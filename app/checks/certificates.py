# app/checks/certificates.py
"""
Tax self-cert, expected activity, and source-of-funds from raw.* (non-CDC).
We return meaningful single-column lists to signal presence.
"""
from app.db import qv
from app.schemas import CheckResult, FieldStatus

def check_tax_self_cert(customer_id: int) -> CheckResult:
    # Return the declared W-Form/CRS FATCA type(s) as identifiers
    sql = """
    SELECT COALESCE(w_form_type, fatca_status, 'SELF_CERT') AS key
    FROM raw.tax_self_cert
    WHERE customer_id = ?;
    """
    vals = qv(sql, (customer_id,))
    return CheckResult(status=FieldStatus(field_name="tax_self_cert", field_value=vals, missing=(len(vals) == 0)))

def check_expected_activity(customer_id: int) -> CheckResult:
    # Return expected_products (fallback to currency)
    sql = """
    SELECT COALESCE(expected_products, currency, 'ACTIVITY') AS key
    FROM raw.expected_activity
    WHERE customer_id = ?;
    """
    vals = qv(sql, (customer_id,))
    return CheckResult(status=FieldStatus(field_name="expected_activity", field_value=vals, missing=(len(vals) == 0)))

def check_source_of_funds(customer_id: int) -> CheckResult:
    # Return source_of_funds (fallback to source_of_wealth)
    sql = """
    SELECT COALESCE(source_of_funds, source_of_wealth, 'SOF') AS key
    FROM raw.occupation_source_of_funds
    WHERE customer_id = ?;
    """
    vals = qv(sql, (customer_id,))
    return CheckResult(status=FieldStatus(field_name="occupation_source_of_funds", field_value=vals, missing=(len(vals) == 0)))
