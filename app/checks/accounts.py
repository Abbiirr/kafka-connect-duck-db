# app/checks/accounts.py
"""
Customer existence, accounts, loans — refactored to use raw.* CDC tables.
"""
from typing import List
import duckdb
from app.db import get_conn, qv
from app.schemas import CheckResult, FieldStatus

def customer_exists(customer_id: int) -> bool:
    """
    Existence = latest event for this id is NOT a delete.
    We coalesce id from AFTER/BEFORE so deletes (which have AFTER=NULL) still match.
    """
    sql = """
    WITH e AS (
      SELECT
        COALESCE((after).id, (before).id) AS id,
        op,
        ts_ms
      FROM raw.customer
      WHERE COALESCE((after).id, (before).id) = ?
    ),
    ranked AS (
      SELECT op, row_number() OVER (ORDER BY ts_ms DESC) rn
      FROM e
    )
    SELECT 1
    FROM ranked
    WHERE rn = 1 AND op <> 'd';
    """
    with get_conn() as con:
        return con.execute(sql, (customer_id,)).fetchone() is not None

def check_accounts(customer_id: int, active_only: bool = True) -> CheckResult:
    """
    Latest row per account id for this customer; ignore deletes; optional ACTIVE filter.
    """
    status_clause = "AND status = 'ACTIVE'" if active_only else ""
    sql = f"""
    WITH e AS (
      SELECT
        (after).id            AS id,
        (after).customer_id   AS customer_id,
        (after).status        AS status,
        ts_ms,
        op
      FROM raw.account
      WHERE (after).customer_id = ?
    ),
    r AS (
      SELECT *, row_number() OVER (PARTITION BY id ORDER BY ts_ms DESC) rn
      FROM e
    )
    SELECT id
    FROM r
    WHERE rn = 1 AND op <> 'd' {status_clause}
    ORDER BY id;
    """
    vals = qv(sql, (customer_id,))
    return CheckResult(
        status=FieldStatus(field_name="account_number", field_value=vals, missing=(len(vals) == 0))
    )

def check_loans(customer_id: int) -> CheckResult:
    """
    Latest row per loan id for this customer; ignore deletes.
    """
    sql = """
    WITH e AS (
      SELECT
        (after).id            AS id,
        (after).customer_id   AS customer_id,
        ts_ms,
        op
      FROM raw.loan_application
      WHERE (after).customer_id = ?
    ),
    r AS (
      SELECT *, row_number() OVER (PARTITION BY id ORDER BY ts_ms DESC) rn
      FROM e
    )
    SELECT id
    FROM r
    WHERE rn = 1 AND op <> 'd'
    ORDER BY id;
    """
    vals = qv(sql, (customer_id,))
    return CheckResult(
        status=FieldStatus(field_name="loan_application_ids", field_value=vals, missing=(len(vals) == 0))
    )
