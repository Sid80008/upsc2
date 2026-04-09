from datetime import date
from typing import List

from pydantic import BaseModel


class DailyReport(BaseModel):
    """
    Summary of a single day's study activity.
    """

    date: date
    completed_tasks: List[str]
    partial_tasks: List[str]
    missed_tasks: List[str]
    distraction_time: float

