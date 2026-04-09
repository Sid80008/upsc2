from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.db.database import get_db
from app.db.models import User, DailyReport, StudyBlock
from app.core.deps import get_current_user
from app.services.ai_engine import AIEngine
from typing import Dict
from datetime import date, timedelta
import json

router = APIRouter()

@router.get("/ai_analysis", response_model=Dict[str, str])
def get_ai_analysis(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    # Fetch last 7 days of reports
    seven_days_ago = date.today() - timedelta(days=7)
    reports = db.query(DailyReport).filter(
        DailyReport.user_id == current_user.id,
        DailyReport.date >= seven_days_ago
    ).all()
    
    # Fetch recent study blocks to see subjects
    blocks = db.query(StudyBlock).filter(
        StudyBlock.user_id == current_user.id,
        StudyBlock.date >= seven_days_ago
    ).all()

    completed_blocks = sum(1 for b in blocks if b.status == 'completed')
    total_blocks = len(blocks)
    
    user_data = {
        "name": current_user.name,
        "weak_subjects": current_user.weak_subjects,
        "daily_study_hours": current_user.daily_study_hours
    }
    
    analysis_text = AIEngine.generate_comprehensive_insights(
        user_data=user_data,
        completed_blocks=completed_blocks,
        total_blocks=total_blocks
    )
    
    return {"analysis": analysis_text}
