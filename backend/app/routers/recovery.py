from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from datetime import date, timedelta
from typing import List
from app.db.database import get_db
from app.db.models import StudyBlock, User
from app.schemas import RecoveryOptimizeResponse
from app.core.deps import get_current_user

router = APIRouter()

@router.post("/optimize", response_model=RecoveryOptimizeResponse)
def optimize_recovery(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    # 1. Identity missed/partial blocks from last 7 days
    today = date.today()
    seven_days_ago = today - timedelta(days=7)
    
    backlog = db.query(StudyBlock).filter(
        StudyBlock.user_id == current_user.id,
        StudyBlock.date >= seven_days_ago,
        StudyBlock.date < today,
        StudyBlock.status.in_(["missed", "pending"]),
        StudyBlock.rescheduled_from_id == None
    ).all()
    
    if not backlog:
        return RecoveryOptimizeResponse(number_of_blocks_rescheduled=0, affected_dates=[])
    
    # 2. Reschedule into next 3 days
    rescheduled_count = 0
    affected_dates = set()
    
    for i, block in enumerate(backlog):
        target_offset = (i % 3) + 1 # Next 1, 2, or 3 days
        target_date = today + timedelta(days=target_offset)
        
        # Check total hours on that date to respect limits
        existing_hours = db.query(StudyBlock).filter(
            StudyBlock.user_id == current_user.id,
            StudyBlock.date == target_date
        ).count() * (current_user.session_length / 60 if current_user.session_length else 1.5)
        
        if existing_hours < 10: # Safety cap
            new_block = StudyBlock(
                user_id=current_user.id,
                subject=f"[Backlog] {block.subject}",
                date=target_date,
                start_time="20:00", # Suggest late evening slots for backlog
                duration_minutes=block.duration_minutes,
                status="pending",
                rescheduled_from_id=block.id
            )
            db.add(new_block)
            block.status = "rescheduled"
            rescheduled_count += 1
            affected_dates.add(target_date)
            
    db.commit()
    return RecoveryOptimizeResponse(
        number_of_blocks_rescheduled=rescheduled_count,
        affected_dates=list(affected_dates)
    )
