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
