"""
Signal Extractor Service
=========================
Reads historical StudyBlocks and DailyReports to produce
structured behavioral signals per user. No AI. No external APIs.

Loop position: sits inside the Decision Engine, feeding data
to the rule-based scheduler.
"""

from dataclasses import dataclass, field, asdict
from datetime import date, datetime, timedelta
from typing import List, Dict
from collections import Counter
from sqlalchemy.orm import Session

from app.db.models import StudyBlock
from app.services.rule_based_scheduler import SUBJECTS


# ---------------------------------------------------------------------------
# Data structures
# ---------------------------------------------------------------------------

@dataclass
class SubjectSignal:
    subject: str
    miss_count: int = 0
    partial_count: int = 0
    complete_count: int = 0
    avg_completion_pct: float = 0.0
    is_weak: bool = False
    preferred_slots: List[str] = field(default_factory=list)


@dataclass
class UserSignals:
    user_id: int
    computed_at: datetime = field(default_factory=datetime.utcnow)
    weak_subjects: List[str] = field(default_factory=list)
    avoidance_patterns: Dict[str, List[str]] = field(default_factory=dict)
    consistency_score: float = 0.0
    recommended_slot_adjustments: Dict[str, str] = field(default_factory=dict)
    subject_signals: List[SubjectSignal] = field(default_factory=list)


# ---------------------------------------------------------------------------
# Main entry point
# ---------------------------------------------------------------------------

def extract_signals(user_id: int, db: Session) -> UserSignals:
    """
    Analyse the last 14 days of StudyBlocks and return structured
    behavioural signals for the given user.
    """

    # Step A — Define the window
    today = date.today()
    lookback_date = today - timedelta(days=14)

    # Step B — Fetch all StudyBlocks in window
    blocks = (
        db.query(StudyBlock)
        .filter(
            StudyBlock.user_id == user_id,
            StudyBlock.date >= lookback_date,
        )
        .all()
    )

    if not blocks:
        return UserSignals(
            user_id=user_id,
            subject_signals=[SubjectSignal(subject=s) for s in SUBJECTS],
        )

    # Step C — Build per-subject stats
    subject_signals: List[SubjectSignal] = []

    for subject in SUBJECTS:
        sub_blocks = [b for b in blocks if b.subject == subject]

        miss_count = sum(1 for b in sub_blocks if b.status == "missed")
        partial_count = sum(1 for b in sub_blocks if b.status == "partial")
        complete_count = sum(1 for b in sub_blocks if b.status == "completed")

        if sub_blocks:
            avg_completion_pct = round(
                sum(b.completion_percent for b in sub_blocks) / len(sub_blocks), 2
            )
        else:
            avg_completion_pct = 0.0

        is_weak = miss_count >= 3

        # Preferred slots: start_times where status == "completed",
        # most frequent first, ties sorted ascending.
        completed_times = [b.start_time for b in sub_blocks if b.status == "completed"]
        if completed_times:
            counter = Counter(completed_times)
            # Sort by (-frequency, time_string) so most frequent first, ties ascending
            preferred_slots = sorted(counter.keys(), key=lambda t: (-counter[t], t))
        else:
            preferred_slots = []

        subject_signals.append(
            SubjectSignal(
                subject=subject,
                miss_count=miss_count,
                partial_count=partial_count,
                complete_count=complete_count,
                avg_completion_pct=avg_completion_pct,
                is_weak=is_weak,
                preferred_slots=preferred_slots,
            )
        )

    # Step D — Compute consistency score
    terminal_blocks = [
        b for b in blocks if b.status in ("completed", "partial", "missed")
    ]
    total = len(terminal_blocks)
    completed = sum(1 for b in terminal_blocks if b.status == "completed")
    consistency_score = round(completed / total, 2) if total > 0 else 0.0

    # Step E — Build avoidance patterns
    avoidance_patterns: Dict[str, List[str]] = {}
    for sig in subject_signals:
        if not sig.is_weak:
            continue
        sub_blocks = [b for b in blocks if b.subject == sig.subject]
        missed_times = [b.start_time for b in sub_blocks if b.status == "missed"]
        counter = Counter(missed_times)
        bad_slots = sorted(t for t, count in counter.items() if count >= 2)
        if bad_slots:
            avoidance_patterns[sig.subject] = bad_slots

    # Step F — Build recommended slot adjustments
    recommended_slot_adjustments: Dict[str, str] = {}
    for sig in subject_signals:
        if sig.preferred_slots:
            recommended_slot_adjustments[sig.subject] = sig.preferred_slots[0]

    # Step G — Return
    return UserSignals(
        user_id=user_id,
        computed_at=datetime.utcnow(),
        weak_subjects=[s.subject for s in subject_signals if s.is_weak],
        avoidance_patterns=avoidance_patterns,
        consistency_score=consistency_score,
        recommended_slot_adjustments=recommended_slot_adjustments,
        subject_signals=subject_signals,
    )
