// combined import statement to import tweet data from csv's, 
// written and tested along with @skeuomorph on github
// tested each part of the statement seperately and combined here for importing in one go
// neo4j ran out of RAM on imports, so split the statement back up again (see 'twitter_csv_to_neo_chunks.cql')

// creating uniqueness constraints on node types
// make sure to run these first and confirm they have run seccessfully before running the import statement
CREATE CONSTRAINT ON (c:Comment) ASSERT t.id IS UNIQUE;
CREATE CONSTRAINT ON (u:User) ASSERT u.name IS UNIQUE;
CREATE CONSTRAINT ON (h:Hashtag) ASSERT h.name IS UNIQUE;
// --------------------------------------------

USING PERIODIC COMMIT 100
LOAD CSV WITH HEADERS FROM 'file:///class-statuses-2020-10-21.csv' AS line

MERGE (comment:Comment {id: toInteger(line.id_str)})
SET comment.text = line.text

WITH comment, line, split(line.created_at, ' ') AS dateTime
SET comment.date = date(replace(dateTime[0], '/', '-'))
SET comment.time = time(dateTime[1])
SET comment.hate_score_logreg = toFloat(line.hate_score_logreg)
SET comment.hate_class_svm = CASE line.hate_class_svm WHEN '1' THEN true ELSE false END
SET comment.hate_score_cnn = toFloat(line.hate_score_cnn)
SET comment.hate_score_consensus = CASE line.hate_score_consensus WHEN '1' THEN true ELSE false END

MERGE (user:User {name: line.user_screen_name})

CREATE (user)-[:POSTS]->(comment)

WITH comment, line, split(line.user_mentions_screen_name, '|') AS mentions
FOREACH (m in mentions | merge (mentioned:User {name: m}) merge (comment)-[:MENTIONS]->(mentioned))

WITH comment, line, split(line.hashtags, '|') AS hashtags
FOREACH (h in hashtags | merge (hashtag:Hashtag {name: toUpper(h)}) merge (comment)-[:USES]->(hashtag))
;
// --------------------------------------------



