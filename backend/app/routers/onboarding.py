import json
from datetime import date, timedelta
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.db.database import get_db
from app.db.models import User
from app.core.deps import get_current_user
from app.schemas import OnboardingRequest, UserSetupRequest
from app.services.scheduler import generate_schedule

router = APIRouter()

@router.post("/complete")
def complete_onboarding(
    payload: OnboardingRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # Update the user record with the exact JSON telemetry
    current_user.goal_type = payload.goal_type

    current_user.target_year = payload.target_year
    current_user.months_remaining = payload.months_remaining
    current_user.current_level = payload.current_level
    
    current_user.preferred_study_slots = json.dumps(payload.preferred_study_slots)
    current_user.wake_time = payload.wake_time
    current_user.sleep_time = payload.sleep_time
    
    current_user.focus_level = payload.focus_level
    current_user.distraction_level = payload.distraction_level
    current_user.peak_focus_time = payload.peak_focus_time
    current_user.primary_problem = payload.primary_problem
    current_user.biggest_problems = json.dumps(payload.biggest_problems)
    
    current_user.session_length = payload.session_length
    current_user.study_style = payload.study_style
    current_user.revision_preference = payload.revision_preference
    
    current_user.weak_subjects = json.dumps(payload.weak_subjects)
    current_user.strong_subjects = json.dumps(payload.strong_subjects)
    current_user.covered_subjects = json.dumps(payload.covered_subjects)
    
    db.commit()
    
    # Immediately trigger schedule generation for the next day as requested by the Senior Engineering Directive
    tomorrow = date.today() + timedelta(days=1)
    schedule = generate_schedule(db, current_user.id, tomorrow)
    
    return {
        "status": "success",
        "message": "Onboarding complete. First schedule generated based on behavioral profile.",
    }

@router.post("/setup")
def setup_user(
    payload: UserSetupRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    current_user.name = payload.name
    current_user.exam_date = payload.exam_date
    current_user.daily_study_hours = payload.daily_study_hours
    current_user.covered_subjects = json.dumps(payload.selected_subjects)
    current_user.preferred_study_slots = json.dumps([payload.preferred_study_time])
    current_user.difficulty_preference = payload.difficulty_preference
    
    db.commit()
    
    # Trigger first schedule generation
    tomorrow = date.today() + timedelta(days=1)
    generate_schedule(db, current_user.id, tomorrow)
    
    return {
        "status": "success",
        "message": "User setup complete. Schedule initialized.",
    }
