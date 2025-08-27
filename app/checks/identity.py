# app/checks/identity.py
"""
Identity documents from CDC stream raw.kyc_submission.
"""
from app.db import qv
from app.schemas import CheckResult, FieldStatus
from app.inference.doc_types import infer_primary_id_type

REQUIRED_PRIMARY = {"NID","PASSPORT","DRIVING_LICENSE"}

def check_identity(customer_id: int) -> CheckResult:
    # Take latest per document row; ignore deletes; gather document_id strings.
    sql = """
    WITH e AS (
      SELECT
        (after).id           AS id,
        (after).customer_id  AS customer_id,
        (after).document_id  AS document_id,
        ts_ms,
        op
      FROM raw.kyc_submission
      WHERE (after).customer_id = ?
    ),
    r AS (
      SELECT *, row_number() OVER (PARTITION BY id ORDER BY ts_ms DESC) rn
      FROM e
    )
    SELECT document_id
    FROM r
    WHERE rn = 1 AND op <> 'd'
    ORDER BY ts_ms;
    """
    docs = qv(sql, (customer_id,))
    types = sorted({infer_primary_id_type(d) for d in docs})
    missing = len(REQUIRED_PRIMARY.intersection(types)) == 0
    return CheckResult(
        status=FieldStatus(field_name="identity_documents", field_value=types, missing=missing)
    )
