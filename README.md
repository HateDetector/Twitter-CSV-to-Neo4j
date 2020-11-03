# Twitter-CSV-to-Neo4j
Cypher Query Language files used to convert Twitter API info stored as CSVs, into nodes and relationships in Neo4j.

The "chunks" file contains the same code as the "combined", but in smaller chunks to save RAM. 

We recommend editing the neo4j.config file regardless, to have larger values for 'dbms.memory.heap.initial_size' and 'dbms.memory.heap.max_size' (at least 2GB preferably)
