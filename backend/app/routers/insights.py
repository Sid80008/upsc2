from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from datetime import date

from app.db.database import get_db
from app.services import signal_extractor
from app.services import behavioral_fingerprint

router = APIRouter()

@router.get("/subjects/{user_id}")
def get_subject_insights(
    user_id: int,
    db: Session = Depends(get_db)
):
    """
    Returns per-subject performance data based on real behavioral signals.
    """
    signals = signal_extractor.extract_signals(user_id, db)
    return {
        "subjects": [
            {
                "subject": s.subject,
                "completion_rate": s.complete_count / max(s.complete_count + s.partial_count + s.miss_count, 1),
                "miss_count": s.miss_count,
                "is_weak": s.is_weak,
                "avg_completion_pct": s.avg_completion_pct
            }
            for s in signals.subject_signals
        ]
    }

@router.get("/summary/{user_id}")
def get_summary_insights(
    user_id: int,
    db: Session = Depends(get_db)
):
    """
    Returns high-level consistency and fingerprint summary.
    """
    signals = signal_extractor.extract_signals(user_id, db)
    fingerprint = behavioral_fingerprint.compute_fingerprint(user_id, db)
    return {
        "consistency_score": signals.consistency_score,
        "weak_subjects": signals.weak_subjects,
        "best_study_day": fingerprint["best_study_day"],
        "current_streak_days": fingerprint["current_streak_days"],
        "peak_performance_hour": fingerprint["peak_performance_hour"],
        "most_avoided_subject": fingerprint["most_avoided_subject"]
    }
