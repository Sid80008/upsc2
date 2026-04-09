"""
Exam Countdown Optimizer
========================
Shifts study behavior from coverage to revision to final sprint.
Determines intensity and subject weighting.
"""

from dataclasses import dataclass
from datetime import date
from typing import Dict
from app.db.models import User
from app.core.config import settings

SUBJECTS = settings.SUBJECTS


@dataclass
class ExamCountdownState:
    days_remaining: int
    mode: str              # "coverage", "balanced", "revision", "final_sprint"
    revision_weight: float # 0.0 to 1.0
    subject_priorities: Dict[str, int]
    schedule_intensity: str   # "normal", "reduced", "intensive"

def compute_countdown_state(user: User, signals) -> ExamCountdownState:
    """
    Computes the current trajectory state based on exam date and behavioral signals.
    """
    today = date.today()
    
    if user.exam_date is None:
        days_remaining = -1
    else:
        days_remaining = (user.exam_date - today).days

    # Step 1 — Determine Mode & Weights
    if days_remaining < 0:
        mode = "coverage"
        revision_weight = 0.2
        intensity = "normal"
    elif days_remaining > 180:
        mode = "coverage"
        revision_weight = 0.15
        intensity = "normal"
    elif days_remaining > 90:
        mode = "balanced"
        revision_weight = 0.30
        intensity = "normal"
    elif days_remaining > 30:
        mode = "revision"
        revision_weight = 0.55
        intensity = "intensive"
    else: # 0 to 30 days
        mode = "final_sprint"
        revision_weight = 0.75
        intensity = "intensive"

    # Step 2 — Consistency check to override intensity
    # Redefine intensity if consistency is very low
    if signals.consistency_score < 0.3 and mode in ["coverage", "balanced"]:
        intensity = "reduced"

    # Step 3 — Subject Priorities
    priorities = {}
    weak_subs = signals.weak_subjects or []
    
    for sub in SUBJECTS:
        score = 5 # base
        
        # Weak bonus
        if sub in weak_subs:
            score += 3
            
            # Additional countdown bonus for weak subjects
            if mode == "final_sprint":
                score += 2
            elif mode == "revision":
                score += 1
                
        # Final Sprint: reduce non-weak subjects score further? 
        # Requirement says "Reduce schedule to highest-signal subjects only"
        # We handle this by making scores for weak subjects very high (10).
        
        priorities[sub] = max(1, min(10, score))
        
    return ExamCountdownState(
        days_remaining=days_remaining,
        mode=mode,
        revision_weight=revision_weight,
        subject_priorities=priorities,
        schedule_intensity=intensity
    )
