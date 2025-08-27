"""
Normalize raw IDs/names to standard buckets.

- infer_primary_id_type(doc_id) -> {"NID","PASSPORT","DRIVING_LICENSE","OTHER"}
- infer_poa_type(name) -> {"UTILITY_BILL","BANK_STATEMENT","LEASE","OTHER"}
"""
def infer_primary_id_type(doc_id: str) -> str:
    d = (doc_id or "").upper()
    if "PASSPORT" in d: return "PASSPORT"
    if "NID" in d or "NATIONAL ID" in d: return "NID"
    if "DRIVING" in d or "DRIVER" in d: return "DRIVING_LICENSE"
    return "OTHER"

def infer_poa_type(name: str) -> str:
    n = (name or "").upper()
    if any(k in n for k in ["ELECTRIC", "GAS", "WATER", "INTERNET", "UTILITY", "PHONE", "TELECOM"]):
        return "UTILITY_BILL"
    if "BANK" in n or "STATEMENT" in n or "CREDIT CARD" in n:
        return "BANK_STATEMENT"
    if "LEASE" in n or "RENT" in n or "TENANCY" in n:
        return "LEASE"
    return "OTHER"
