from pydantic import BaseModel
from typing import List

class BlockReport(BaseModel):
    block_id: int
    status: str # "completed", "partial", "missed"

class DailyReportRequest(BaseModel):
    user_id: int
    date: str
    blocks: List[BlockReport]
    focus_rating: int
