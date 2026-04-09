from datetime import date
from typing import List

from pydantic import BaseModel

from .subject import Subject


class StudyPlan(BaseModel):
    """
    High-level study plan for a user.

    Links a user to a set of subjects and a target exam date.
    """

    user_id: int
    subjects: List[Subject]
    start_date: date
    target_exam_date: date

