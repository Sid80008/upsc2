"""
Report Processor
=================
Processes daily reports: validates blocks, updates statuses,
creates/upserts DailyReport, reschedules missed blocks.

Loop position: Daily Report → Orchestrator → (this) → Schedule (next day)
"""

from datetime import datetime, timedelta
from typing import List
from sqlalchemy.orm import Session
from fastapi import HTTPException

from app.db.models import StudyBlock, DailyReport, User
from app.schemas import ReportSubmitRequest, ReportSubmitResponse
from app.services.rule_based_scheduler import _time_to_minutes, _minutes_to_time


def process_report(request: ReportSubmitRequest, db: Session) -> ReportSubmitResponse:
    """
    Step 1 — Validate (all-or-nothing)
    Step 2 — Update blocks
    Step 3 — Count
    Step 4 — Upsert DailyReport
    Step 5 — Reschedule missed
    Step 6 — Return
    """
    user_id = request.user_id
    if not user_id:
        raise HTTPException(status_code=400, detail="User ID required")

    # ------------------------------------------------------------------
    # Step 1 — Validate
    # ------------------------------------------------------------------
    block_records = []
    for item in request.blocks:
        block = db.query(StudyBlock).filter(StudyBlock.id == item.block_id).first()
        if not block or block.user_id != user_id:
            raise HTTPException(
                status_code=400,
                detail=f"Invalid block_id: {item.block_id}"
            )
        block_records.append((block, item))

    # ------------------------------------------------------------------
    # Step 2 — Update blocks
    # ------------------------------------------------------------------
    for block, item in block_records:
        block.status = item.status
        block.completion_percent = item.completion_percent
    db.commit()

    # ------------------------------------------------------------------
    # Step 3 — Count
    # ------------------------------------------------------------------
    blocks_completed = sum(1 for _, item in block_records if item.status == "completed")
    blocks_partial = sum(1 for _, item in block_records if item.status == "partial")
    blocks_missed = sum(1 for _, item in block_records if item.status == "missed")

    # ------------------------------------------------------------------
    # Step 4 — Upsert DailyReport
    # ------------------------------------------------------------------
    report = (
        db.query(DailyReport)
        .filter(DailyReport.user_id == user_id, DailyReport.date == request.date)
        .first()
    )

    if report:
        report.blocks_completed = blocks_completed
        report.blocks_partial = blocks_partial
        report.blocks_missed = blocks_missed
        report.notes = request.notes
        report.submitted_at = datetime.utcnow()
    else:
        report = DailyReport(
            user_id=user_id,
            date=request.date,
            blocks_completed=blocks_completed,
            blocks_partial=blocks_partial,
            blocks_missed=blocks_missed,
            notes=request.notes,
        )
        db.add(report)

    db.commit()
    db.refresh(report)

    # ------------------------------------------------------------------
    # Step 5 — Reschedule missed blocks
    # ------------------------------------------------------------------
    missed_blocks = [block for block, item in block_records if item.status == "missed"]
    rescheduled_count = reschedule_missed(user_id, missed_blocks, request.date, db)

    # ------------------------------------------------------------------
    # Step 5B — Update User.consistency_score (Phase 3)
    # ------------------------------------------------------------------
    from app.services import signal_extractor
    signals = signal_extractor.extract_signals(user_id, db)
    user = db.query(User).filter(User.id == user_id).first()
    if user:
        user.consistency_score = signals.consistency_score
        db.commit()

    # ------------------------------------------------------------------
    # Step 6 — Return
    # ------------------------------------------------------------------
    return ReportSubmitResponse(
        report_id=report.id,
        blocks_completed=blocks_completed,
        blocks_partial=blocks_partial,
        blocks_missed=blocks_missed,
        rescheduled_count=rescheduled_count,
    )


def reschedule_missed(
    user_id: int,
    missed_blocks: List[StudyBlock],
    original_date,
    db: Session,
) -> int:
    """Create new pending blocks on the next day for each missed block."""
    target_date = original_date + timedelta(days=1)
    created_count = 0

    for missed in missed_blocks:
        # Find latest block on target_date to calculate next start
        latest = (
            db.query(StudyBlock)
            .filter(StudyBlock.user_id == user_id, StudyBlock.date == target_date)
            .order_by(StudyBlock.start_time.desc())
            .first()
        )

        if latest:
            next_start = (
                _time_to_minutes(latest.start_time)
                + latest.duration_minutes
                + 10
            )
        else:
            next_start = _time_to_minutes("07:00")  # 420

        # Check 21:00 boundary
        if next_start + missed.duration_minutes > _time_to_minutes("21:00"):  # 1260
            continue  # skip — can't fit

        new_block = StudyBlock(
            user_id=user_id,
            subject=missed.subject,
            date=target_date,
            start_time=_minutes_to_time(next_start),
            duration_minutes=missed.duration_minutes,
            status="pending",
            completion_percent=0,
            rescheduled_from_id=missed.id,
        )
        db.add(new_block)
        db.commit()  # commit each so the next iteration sees it
        db.refresh(new_block)
        created_count += 1

    return created_count
