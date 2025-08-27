rollback
BEGIN TRANSACTION;

-- db.public.*
INSERT INTO raw.account
SELECT * FROM read_parquet('s3://banking-lake/topics/db.public.account/**/*.parquet', union_by_name=true);

INSERT INTO raw.customer
SELECT * FROM read_parquet('s3://banking-lake/topics/db.public.customer/**/*.parquet', union_by_name=true);

INSERT INTO raw.kyc_submission
SELECT * FROM read_parquet('s3://banking-lake/topics/db.public.kyc_submission/**/*.parquet', union_by_name=true);

INSERT INTO raw.loan_application
SELECT * FROM read_parquet('s3://banking-lake/topics/db.public.loan_application/**/*.parquet', union_by_name=true);

-- files.*
INSERT INTO raw.address_verifications
SELECT * FROM read_parquet('s3://banking-lake/topics/files.address_verifications/**/*.parquet', union_by_name=true);

INSERT INTO raw.beneficial_owners
SELECT * FROM read_parquet('s3://banking-lake/topics/files.beneficial_owners/**/*.parquet', union_by_name=true);

INSERT INTO raw.expected_activity
SELECT * FROM read_parquet('s3://banking-lake/topics/files.expected_activity/**/*.parquet', union_by_name=true);



-- NOTE: you had pointed kyc_uploads to the kyc_review path by mistake — fixed here:
INSERT INTO raw.kyc_uploads
SELECT * FROM read_parquet('s3://banking-lake/topics/files.kyc_uploads/**/*.parquet', union_by_name=true);

INSERT INTO raw.occupation_source_of_funds
SELECT * FROM read_parquet('s3://banking-lake/topics/files.occupation_source_of_funds/**/*.parquet', union_by_name=true);


INSERT INTO raw.tax_self_cert
SELECT * FROM read_parquet('s3://banking-lake/topics/files.tax_self_cert/**/*.parquet', union_by_name=true);

INSERT INTO raw.kyc_review
SELECT * FROM read_parquet('s3://banking-lake/topics/files.kyc_review/**/*.parquet', union_by_name=true);


INSERT INTO raw.screening_results
SELECT * FROM read_parquet('s3://banking-lake/topics/files.screening_results/**/*.parquet', union_by_name=true);


INSERT INTO raw.identity_documents
SELECT * FROM read_parquet('s3://banking-lake/topics/files.identity_documents/**/*.parquet', union_by_name=true);

COMMIT;
