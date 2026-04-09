from datetime import datetime
from typing import Optional
from pydantic import BaseModel

class StudyBlock(BaseModel):
    """
    A single scheduled study block.
    """
    id: Optional[int] = None
    subject_id: Optional[int] = None
    subject_name: str
    start_time: str
    end_time: str
    type: str = "Study"
    status: str = "pending"

    class Config:
        from_attributes = True
