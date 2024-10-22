-- Supabase Guide: https://supabase.com/docs/guides/ai/langchain?database-method=sql

-- Enable the pgvector extension to work with embedding vectors
create extension vector;

-- Create a table to store your documents
create table documents (
  id bigserial primary key,
  content text, -- corresponds to Document.pageContent
  metadata jsonb, -- corresponds to Document.metadata
  embedding vector(1536) -- 1536 works for OpenAI embeddings, change if needed
);

-- Create a function to search for documents
create function match_documents (
  query_embedding vector(1536),
  match_count int default null,
  filter jsonb DEFAULT '{}'
) returns table (
  id bigint,
  content text,
  metadata jsonb,
  similarity float
)
language plpgsql
as $$
#variable_conflict use_column
begin
  return query
  select
    id,
    content,
    metadata,
    1 - (documents.embedding <=> query_embedding) as similarity
  from documents
  where metadata @> filter
  order by documents.embedding <=> query_embedding
  limit match_count;
end;
$$;


-- -- Create the "vector" extension in the "public" schema
-- CREATE EXTENSION IF NOT EXISTS vector 
-- WITH
--   SCHEMA public;

-- -- Create the "vectors" table in the "public" schema
-- CREATE TABLE IF NOT EXISTS public.vectors (
--   id SERIAL PRIMARY KEY,              -- Unique identifier for each row
--   embedding vector(1536),             -- Vector data type for storing embeddings
--   content TEXT NOT NULL,              -- Content that the vector is associated with
--   metadata JSONB                      -- Metadata stored in JSONB format for flexibility
-- );

-- -- Create an index for the "embedding" column to improve search performance
-- CREATE INDEX IF NOT EXISTS vectors_index ON public.vectors USING ivfflat (embedding);