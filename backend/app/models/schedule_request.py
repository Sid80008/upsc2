from datetime import date
from typing import List

from pydantic import BaseModel


class ScheduleGenerationRequest(BaseModel):
    """
    Request payload for generating a new study schedule.
    """

    exam_type: str
    exam_date: date
    subjects: List[str]
    daily_study_hours: float
    start_date: date


class BacklogAdjustmentRequest(BaseModel):
    """
    Request payload for redistributing backlog items.
    """

    missed_subjects: List[str]
    missed_topics: List[str]
    missed_days: List[date]


class WeakSubjectRequest(BaseModel):
    """
    Request payload for prioritizing weak subjects.
    """

    subject_name: str
    accuracy_score: float
    recent_test_scores: List[float]

