MATCH (n) DETACH DELETE n;
CALL db.constraints;
call db.schema.visualization();

MATCH (u:URL)-[us:USES]-(h:Hate)
RETURN u, COLLECT(h) as tweets
ORDER BY SIZE(tweets) DESC LIMIT 10

MATCH (ha:Hashtag)-[hs:USES]-(h:Hate)
RETURN ha, COLLECT(h) as tweets
LIMIT tweets 100
ORDER BY SIZE(tweets) DESC LIMIT 10

MATCH (y:User)-[ys:POSTS]-(h:Hate)
RETURN y, COLLECT(h) as tweets
ORDER BY SIZE(tweets) DESC LIMIT 10
