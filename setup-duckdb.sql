INSTALL httpfs;
LOAD httpfs;

-- S3/MinIO settings
SET s3_region='us-east-1';
SET s3_endpoint='localhost:9000'; -- or 'minio:9000' if inside Docker
SET s3_access_key_id='minioadmin';
SET s3_secret_access_key='minioadmin123';
SET s3_use_ssl=false;

-- Debezium views (JSON with schema/payload)
CREATE OR REPLACE VIEW customer_stream AS
SELECT
  payload.after.* EXCLUDE (op, ts_ms),
  payload.op AS operation,
  to_timestamp(payload.ts_ms/1000) AS change_timestamp
FROM parquet_scan('s3://banking-lake/db.public.customer/**/*.parquet')
WHERE payload.op != 'd';

CREATE OR REPLACE VIEW kyc_submissions AS
SELECT
  payload.after.*,
  payload.op AS operation,
  to_timestamp(payload.ts_ms/1000) AS change_timestamp
FROM parquet_scan('s3://banking-lake/db.public.kyc_submission/**/*.parquet')
WHERE payload.op != 'd';

CREATE OR REPLACE VIEW file_uploads AS
SELECT
  *,
  to_timestamp(file_processed_at/1000) AS processed_timestamp
FROM parquet_scan('s3://banking-lake/files.kyc_uploads/**/*.parquet');
