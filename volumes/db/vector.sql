\set pguser `echo "$POSTGRES_USER"`

-- GRANT ALL PRIVILEGES ON SCHEMA vector TO :pguser;

-- Create the "vector" extension in the "vector" schema
CREATE EXTENSION IF NOT EXISTS vector SCHEMA vector;

-- Create the "vector" table in the "vector" schema
CREATE TABLE vector.vectors (
    id SERIAL PRIMARY KEY,              -- Unique identifier for each row
    embedding VECTOR(1536),             -- Vector data type for storing embeddings
    content TEXT NOT NULL,              -- Content that the vector is associated with
    metadata JSONB                      -- Metadata stored in JSONB format for flexibility
);

-- Create an index for the "vector" column to improve search performance
CREATE INDEX vector_index ON vector.vectors USING ivfflat (embedding);