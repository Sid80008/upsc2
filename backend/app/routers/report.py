"""
Report Router
==============
Routes through Orchestrator. Two endpoints only.
"""

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from datetime import date

from app.db.database import get_db
from app.db.models import DailyReport
from app.schemas import ReportSubmitRequest, ReportSubmitResponse
from app.services.orchestrator import Orchestrator

router = APIRouter()


@router.post("/submit", response_model=ReportSubmitResponse)
def submit_report_endpoint(
    request: ReportSubmitRequest,
    db: Session = Depends(get_db),
):
    orch = Orchestrator(db)
    return orch.submit_report(request)


@router.get("/{user_id}/{target_date}")
def get_report_endpoint(
    user_id: int,
    target_date: date,
    db: Session = Depends(get_db),
):
    report = (
        db.query(DailyReport)
        .filter(DailyReport.user_id == user_id, DailyReport.date == target_date)
        .first()
    )

    if not report:
        raise HTTPException(status_code=404, detail="No report found for this date")

    return {
        "id": report.id,
        "user_id": report.user_id,
        "date": report.date,
        "submitted_at": report.submitted_at,
        "blocks_completed": report.blocks_completed,
        "blocks_partial": report.blocks_partial,
        "blocks_missed": report.blocks_missed,
        "notes": report.notes,
    }
