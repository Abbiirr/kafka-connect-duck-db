from pydantic import BaseModel
from typing import List, Dict, Optional

class FieldStatus(BaseModel):
    field_name: str
    field_value: List[str]
    missing: bool

class MissingSummary(BaseModel):
    missing_fields: List[str]
    required_breakdown: Dict[str, List[str]] = {}

class CheckResult(BaseModel):
    status: FieldStatus
    details: Dict[str, Optional[str]] = {}
