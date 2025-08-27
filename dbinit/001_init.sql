-- Create a least-privilege Debezium user with REPLICATION + LOGIN
CREATE ROLE replication_role WITH REPLICATION LOGIN;
CREATE USER debezium_user WITH PASSWORD 'debezium_pass';
GRANT replication_role TO debezium_user;

-- Demo tables (match your include list)
CREATE TABLE IF NOT EXISTS public.customer(
  id BIGSERIAL PRIMARY KEY,
  full_name TEXT,
  email TEXT UNIQUE,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.account(
  id BIGSERIAL PRIMARY KEY,
  customer_id BIGINT REFERENCES public.customer(id),
  balance NUMERIC(18,2) DEFAULT 0,
  status TEXT,
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.kyc_submission(
  id BIGSERIAL PRIMARY KEY,
  customer_id BIGINT REFERENCES public.customer(id),
  document_id TEXT,
  submitted_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.loan_application(
  id BIGSERIAL PRIMARY KEY,
  customer_id BIGINT REFERENCES public.customer(id),
  amount NUMERIC(18,2),
  state TEXT,
  applied_at TIMESTAMPTZ DEFAULT now()
);

-- Minimal read grants for Debezium
GRANT CONNECT ON DATABASE banking_core TO debezium_user;
GRANT USAGE ON SCHEMA public TO debezium_user;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO debezium_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO debezium_user;

GRANT CONNECT ON DATABASE banking_core TO debezium_user;
GRANT USAGE ON SCHEMA public TO debezium_user;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO debezium_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO debezium_user;
CREATE PUBLICATION dbz_publication FOR TABLE public.customer, public.account, public.kyc_submission, public.loan_application;
ALTER PUBLICATION dbz_publication
  ADD TABLE public.customer,
            public.account,
            public.kyc_submission,
            public.loan_application;

select * from pg_publication where pubname = 'dbz_publication';
-- Check if the publication exists
SELECT * FROM pg_catalog.pg_publication;

-- Check which tables are included in it
SELECT * FROM pg_catalog.pg_publication_tables;



truncate customer, account, kyc_submission, loan_application;
-- CUSTOMER
INSERT INTO customer (id, full_name, email, created_at)
VALUES
  (1001, 'Rahim Uddin', 'rahim.uddin@example.com', '2025-08-20 04:15:00+00');

-- ACCOUNTS
INSERT INTO account (id, customer_id, balance, status, created_at)
VALUES
  (2001, 1001, 125000.50, 'ACTIVE', '2025-08-24 03:00:00+00'),
  (2002, 1001,  32050.00, 'ACTIVE', '2025-08-24 03:05:00+00');

-- KYC SUBMISSIONS (documents uploaded)
INSERT INTO kyc_submission (id, customer_id, document_id, created_at)
VALUES
  (3001, 1001, 'NID-2020-1234567890',    '2025-08-22 06:30:00+00'),
  (3002, 1001, 'PASSPORT-BD-AC9876543',  '2025-08-22 06:35:00+00'),
  (3003, 1001, 'POA-UTILITY-DPDC-0725',  '2025-08-22 06:40:00+00');

-- LOAN APPLICATION
INSERT INTO loan_application (id, customer_id, amount, state, created_at)
VALUES
  (4001, 1001, 300000.00, 'UNDER_REVIEW', '2025-08-25 07:10:00+00');




-- CUSTOMER
INSERT INTO customer (id, full_name, email, created_at)
VALUES
  (1002, 'Aisha Rahman', 'aisha.rahman@example.com', '2025-08-21 10:00:00+00');

-- ACCOUNTS
INSERT INTO account (id, customer_id, balance, status, created_at)
VALUES
  (2003, 1002, 50000.00, 'ACTIVE', '2025-08-26 12:00:00+00'),
  (2004, 1002, 150000.00, 'ACTIVE', '2025-08-26 12:05:00+00');

-- KYC SUBMISSIONS (documents uploaded)
INSERT INTO kyc_submission (id, customer_id, document_id, created_at)
VALUES
  (3004, 1002, 'NID-2018-9876543210',      '2025-08-23 09:30:00+00'),
  (3005, 1002, 'PASSPORT-BD-BC1234567',    '2025-08-23 09:35:00+00'),
  (3006, 1002, 'POA-BANK-STMT-0918',       '2025-08-23 09:40:00+00');

-- LOAN APPLICATION
INSERT INTO loan_application (id, customer_id, amount, state, created_at)
VALUES
  (4002, 1002, 450000.00, 'APPROVED', '2025-08-27 08:30:00+00');

