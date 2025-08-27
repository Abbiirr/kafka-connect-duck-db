# app/main.py
from typing import List
from fastapi import FastAPI, Query, Path, HTTPException
from fastapi.middleware.cors import CORSMiddleware

from app.schemas import FieldStatus                         # :contentReference[oaicite:4]{index=4}
from app.checks.accounts import customer_exists, check_accounts, check_loans
from app.checks.identity import check_identity
from app.checks.address import check_address                # now uses proof_type/proof_issue_date
from app.checks.certificates import (
    check_tax_self_cert, check_expected_activity, check_source_of_funds
)
from app.checks.kyc import (
    check_screening, check_beneficial_owners, check_uploads, check_kyc_review
)

app = FastAPI(title="Customer Coverage API", version="1.1.0")

# CORS: open to all origins/methods/headers (no credentials)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

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
    active_accounts_only: bool = Query(True, description="Only count ACTIVE accounts"),
    is_legal_entity: bool = Query(False, description="If true, beneficial owners are expected"),
):
    # 404 guard
    if not customer_exists(customer_id):
        raise HTTPException(status_code=404, detail="Customer not found")

    results: List[FieldStatus] = [
        # Core
        check_accounts(customer_id, active_only=active_accounts_only).status,
        check_loans(customer_id).status,

        # Identity & Address
        check_identity(customer_id).status,
        check_address(customer_id).status,

        # Certificates
        check_tax_self_cert(customer_id).status,
        check_source_of_funds(customer_id).status,
        check_expected_activity(customer_id).status,

        # KYC pack
        check_uploads(customer_id).status,
        check_kyc_review(customer_id).status,
        check_screening(customer_id).status,  # returns [] if table not present
        check_beneficial_owners(customer_id, is_legal_entity=is_legal_entity).status,
    ]
    return results
