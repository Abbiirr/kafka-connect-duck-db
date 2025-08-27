# app/checks/kyc.py
"""
Uploads, KYC review, and beneficial owners from raw.* (non-CDC).
Screening may not exist in raw; we handle that gracefully.
"""
import duckdb
from app.db import qv
from app.schemas import CheckResult, FieldStatus

def check_screening(customer_id: int) -> CheckResult:
    """
    Try raw.screening_results (if/when it exists). Otherwise return [].
    """
    try:
        sql = """
        SELECT COALESCE(status, 'SCREENED') AS key
        FROM raw.screening_results
        WHERE customer_id = ?
        ORDER BY created_at DESC;
        """
        vals = qv(sql, (customer_id,))
    except (duckdb.CatalogException, duckdb.BinderException):
        vals = []
    return CheckResult(status=FieldStatus(field_name="screening_results", field_value=vals, missing=(len(vals) == 0)))

def check_beneficial_owners(customer_id: int, is_legal_entity: bool) -> CheckResult:
    # Return BO names, sorted by declared ownership%
    sql = """
    SELECT bo_full_name
    FROM raw.beneficial_owners
    WHERE customer_id = ?
    ORDER BY TRY_CAST(ownership_percent AS DECIMAL(9,4)) DESC NULLS LAST;
    """
    vals = qv(sql, (customer_id,))
    missing = (len(vals) == 0) if is_legal_entity else False
    return CheckResult(
        status=FieldStatus(field_name="beneficial_owners", field_value=vals, missing=missing),
        details={"required": str(is_legal_entity)}
    )

def check_uploads(customer_id: int) -> CheckResult:
    # Return uploaded filenames
    sql = """
    SELECT file_name
    FROM raw.kyc_uploads
    WHERE customer_id = ?
    ORDER BY created_at DESC;
    """
    vals = qv(sql, (customer_id,))
    return CheckResult(status=FieldStatus(field_name="kyc_uploads", field_value=vals, missing=(len(vals) == 0)))

def check_kyc_review(customer_id: int) -> CheckResult:
    # Return most recent decision(s)
    sql = """
    SELECT review_outcome
    FROM raw.kyc_review
    WHERE customer_id = ?
    ORDER BY COALESCE(TRY_CAST(last_review_on AS TIMESTAMP), TRY_CAST(created_at AS TIMESTAMP)) DESC NULLS LAST;
    """
    vals = qv(sql, (customer_id,))
    return CheckResult(status=FieldStatus(field_name="kyc_review", field_value=vals, missing=(len(vals) == 0)))
