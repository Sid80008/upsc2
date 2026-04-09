from datetime import date
from typing import List

from pydantic import BaseModel

from .study_block import StudyBlock


class DailySchedule(BaseModel):
    """
    Study schedule for a specific calendar day.
    """

    date: date
    blocks: List[StudyBlock]


class ScheduleResponse(BaseModel):
    """
    Overall study schedule generated for a user.
    """

    user_id: int
    generated_date: date
    daily_schedule: List[DailySchedule]

