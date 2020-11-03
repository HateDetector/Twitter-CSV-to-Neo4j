//The following code can be shortened into one single statement(see @jrobi001 on GitHub), but for limited memory we have split the program into smaller chunks

//Save each comment, user, and hashtag as unique nodes
CREATE CONSTRAINT ON (comment:Comment) ASSERT comment.id IS UNIQUE;
CREATE CONSTRAINT ON (user:User) ASSERT user.name IS UNIQUE;
CREATE CONSTRAINT ON (h:Hashtag) ASSERT h.name IS UNIQUE;

//Initialise comment + user nodes with "posts" relationship, set text property to comment nodes
:auto USING PERIODIC COMMIT 100
LOAD CSV WITH HEADERS FROM 'file:///class-statuses-2020-10-21.csv' AS line

MERGE (comment:Comment {id: toInteger(line.id_str)})
SET comment.text = line.text

MERGE (user:User {name: line.user_screen_name})

MERGE (user)-[:POSTS]->(comment)
;

//Create user node for each account listed in "user_mentions_screen_name" column, add "MENTIONS" relationship

:auto USING PERIODIC COMMIT 100
LOAD CSV WITH HEADERS FROM 'file:///class-statuses-2020-10-21.csv' AS line

MATCH (comment:Comment {id: toInteger(line.id_str)})
WITH comment, line, split(line.user_mentions_screen_name, '|') AS mentions
FOREACH (m in mentions | merge (mentioned:User {name: m}) merge (comment)-[:MENTIONS]->(mentioned))
;

//Add relationship "TAGGED" from comment node to hashtag node using the "hashtags" column in CSV

:auto USING PERIODIC COMMIT 100
LOAD CSV WITH HEADERS FROM 'file:///class-statuses-2020-10-21.csv' AS line

MATCH (comment:Comment {id: toInteger(line.id_str)})

WITH comment, line, split(line.hashtags, '|') AS hashtags
FOREACH (h in hashtags | merge (hashtag:Hashtag {name: toUpper(h)}) merge (comment)-[:TAGGED]->(hashtag))
;


//SET date and time as properties for each comment node
:auto USING PERIODIC COMMIT 100
LOAD CSV WITH HEADERS FROM 'file:///class-statuses-2020-10-21.csv' AS line

MATCH (comment:Comment {id: toInteger(line.id_str)})

WITH comment, line, split(line.created_at, ' ') AS dateTime
SET comment.date = date(replace(dateTime[0], '/', '-'))
SET comment.time = time(dateTime[1])
;


//Import hate detection scores (CNN = Convolutional Neural Network by @JAWorsfold on GitHub)
:auto USING PERIODIC COMMIT 100
LOAD CSV WITH HEADERS FROM 'file:///class-statuses-2020-10-21.csv' AS line

MATCH (comment:Comment {id: toInteger(line.id_str)})

SET comment.hate_score_logreg = toFloat(line.hate_score_logreg)
SET comment.hate_class_svm = CASE line.hate_class_svm WHEN '1' THEN true ELSE false END
SET comment.hate_score_cnn = toFloat(line.hate_score_cnn)
SET comment.hate_score_consensus = CASE line.hate_score_consensus WHEN '1' THEN true ELSE false END
;
