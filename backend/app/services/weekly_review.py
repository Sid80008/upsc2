"""
Weekly Review Engine
====================
Analyzes 7-day performance, compares to prior week, 
and suggests scheduling adjustments.
"""

import logging
from dataclasses import dataclass
from datetime import date, datetime, timedelta
from typing import Optional, Dict, List
from sqlalchemy.orm import Session
import google.generativeai as genai

from app.db.models import StudyBlock, User
from app.core.config import settings

SUBJECTS = settings.SUBJECTS

logger = logging.getLogger("weekly_review")

@dataclass
class WeeklyReview:
    user_id: int
    week_start: date          # Monday of the reviewed week
    week_end: date            # Sunday of the reviewed week
    generated_at: datetime

    total_blocks: int
    completed_blocks: int
    partial_blocks: int
    missed_blocks: int
    completion_rate: float    # completed / total, rounded to 2 decimal places

    strongest_subject: str    # highest completion rate this week
    weakest_subject: str      # lowest completion rate this week (must have ≥2 blocks)
    most_improved: Optional[str] # subject with biggest miss_count drop vs prior week
    most_declined: Optional[str] # subject with biggest miss_count rise vs prior week

    recommended_weight_adjustments: Dict[str, int]  # { subject: delta } e.g. {"History": +1, "Essay": -1}
    summary_text: str         # human-readable paragraph (rule-based or AI-generated)


def generate_weekly_review(user_id: int, week_start: date, db: Session) -> WeeklyReview:
    """
    Analyzes student performance for the week and generates a structured review.
    """
    # Step A — Define window
    week_end = week_start + timedelta(days=6)
    prior_week_start = week_start - timedelta(days=7)
    prior_week_end = week_start - timedelta(days=1)
    
    # Step B — Fetch this week's blocks
    blocks = db.query(StudyBlock).filter(
        StudyBlock.user_id == user_id,
        StudyBlock.date >= week_start,
        StudyBlock.date <= week_end
    ).all()
    
    if not blocks:
        return WeeklyReview(
            user_id=user_id,
            week_start=week_start,
            week_end=week_end,
            generated_at=datetime.utcnow(),
            total_blocks=0,
            completed_blocks=0,
            partial_blocks=0,
            missed_blocks=0,
            completion_rate=0.0,
            strongest_subject="None",
            weakest_subject="None",
            most_improved=None,
            most_declined=None,
            recommended_weight_adjustments={},
            summary_text="No study data for this week."
        )

    # Step C — Compute counts
    total = len(blocks)
    completed = sum(1 for b in blocks if b.status == "completed")
    partial = sum(1 for b in blocks if b.status == "partial")
    missed = sum(1 for b in blocks if b.status == "missed")
    completion_rate = round(completed / total, 2) if total > 0 else 0.0

    # Step D — Per-subject stats for this week
    subject_stats = {}
    for sub in SUBJECTS:
        sub_blocks = [b for b in blocks if b.subject == sub]
        sub_total = len(sub_blocks)
        sub_comp = sum(1 for b in sub_blocks if b.status == "completed")
        sub_miss = sum(1 for b in sub_blocks if b.status == "missed")
        rate = sub_comp / max(sub_total, 1)
        subject_stats[sub] = {
            "total": sub_total,
            "completed": sub_comp,
            "missed": sub_miss,
            "rate": rate
        }

    # strongest_subject: highest (completed / total) ratio. Min 1 block.
    eligible_strong = [(s, d["rate"]) for s, d in subject_stats.items() if d["total"] >= 1]
    if eligible_strong:
        strongest_subject = max(eligible_strong, key=lambda x: x[1])[0]
    else:
        strongest_subject = "None"

    # weakest_subject: lowest ratio. Min 2 blocks qualifier.
    eligible_weak = [(s, d["rate"]) for s, d in subject_stats.items() if d["total"] >= 2]
    if eligible_weak:
        weakest_subject = min(eligible_weak, key=lambda x: x[1])[0]
    else:
        # Fallback to subject with most misses if no 2+ blocks sub
        weakest_subject = max(subject_stats.items(), key=lambda x: x[1]["missed"])[0]

    # Step E — Compare to prior week
    prior_blocks = db.query(StudyBlock).filter(
        StudyBlock.user_id == user_id,
        StudyBlock.date >= prior_week_start,
        StudyBlock.date <= prior_week_end
    ).all()
    
    most_improved = None
    most_declined = None
    
    if prior_blocks:
        imp_val = 0
        dec_val = 0
        for sub in SUBJECTS:
            this_miss = subject_stats[sub]["missed"]
            prior_miss = sum(1 for b in prior_blocks if b.subject == sub and b.status == "missed")
            
            # Improvement: prior_miss - this_miss > 0
            if prior_miss - this_miss > imp_val:
                imp_val = prior_miss - this_miss
                most_improved = sub
            
            # Decline: this_miss - prior_miss > 0
            if this_miss - prior_miss > dec_val:
                dec_val = this_miss - prior_miss
                most_declined = sub

    # Step F — Weight adjustments
    recommended_adjustments = {}
    for sub in SUBJECTS:
        miss_count = subject_stats[sub]["missed"]
        comp_count = subject_stats[sub]["completed"]
        
        delta = 0
        if miss_count >= 3:
            delta = 2
        elif miss_count >= 1:
            delta = 1
        elif comp_count >= 3:
            delta = -1
        
        # Cap at -2 to +2 (though our logic currently range is -1 to +2)
        delta = max(-2, min(2, delta))
        if delta != 0:
            recommended_adjustments[sub] = delta

    # Step G — Summary text
    summary_text = _generate_summary_text(
        week_start, completion_rate, completed, total, 
        strongest_subject, weakest_subject, 
        most_improved, most_declined
    )

    return WeeklyReview(
        user_id=user_id,
        week_start=week_start,
        week_end=week_end,
        generated_at=datetime.utcnow(),
        total_blocks=total,
        completed_blocks=completed,
        partial_blocks=partial,
        missed_blocks=missed,
        completion_rate=completion_rate,
        strongest_subject=strongest_subject,
        weakest_subject=weakest_subject,
        most_improved=most_improved,
        most_declined=most_declined,
        recommended_weight_adjustments=recommended_adjustments,
        summary_text=summary_text
    )


def _generate_summary_text(week_start, rate, completed, total, strong, weak, imp, dec) -> str:
    """Helper to generate summary via Gemini or Rules."""
    
    if settings.USE_AI_SCHEDULER:
        try:
            prompt = f"""Write a compact UPSC study coaching summary (2-3 sentences) based on these stats:
- Week: {week_start}
- Completion: {rate*100:.0f}% ({completed}/{total} blocks)
- Strongest: {strong}
- Weakest: {weak}
- Improved: {imp or 'None'}
- Declined: {dec or 'None'}

Target: Direct, data-specific, mentor-like tone. No fluff."""
            
            genai.configure(api_key=settings.gemini_api_key)
            model = genai.GenerativeModel("models/gemini-2.0-flash")
            response = model.generate_content(prompt, request_options={"timeout": 10})
            return response.text.strip()
        except Exception as e:
            logger.warning(f"AI Weekly Summary failed: {e}")
            # Fall through to rule-based

    # Rule-based fallback
    imp_text = f"{imp} improved this week." if imp else ""
    dec_text = f"{dec} declined — increase priority next week." if dec else ""
    
    return (f"Week of {week_start}: {rate*100:.0f}% completion ({completed}/{total} blocks). "
            f"Strongest: {strong}. Needs attention: {weak}. "
            f"{imp_text} {dec_text}").strip()
