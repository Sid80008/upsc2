from datetime import date
from typing import Optional

from pydantic import BaseModel


class User(BaseModel):
    """
    Basic user model for the study planning system.

    This only captures core attributes; persistence and
    authentication details will be added later.
    """

    id: int
    name: str
    exam_type: str
    exam_date: Optional[date] = None
    daily_study_hours: Optional[float] = None


