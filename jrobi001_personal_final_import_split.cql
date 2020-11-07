// Personal final import script for my local version of the database to test statements
// Written alongside @skeuomorph on github and based on additions and changes by @JAWorsfold on github

// Changes:
// - returned User, Hashtag and Hrl to using .name property instead of .id, so that nodes will show the property overlayed when displaying nodes in neo4j (neo4j will assign an id)
// - removed Link node labels on hashtag and url (messed with visualising nodes, both sometimes appeared same color on some searches)
// - renamed Comment nodes to Tweet (personal preference)
// - renamed Tweet->URL relationship as SHARES (was USES, same as hashtag, wanded to remove ambiguity)
// - split up import statement again, only have 2GB ram spare on this machine, thee combined statement was too much for this PC 😅

// The split up statements could be combined a little more, some statements are not too intensive


// creating uniqueness constraints on node types
// make sure to run these first and confirm they have run seccessfully before running the import statements below
CREATE CONSTRAINT ON (tweet:Tweet) ASSERT tweet.id IS UNIQUE;
CREATE CONSTRAINT ON (user:User) ASSERT user.name IS UNIQUE;
CREATE CONSTRAINT ON (hashtag:Hashtag) ASSERT hashtag.name IS UNIQUE;
CREATE CONSTRAINT ON (url:URL) ASSERT url.name IS UNIQUE;
//-----------
// Run this statement first after constraints, the order of the others should not matter
USING PERIODIC COMMIT 100
LOAD CSV WITH HEADERS FROM 'file:///class-statuses-2020-10-17.csv' AS line

MERGE (tweet:Tweet {id: toInteger(line.id_str)})
SET tweet.text = line.text
SET tweet.hate_score_logreg = toFloat(line.hate_score_logreg)
SET tweet.hate_class_svm = CASE line.hate_class_svm WHEN '1' THEN true ELSE false END
SET tweet.hate_score_cnn = toFloat(line.hate_score_cnn)
SET tweet.hate_score_consensus = CASE line.hate_score_consensus WHEN '1' THEN true ELSE false END

WITH tweet, line, split(line.created_at, ' ') AS dateTime
SET tweet.date = date(dateTime[0])
SET tweet.time = time(dateTime[1])

MERGE (user:User {name: line.user_id_str})
SET user.handle = line.user_screen_name
SET user.location = line.user_location

WITH user, line, split(line.user_created_at, ' ') AS dateTime
SET user.created = date(replace(dateTime[0], '/', '-'))
;

//------
// split up POSTS relationship, for some reason was not being implemented properly when at the bottom of the above statement
USING PERIODIC COMMIT 100
LOAD CSV WITH HEADERS FROM 'file:///class-statuses-2020-10-17.csv' AS line

MATCH (tweet:Tweet {id: toInteger(line.id_str)})
MATCH (user:User {name: line.user_id_str})
CREATE (user)-[:POSTS]->(tweet)
;
//-----------
// making hashtags and mentions nodes & relationships
USING PERIODIC COMMIT 100
LOAD CSV WITH HEADERS FROM 'file:///class-statuses-2020-10-17.csv' AS line

MATCH (tweet:Tweet {id: toInteger(line.id_str)})

WITH tweet, line, split(line.hashtags, '|') AS hashtags
FOREACH (h in hashtags | merge (hashtag:Hashtag {name: toLower(h), type: 'hashtag'}) merge (tweet)-[:USES]->(hashtag))

WITH tweet, line, split(line.user_mentions_id_str, '|') AS mentions
FOREACH (m in mentions | merge (mentioned:User {name: m}) merge (tweet)-[:MENTIONS]->(mentioned))
;

//------------------
// making URL nodes and relationships
USING PERIODIC COMMIT 100
LOAD CSV WITH HEADERS FROM 'file:///class-statuses-2020-10-17.csv' AS line

MATCH (tweet:Tweet {id: toInteger(line.id_str)})

WITH tweet, line, split(line.urls, '|') AS urls
FOREACH (u in urls | merge (url:URL {name: toLower(u), type: 'url'}) merge (tweet)-[:SHARES]->(url))
;

//----------
// adding the additional label 'Hate' to Tweet nodes where the consensus was that they contain hate speech
USING PERIODIC COMMIT 100
LOAD CSV WITH HEADERS FROM 'file:///class-statuses-2020-10-17.csv' AS line

MATCH (tweet:Tweet {id: toInteger(line.id_str)})

WITH tweet, line, CASE WHEN line.hate_score_consensus = '1' THEN [1] ELSE [] END AS hate
FOREACH (x IN hate | SET tweet:Hate)
;

//----------
// tweet replied to relationship
USING PERIODIC COMMIT 100
LOAD CSV WITH HEADERS FROM 'file:///class-statuses-2020-10-17.csv' AS line

MATCH (tweet:Tweet {id: toInteger(line.id_str)})

MATCH (user:User {name: line.user_id_str})

WITH tweet, line, CASE WHEN line.in_reply_to_user_id_str <> 'None' THEN [toInteger(line.in_reply_to_user_id_str)] ELSE [] END AS replyid
FOREACH (x IN replyid | merge (origin:Tweet {id: x}) merge (tweet)-[:`REPLIED TO`]->(origin))
;
