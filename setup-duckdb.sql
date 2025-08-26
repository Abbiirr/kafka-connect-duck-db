-- setup-duckdb-base.sql
INSTALL httpfs;
LOAD httpfs;

-- MinIO (host CLI: localhost; inside a container: minio)
SET s3_region='us-east-1';
SET s3_endpoint='localhost:9000';
SET s3_access_key_id='minioadmin';
SET s3_secret_access_key='minioadmin123';
SET s3_use_ssl=false;
SET s3_url_style='path';  -- path-style works best with MinIO

