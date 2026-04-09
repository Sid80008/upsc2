"""
Behavioral Fingerprint
=======================
Computes a 30-day behavioral profile from historical StudyBlocks.
Read-only — does not affect scheduling in this phase.

Loop position: read-only analytics attached to signals endpoint.
"""

from datetime import date, timedelta
from typing import Optional, Dict, Any
from collections import Counter, defaultdict
from sqlalchemy.orm import Session

from app.db.models import StudyBlock


DAYS_OF_WEEK = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]


def compute_fingerprint(user_id: int, db: Session) -> Dict[str, Any]:
    """
    Analyse the last 30 days of StudyBlocks and return a behavioral profile.
    All values default to None if insufficient data.
    """

    today = date.today()
    lookback = today - timedelta(days=30)

    blocks = (
        db.query(StudyBlock)
        .filter(
            StudyBlock.user_id == user_id,
            StudyBlock.date >= lookback,
        )
        .all()
    )

    result: Dict[str, Any] = {
        "best_study_day": None,
        "worst_study_day": None,
        "avg_daily_completion_pct": None,
        "longest_streak_days": None,
        "current_streak_days": None,
        "most_avoided_subject": None,
        "most_consistent_subject": None,
        "peak_performance_hour": None,
    }

    if not blocks:
        return result

    # ── Per-day-of-week completion ────────────────────────────────────
    day_completed: Dict[str, int] = defaultdict(int)
    day_total: Dict[str, int] = defaultdict(int)

    for b in blocks:
        if b.status in ("completed", "partial", "missed"):
            dow = DAYS_OF_WEEK[b.date.weekday()]
            day_total[dow] += 1
            if b.status == "completed":
                day_completed[dow] += 1

    if day_total:
        day_rates = {d: (day_completed[d] / day_total[d]) for d in day_total}
        result["best_study_day"] = max(day_rates, key=day_rates.get)
        result["worst_study_day"] = min(day_rates, key=day_rates.get)

    # ── Average daily completion pct ──────────────────────────────────
    date_completed: Dict[date, int] = defaultdict(int)
    date_total: Dict[date, int] = defaultdict(int)

    for b in blocks:
        if b.status in ("completed", "partial", "missed"):
            date_total[b.date] += 1
            if b.status == "completed":
                date_completed[b.date] += 1

    if date_total:
        daily_pcts = [date_completed[d] / date_total[d] for d in date_total]
        result["avg_daily_completion_pct"] = round(sum(daily_pcts) / len(daily_pcts), 2)

    # ── Streaks ───────────────────────────────────────────────────────
    # A "day with study" = any completed block on that date
    study_dates = sorted({b.date for b in blocks if b.status == "completed"})

    if study_dates:
        longest = 1
        current = 1

        for i in range(1, len(study_dates)):
            if (study_dates[i] - study_dates[i - 1]).days == 1:
                current += 1
                longest = max(longest, current)
            else:
                current = 1

        result["longest_streak_days"] = longest

        # Current streak ending today (or most recent)
        current_streak = 1
        check = today
        if check not in study_dates:
            # Check if yesterday is in study_dates
            check = today - timedelta(days=1)
            if check not in study_dates:
                current_streak = 0

        if current_streak > 0 and check in study_dates:
            idx = study_dates.index(check)
            for i in range(idx, 0, -1):
                if (study_dates[i] - study_dates[i - 1]).days == 1:
                    current_streak += 1
                else:
                    break

        result["current_streak_days"] = current_streak
    else:
        result["longest_streak_days"] = 0
        result["current_streak_days"] = 0

    # ── Most avoided subject ──────────────────────────────────────────
    missed_subjects = [b.subject for b in blocks if b.status == "missed"]
    if missed_subjects:
        result["most_avoided_subject"] = Counter(missed_subjects).most_common(1)[0][0]

    # ── Most consistent subject ───────────────────────────────────────
    subj_completed: Dict[str, int] = defaultdict(int)
    subj_total: Dict[str, int] = defaultdict(int)

    for b in blocks:
        if b.status in ("completed", "partial", "missed"):
            subj_total[b.subject] += 1
            if b.status == "completed":
                subj_completed[b.subject] += 1

    if subj_total:
        subj_rates = {s: subj_completed[s] / subj_total[s] for s in subj_total if subj_total[s] > 0}
        if subj_rates:
            result["most_consistent_subject"] = max(subj_rates, key=subj_rates.get)

    # ── Peak performance hour ─────────────────────────────────────────
    completed_hours = []
    for b in blocks:
        if b.status == "completed" and b.start_time:
            try:
                hour = int(b.start_time.split(":")[0])
                completed_hours.append(f"{hour:02d}:00")
            except (ValueError, IndexError):
                pass

    if completed_hours:
        result["peak_performance_hour"] = Counter(completed_hours).most_common(1)[0][0]

    return result
