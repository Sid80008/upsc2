from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from datetime import date, datetime

from app.models.schedule_request import (
    BacklogAdjustmentRequest,
    ScheduleGenerationRequest,
    WeakSubjectRequest,
)
from app.models.schedule_response import ScheduleResponse, DailySchedule
from app.models.report_request import DailyReportRequest
from app.models.study_block import StudyBlock as PydanticStudyBlock
from app.db.database import get_db
from app.db import models
from app.services.scheduler import StudyScheduler

router = APIRouter()
_scheduler = StudyScheduler()

@router.get("/health")
async def health_check() -> dict:
    return {"status": "ok"}

@router.post("/schedule/generate", response_model=ScheduleResponse)
async def generate_schedule(
    payload: ScheduleGenerationRequest,
    db: Session = Depends(get_db)
) -> ScheduleResponse:
    user = db.query(models.User).filter(models.User.id == payload.user_id).first()
    if not user:
        user = models.User(id=payload.user_id, name="Test User")
        db.add(user)
        db.commit()

    plan = db.query(models.StudyPlan).filter(
        models.StudyPlan.user_id == user.id,
        models.StudyPlan.date == payload.start_date
    ).first()

    if not plan:
        plan = models.StudyPlan(user_id=user.id, date=payload.start_date)
        db.add(plan)
        db.commit()
        db.refresh(plan)

        # Generate dummy blocks mapped to database
        block1 = models.StudyBlock(
            plan_id=plan.id,
            subject="History (Dummy)",
            start_time="09:00 AM",
            end_time="11:00 AM",
            status=models.BlockStatus.pending
        )
        block2 = models.StudyBlock(
            plan_id=plan.id,
            subject="Polity (Dummy)",
            start_time="01:00 PM",
            end_time="03:00 PM",
            status=models.BlockStatus.pending
        )
        db.add(block1)
        db.add(block2)
        db.commit()

    blocks = db.query(models.StudyBlock).filter(models.StudyBlock.plan_id == plan.id).all()
    
    pydantic_blocks = [
        PydanticStudyBlock(
            id=b.id,
            subject_name=b.subject,
            start_time=b.start_time,
            end_time=b.end_time,
            status=b.status.value
        ) for b in blocks
    ]

    return ScheduleResponse(
        user_id=user.id,
        generated_date=payload.start_date,
        daily_schedule=[
            DailySchedule(
                date=plan.date,
                blocks=pydantic_blocks
            )
        ],
    )

@router.post("/report/submit")
async def submit_daily_report(
    payload: DailyReportRequest,
    db: Session = Depends(get_db)
) -> dict:
    updated_count = 0
    for block_report in payload.blocks:
        db_block = db.query(models.StudyBlock).filter(models.StudyBlock.id == block_report.block_id).first()
        if db_block:
            db_block.status = models.BlockStatus(block_report.status)
            updated_count += 1
            
            # Simple adaptive logic: If missed, clone it for tomorrow!
            if db_block.status == models.BlockStatus.missed:
                # Find tomorrow's plan
                from datetime import timedelta
                tomorrow = date.today() + timedelta(days=1)
                
                tomorrow_plan = db.query(models.StudyPlan).filter(
                    models.StudyPlan.user_id == payload.user_id,
                    models.StudyPlan.date == tomorrow
                ).first()
                
                if not tomorrow_plan:
                    tomorrow_plan = models.StudyPlan(user_id=payload.user_id, date=tomorrow)
                    db.add(tomorrow_plan)
                    db.commit()
                    db.refresh(tomorrow_plan)
                    
                # Add the retry block
                retry_block = models.StudyBlock(
                    plan_id=tomorrow_plan.id,
                    subject=db_block.subject + " (Retry)",
                    start_time="08:00 AM", # Defaulting
                    end_time="10:00 AM",
                    status=models.BlockStatus.pending
                )
                db.add(retry_block)
                
    db.commit()
    return {"status": "success", "blocks_updated": updated_count}
