WITH all_files AS (
  SELECT
    filename,
    size,
    last_modified,
    regexp_extract(filename, 'topics/([^/]+)/', 1) AS topic_prefix
  FROM read_blob('s3://banking-lake/topics/**/*.parquet')
),
latest_per_topic AS (
  SELECT
    topic_prefix,
    filename,
    size,
    last_modified,
    row_number() OVER (PARTITION BY topic_prefix ORDER BY last_modified DESC) AS rn
  FROM all_files
)
SELECT topic_prefix, filename, size, last_modified
FROM latest_per_topic
WHERE rn = 1
ORDER BY topic_prefix;


drop schema if exists raw cascade;
CREATE SCHEMA IF NOT EXISTS raw;



-- Then create an empty table using inferred schema:
CREATE TABLE raw.customer AS
SELECT *
FROM read_parquet('s3://banking-lake/topics/db.public.customer/2025/08/27/10/db.public.customer+1+0000000003.snappy.parquet')
LIMIT 0;


-- Then create an empty table using inferred schema:
CREATE TABLE raw.kyc_submission AS
SELECT *
FROM read_parquet('s3://banking-lake/topics/db.public.kyc_submission/2025/08/27/10/db.public.kyc_submission+1+0000000005.snappy.parquet')
LIMIT 0;


-- Then create an empty table using inferred schema:
CREATE TABLE raw.address_verifications AS
SELECT *
FROM read_parquet('s3://banking-lake/topics/files.address_verifications/2025/08/27/10/files.address_verifications+1+0000000002.snappy.parquet')
LIMIT 0;



-- Then create an empty table using inferred schema:
CREATE TABLE raw.beneficial_owners AS
SELECT *
FROM read_parquet('s3://banking-lake/topics/files.beneficial_owners/2025/08/27/10/files.beneficial_owners+1+0000000002.snappy.parquet')
LIMIT 0;


-- Then create an empty table using inferred schema:
CREATE TABLE raw.expected_activity AS
SELECT *
FROM read_parquet('s3://banking-lake/topics/files.expected_activity/2025/08/27/10/files.expected_activity+1+0000000002.snappy.parquet')
LIMIT 0;







-- Then create an empty table using inferred schema:
CREATE TABLE raw.kyc_uploads AS
SELECT *
FROM read_parquet('s3://banking-lake/topics/files.kyc_uploads/2025/08/27/10/files.kyc_uploads+1+0000000006.snappy.parquet')
LIMIT 0;



-- Then create an empty table using inferred schema:
CREATE TABLE raw.occupation_source_of_funds AS
SELECT *
FROM read_parquet('s3://banking-lake/topics/files.occupation_source_of_funds/2025/08/27/10/files.occupation_source_of_funds+1+0000000002.snappy.parquet')
LIMIT 0;

-- Then create an empty table using inferred schema:
CREATE TABLE raw.tax_self_cert AS
SELECT *
FROM read_parquet('s3://banking-lake/topics/files.tax_self_cert/2025/08/27/10/files.tax_self_cert+1+0000000002.snappy.parquet')
LIMIT 0;

CREATE TABLE raw.kyc_review AS
SELECT *
FROM read_parquet('s3://banking-lake/topics/files.kyc_review/2025/08/27/10/files.kyc_review+1+0000000002.snappy.parquet')
LIMIT 0;



-- Then create an empty table using inferred schema:
CREATE TABLE raw.loan_application AS
SELECT *
FROM read_parquet('s3://banking-lake/topics/db.public.loan_application/2025/08/27/10/db.public.loan_application+1+0000000001.snappy.parquet')
LIMIT 0;

-- Then create an empty table using inferred schema:
CREATE TABLE raw.account AS
SELECT *
FROM read_parquet('s3://banking-lake/topics/db.public.account/2025/08/27/10/db.public.account+1+0000000002.snappy.parquet')
LIMIT 0;





-- Then create an empty table using inferred schema:
CREATE TABLE raw.screening_results AS
SELECT *
FROM read_parquet('s3://banking-lake/topics/files.screening_results/2025/08/27/06/files.screening_results+2+0000000003.snappy.parquet')
LIMIT 0;

-- Then create an empty table using inferred schema:
CREATE TABLE raw.identity_documents AS
SELECT *
FROM read_parquet('s3://banking-lake/topics/files.identity_documents/2025/08/27/06/files.identity_documents+2+0000000002.snappy.parquet')
LIMIT 0;
