"""
Schedule Router
================
Routes through Orchestrator. Two endpoints only.
"""

from fastapi import APIRouter, Depends, HTTPException

from sqlalchemy.orm import Session
from datetime import date, datetime, timedelta

from app.db.database import get_db
from app.schemas import (
    ScheduleGenerateRequest, ScheduleGenerateResponse, StudyBlockOut,
    UserSignalsOut, SubjectSignalOut, BehavioralFingerprintOut,
    WeeklyReviewOut, TaskAddRequest,
)

from app.services.orchestrator import Orchestrator
from app.services import signal_extractor
from app.services import behavioral_fingerprint

router = APIRouter()


@router.get("/signals/{user_id}", response_model=UserSignalsOut)
def get_signals_endpoint(
    user_id: int,
    db: Session = Depends(get_db),
):
    """Read-only signal + fingerprint computation. No Orchestrator involvement."""
    signals = signal_extractor.extract_signals(user_id, db)
    fp = behavioral_fingerprint.compute_fingerprint(user_id, db)
    return UserSignalsOut(
        user_id=signals.user_id,
        computed_at=signals.computed_at,
        consistency_score=signals.consistency_score,
        weak_subjects=signals.weak_subjects,
        avoidance_patterns=signals.avoidance_patterns,
        recommended_slot_adjustments=signals.recommended_slot_adjustments,
        subject_signals=[
            SubjectSignalOut(
                subject=s.subject,
                miss_count=s.miss_count,
                partial_count=s.partial_count,
                complete_count=s.complete_count,
                avg_completion_pct=s.avg_completion_pct,
                is_weak=s.is_weak,
                preferred_slots=s.preferred_slots,
            )
            for s in signals.subject_signals
        ],
        fingerprint=BehavioralFingerprintOut(**fp),
    )


def _build_response(date_obj, blocks):
    """Build ScheduleGenerateResponse from a list of StudyBlock ORM objects."""
    planned = sum(b.duration_minutes for b in blocks)
    completed = sum(
        int(b.duration_minutes * (b.completion_percent / 100)) for b in blocks
    )

    # Enrich blocks with calculated end_time for UI
    for b in blocks:
        try:
            start_dt = datetime.strptime(b.start_time, "%H:%M")
            end_dt = start_dt + timedelta(minutes=b.duration_minutes)
            b.end_time = end_dt.strftime("%H:%M")
        except Exception:
            b.end_time = b.start_time

    return ScheduleGenerateResponse(
        date=date_obj,
        total_planned_time=planned,
        total_completed_time=completed,
        total_planned_minutes=planned,
        total_completed_minutes=completed,
        blocks=blocks,
    )


@router.post("/generate", response_model=ScheduleGenerateResponse)
def generate_schedule_endpoint(
    request: ScheduleGenerateRequest,
    db: Session = Depends(get_db),
):
    uid = request.user_id or 1
    orch = Orchestrator(db)
    blocks = orch.get_schedule(uid, request.date)
    return _build_response(request.date, blocks)


@router.get("/{user_id}/{target_date}", response_model=ScheduleGenerateResponse)
def get_schedule_endpoint(
    user_id: int,
    target_date: date,
    db: Session = Depends(get_db),
):
    orch = Orchestrator(db)
    blocks = orch.get_schedule(user_id, target_date)
    return _build_response(target_date, blocks)


@router.get("/weekly-review/{user_id}/{week_start}", response_model=WeeklyReviewOut)
def get_weekly_review_endpoint(
    user_id: int,
    week_start: date,
    db: Session = Depends(get_db),
):
    """Retrieves or generates a weekly performance review."""
    # Validation: must be a Monday (weekday() == 0)
    if week_start.weekday() != 0:
        raise HTTPException(status_code=400, detail="week_start must be a Monday")

    orch = Orchestrator(db)
    review = orch.get_weekly_review(user_id, week_start)
    return review


# --------------------------------------------------------------------------
# COMMENTED-OUT ENDPOINTS — preserved for future phases
# --------------------------------------------------------------------------

@router.post("/add_task", response_model=StudyBlockOut)
def add_task_endpoint(
    request: TaskAddRequest,
    db: Session = Depends(get_db),
):
    orch = Orchestrator(db)
    return orch.add_task(request)

# @router.get("/block/{block_id}", response_model=StudyBlockOut)
# def get_single_block(
#     block_id: int,
#     current_user: User = Depends(get_current_user),
#     db: Session = Depends(get_db),
# ):
#     ...

# @router.patch("/block/update-time")
# def update_block_time(
#     request: TimeUpdateRequest,
#     current_user: User = Depends(get_current_user),
#     db: Session = Depends(get_db),
# ):
#     ...
