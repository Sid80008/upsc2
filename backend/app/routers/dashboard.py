from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from datetime import date, timedelta, datetime
from typing import List
from app.db.database import get_db
from app.db.models import StudyBlock, User, DailyReport
from app.schemas import DashboardSummary
from app.core.deps import get_current_user

router = APIRouter()

@router.get("/summary", response_model=DashboardSummary)
def get_dashboard_summary(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    today = date.today()
    week_ago = today - timedelta(days=7)
    
    # Study Blocks Today
    blocks_today = db.query(StudyBlock).filter(
        StudyBlock.user_id == current_user.id,
        StudyBlock.date == today
    ).all()
    
    total_min_today = sum(b.time_spent_minutes for b in blocks_today)
    total_planned_today = sum(b.duration_minutes for b in blocks_today)
    
    pending_today = len([b for b in blocks_today if b.status == "pending"])
    
    completion_percent = 0
    if total_planned_today > 0:
        completion_percent = int((total_min_today / total_planned_today) * 100)
    
    # Weekly hours
    blocks_week = db.query(StudyBlock).filter(
        StudyBlock.user_id == current_user.id,
        StudyBlock.date >= week_ago,
        StudyBlock.date <= today
    ).all()
    total_min_week = sum(b.time_spent_minutes for b in blocks_week)
    
    # Streak Logic (Checking DailyReports)
    recent_reports = db.query(DailyReport).filter(
        DailyReport.user_id == current_user.id
    ).order_by(DailyReport.date.desc()).all()
    
    streak = 0
    check_date = today
    for report in recent_reports:
        if report.date == check_date:
            if report.blocks_completed > 0 or report.blocks_partial > 0:
                streak += 1
                check_date -= timedelta(days=1)
            else:
                break
        elif report.date < check_date:
            # Skip today if it's still ongoing
            if check_date == today:
                check_date -= timedelta(days=1)
                if report.date == check_date:
                    if report.blocks_completed > 0 or report.blocks_partial > 0:
                        streak += 1
                        check_date -= timedelta(days=1)
                    else:
                        break
            else:
                break
                
    # Missed blocks last 3 days
    three_days_ago = today - timedelta(days=3)
    missed_count = db.query(StudyBlock).filter(
        StudyBlock.user_id == current_user.id,
        StudyBlock.date >= three_days_ago,
        StudyBlock.date < today,
        StudyBlock.status == "missed"
    ).count()
    
    return DashboardSummary(
        total_study_hours_today=round(total_min_today / 60, 1),
        total_study_hours_week=round(total_min_week / 60, 1),
        completion_percentage_today=min(completion_percent, 100),
        streak_days=streak,
        pending_blocks_today=pending_today,
        missed_blocks_last_3_days=missed_count,
        xp=current_user.xp or 0
    )
