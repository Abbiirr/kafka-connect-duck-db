# app/checks/address.py
"""
Proof of Address (PoA) from raw.address_verifications.
- Use proof_type as the label.
- Enforce recency via proof_issue_date <= 90 days (tunable).
"""
from datetime import date
from app.db import get_conn
from app.schemas import CheckResult, FieldStatus
from app.inference.doc_types import infer_poa_type

POA_MAX_DAYS = 90

def check_address(customer_id: int) -> CheckResult:
    # Cast issue date to DATE so Python gets datetime.date objects back.
    sql = """
    SELECT
      proof_type,
      TRY_CAST(proof_issue_date AS DATE) AS issue_date
    FROM raw.address_verifications
    WHERE customer_id = ?;
    """
    with get_conn() as con:
        rows = con.execute(sql, (customer_id,)).fetchall()

    today = date.today()
    types, fresh = [], False
    for proof_type, issue_date in rows:
        types.append(infer_poa_type(proof_type))
        try:
            if issue_date and (today - issue_date).days <= POA_MAX_DAYS:
                fresh = True
        except Exception:
            pass

    have = sorted(set(types))
    missing = (len(have) == 0) or (not fresh)
    return CheckResult(
        status=FieldStatus(field_name="address_verifications", field_value=have, missing=missing),
        details={"has_fresh_poa": str(fresh)}
    )
