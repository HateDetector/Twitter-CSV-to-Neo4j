// combined import statement to import tweet data from csv's, 
// written and tested along with @skeuomorph on github
// tested each part of the statement seperately and combined here for importing in one go
// neo4j ran out of RAM on imports, so split the statement back up again (see 'twitter_csv_to_neo_chunks.cql')

// creating uniqueness constraints on node types
// make sure to run these first and confirm they have run seccessfully before running the import statement
CREATE CONSTRAINT ON (comment:Comment) ASSERT comment.id IS UNIQUE;
CREATE CONSTRAINT ON (user:User) ASSERT user.id IS UNIQUE;
CREATE CONSTRAINT ON (hashtag:Hashtag) ASSERT hashtag.id IS UNIQUE;
CREATE CONSTRAINT ON (url:URL) ASSERT url.id IS UNIQUE;
// --------------------------------------------

USING PERIODIC COMMIT
LOAD CSV WITH HEADERS FROM 'file:///class-statuses-2020-11-03-part2.csv' AS line

MERGE (comment:Comment {id: toInteger(line.id_str)})
SET comment.text = line.text
SET comment.hate_score_logreg = toFloat(line.hate_score_logreg)
SET comment.hate_class_svm = CASE line.hate_class_svm WHEN '1' THEN true ELSE false END
SET comment.hate_score_cnn = toFloat(line.hate_score_cnn)
SET comment.hate_score_consensus = CASE line.hate_score_consensus WHEN '1' THEN true ELSE false END

MERGE (user:User {id: line.user_id_str})
SET user.handle = line.user_screen_name
SET user.location = line.user_location

CREATE (user)-[:POSTS]->(comment)

WITH comment, line, split(line.hashtags, '|') AS hashtags
FOREACH (h in hashtags | merge (hashtag:Hashtag {id: toLower(h), type: 'hashtag'}) merge (comment)-[:USES]->(hashtag) SET hashtag:Link)
WITH comment, line, split(line.urls, '|') AS urls
FOREACH (u in urls | merge (url:URL {id: toLower(u), type: 'url'}) merge (comment)-[:USES]->(url) SET url:Link)
WITH comment, line, split(line.user_mentions_id_str, '|') AS mentions
FOREACH (m in mentions | merge (mentioned:User {id: m}) merge (comment)-[:MENTIONS]->(mentioned))
WITH comment, line, split(line.created_at, ' ') AS dateTime
SET comment.date = date(replace(dateTime[0], '/', '-'))
SET comment.time = time(dateTime[1])
WITH comment, line, CASE WHEN line.hate_score_consensus = '1' THEN [1] ELSE [] END AS hate
FOREACH (x IN hate | SET comment:Hate)
WITH comment, line, CASE WHEN line.in_reply_to_status_id_str <> 'None' THEN [toInteger(line.in_reply_to_status_id_str)] ELSE [] END AS replyid
FOREACH (x IN replyid | merge (origin:Comment {id: x}) merge (comment)-[:`REPLIED TO`]->(origin))

MERGE (user:User {id: line.user_id_str})
WITH user, line, split(line.user_created_at, ' ') AS dateTime
SET user.created = date(replace(dateTime[0], '/', '-'))
;
