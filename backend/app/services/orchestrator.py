"""
Orchestrator
=============
Single entry point for all business logic.
API endpoints call the Orchestrator. The Orchestrator calls services.
Nothing else calls services directly.

Loop position: Orchestrator sits between API layer and Decision Engine.
"""

from datetime import date
from typing import List
from sqlalchemy.orm import Session

from app.db.models import StudyBlock
from app.schemas import ReportSubmitRequest, ReportSubmitResponse, TaskAddRequest


class Orchestrator:
    def __init__(self, db: Session):
        self.db = db

    def get_schedule(self, user_id: int, target_date: date) -> List[StudyBlock]:
        from app.services.ai_engine import USE_AI_SCHEDULER
        if USE_AI_SCHEDULER:
            from app.services.ai_engine import generate_schedule
            return generate_schedule(user_id, target_date, self.db)
        from app.services import rule_based_scheduler
        return rule_based_scheduler.generate(user_id, target_date, self.db)

    def submit_report(self, request: ReportSubmitRequest) -> ReportSubmitResponse:
        from app.services import report_processor
        return report_processor.process_report(request, self.db)

    def get_weekly_review(self, user_id: int, week_start: date):
        from app.services import weekly_review
        return weekly_review.generate_weekly_review(user_id, week_start, self.db)

    def add_task(self, request: TaskAddRequest) -> StudyBlock:
        new_block = StudyBlock(
            user_id=request.user_id or 1,
            subject=request.subject,
            topic=request.topic,
            date=request.date,
            start_time=request.start_time,
            duration_minutes=request.duration_minutes,
            status="pending",
            completion_percent=0
        )
        self.db.add(new_block)
        self.db.commit()
        self.db.refresh(new_block)
        return new_block
