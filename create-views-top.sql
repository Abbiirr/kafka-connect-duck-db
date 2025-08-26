-- create-views-top.sql
CREATE OR REPLACE VIEW customer_stream AS
SELECT  a.*, operation, change_timestamp
FROM (
  SELECT after AS a,
         op AS operation,
         to_timestamp(ts_ms/1000) AS change_timestamp
  FROM parquet_scan('s3://banking-lake/db.public.customer/**/*.parquet')
  WHERE op <> 'd'
) t;

CREATE OR REPLACE VIEW kyc_submissions AS
SELECT  a.*, operation, change_timestamp
FROM (
  SELECT after AS a,
         op AS operation,
         to_timestamp(ts_ms/1000) AS change_timestamp
  FROM parquet_scan('s3://banking-lake/db.public.kyc_submission/**/*.parquet')
  WHERE op <> 'd'
) t;

CREATE OR REPLACE VIEW file_uploads AS
SELECT
  *,
  to_timestamp(file_processed_at/1000) AS processed_timestamp
FROM parquet_scan('s3://banking-lake/files.kyc_uploads/**/*.parquet');
