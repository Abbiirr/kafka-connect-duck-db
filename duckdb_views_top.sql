-- duckdb_views_top.sql
-- Views for Debezium envelopes that are TOP-LEVEL (columns: before, after, op, ts_ms, ...).
-- Requires files under: s3://banking-lake/topics/<topic>/...

LOAD httpfs;

-- CUSTOMER STREAM (Debezium 'after' struct expanded to columns)
CREATE OR REPLACE VIEW customer_stream AS
SELECT a.*, operation, change_ts
FROM (
  SELECT after AS a,
         op AS operation,
         to_timestamp(ts_ms/1000) AS change_ts
  FROM parquet_scan('s3://banking-lake/topics/db.public.customer/**/*.parquet')
  WHERE op <> 'd'
) t;

-- KYC SUBMISSIONS (uncomment when the topic exists in S3)
-- CREATE OR REPLACE VIEW kyc_submissions AS
-- SELECT a.*, operation, change_ts
-- FROM (
--   SELECT after AS a,
--          op AS operation,
--          to_timestamp(ts_ms/1000) AS change_ts
--   FROM parquet_scan('s3://banking-lake/topics/db.public.kyc_submission/**/*.parquet')
--   WHERE op <> 'd'
-- ) t;

-- FILE UPLOADS from SpoolDir (flat records; uncomment when present)
-- CREATE OR REPLACE VIEW file_uploads AS
-- SELECT *, to_timestamp(file_processed_at/1000) AS processed_ts
-- FROM parquet_scan('s3://banking-lake/topics/files.kyc_uploads/**/*.parquet');
