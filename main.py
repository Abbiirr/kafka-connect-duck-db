from typing import List, Callable
import os
import duckdb
from fastapi import FastAPI, Query, Path
from pydantic import BaseModel

# ----- Config -----
DB_PATH = os.getenv("DUCKDB_PATH", "identifier.db")  # point to your .duckdb file

# ----- Models -----
class FieldStatus(BaseModel):
    field_name: str
    field_value: List[str]  # empty list => "missing"

# ----- DuckDB helpers -----
def _run_list(sql: str, params: tuple) -> List[str]:
    # Open a fresh connection per request to avoid cross-thread contention.
    # (DuckDB Python connections are simple to create, and persisting the file is handled by duckdb.connect.) :contentReference[oaicite:1]{index=1}
    with duckdb.connect(DB_PATH, read_only=True) as con:
        # If your DB uses S3/MinIO-backed views, httpfs might be required per-connection.
        try:
            con.execute("LOAD httpfs;")
        except Exception:
            pass
        rows = con.execute(sql, params).fetchall()
        return [str(r[0]) for r in rows]

def _try_queries(candidates: List[str], params: tuple) -> List[str]:
    # Try a list of SQLs (to support either base tables or views). Skip if a relation doesn't exist.
    for sql in candidates:
        try:
            return _run_list(sql, params)
        except duckdb.CatalogException:
            # relation doesn't exist; try next candidate
            continue
        except duckdb.BinderException:
            continue
    return []  # nothing found

# ----- Field resolvers -----
def get_account_numbers(customer_id: int, active_only: bool) -> List[str]:
    base = "SELECT id FROM {src} WHERE customer_id = ?"
    if active_only:
        base += " AND status = 'ACTIVE'"
    base += " ORDER BY id"
    candidates = [base.format(src="account"), base.format(src="account_stream")]
    return _try_queries(candidates, (customer_id,))

def get_kyc_documents(customer_id: int) -> List[str]:
    candidates = [
        "SELECT document_id FROM kyc_submission WHERE customer_id = ? ORDER BY created_at",
        "SELECT document_id FROM kyc_submissions WHERE customer_id = ? ORDER BY created_at",
    ]
    return _try_queries(candidates, (customer_id,))

def get_loan_application_ids(customer_id: int) -> List[str]:
    candidates = [
        "SELECT id FROM loan_application WHERE customer_id = ? ORDER BY created_at",
        "SELECT id FROM loan_application_stream WHERE customer_id = ? ORDER BY created_at",
    ]
    return _try_queries(candidates, (customer_id,))

# ----- API -----
app = FastAPI(title="Customer Coverage API", version="1.0.0")

@app.get("/health")
def health():
    return {"status": "ok"}

@app.get(
    "/customers/{customer_id}/coverage",
    response_model=List[FieldStatus],
    summary="List which items a customer has filed (empty lists mean missing)."
)
def coverage(
    customer_id: int = Path(..., description="Customer ID to inspect"),
    active_accounts_only: bool = Query(True, description="Only count ACTIVE accounts")
):
    # Build responses in the shape you requested
    result: List[FieldStatus] = [
        FieldStatus(field_name="account_number",
                    field_value=get_account_numbers(customer_id, active_accounts_only)),
        FieldStatus(field_name="kyc_documents",
                    field_value=get_kyc_documents(customer_id)),
        FieldStatus(field_name="loan_application_ids",
                    field_value=get_loan_application_ids(customer_id)),
    ]
    return result
