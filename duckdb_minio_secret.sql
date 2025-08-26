-- duckdb_minio_secret.sql
-- Creates a persistent DuckDB secret for MinIO so you don't need to SET S3 params every session.

INSTALL httpfs;
LOAD httpfs;

-- NOTE: Persistent secrets are auto-loaded on future DuckDB starts.
-- Scope is limited to this bucket so it won't affect other S3 paths.
CREATE PERSISTENT SECRET minio_s3 (
  TYPE s3,
  KEY_ID    'minioadmin',
  SECRET    'minioadmin123',
  REGION    'us-east-1',
  ENDPOINT  'localhost:9000',
  URL_STYLE 'path',           -- MinIO prefers path-style URLs
  USE_SSL   false,
  SCOPE     's3://banking-lake'
);

-- Optional sanity check: will list zero rows until your S3 Sink writes files
-- SELECT * FROM glob('s3://banking-lake/topics/**') LIMIT 20;
