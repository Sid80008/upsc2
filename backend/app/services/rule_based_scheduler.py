"""
Rule-Based Deterministic Scheduler
===================================
Generates study schedules using fixed subject rotation,
enhanced with signal-aware rules (Phase 3).
Gemini is never called from this module.

Loop position: Decision Engine → Schedule
"""

from datetime import date, timedelta
from typing import List
from sqlalchemy.orm import Session

from app.db.models import StudyBlock, User
from app.services import exam_countdown


from app.core.config import settings

SUBJECTS = settings.SUBJECTS



# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _time_to_minutes(t: str) -> int:
    """Convert "HH:MM" to integer minutes from midnight."""
    parts = t.split(":")
    return int(parts[0]) * 60 + int(parts[1])


def _minutes_to_time(m: int) -> str:
    """Convert integer minutes from midnight to "HH:MM"."""
    h = m // 60
    mins = m % 60
    return f"{h:02d}:{mins:02d}"


# ---------------------------------------------------------------------------
# Main entry point
# ---------------------------------------------------------------------------

def generate(user_id: int, target_date: date, db: Session) -> List[StudyBlock]:
    """
    Deterministic schedule generation.

    Rules executed in order:
      1.  Idempotency — return existing blocks if already generated.
      2.  Rescheduled blocks first — pull orphaned pending blocks from past dates.
      3.  Subject rotation — pick up where the user left off.
      3B. Weak subject priority — insert highest-miss weak subject first.
      3C. (applied inside Rule 4) Slot avoidance — skip avoided time slots.
      4.  Block generation — fill the day up to daily_study_hours or 21:00.
      5.  Commit and return.
    """

    BLOCK_DURATION = 90    # minutes
    GAP_MINUTES = 10
    DAY_START = _time_to_minutes("07:00")   # 420
    DAY_END = _time_to_minutes("21:00")     # 1260

    # ------------------------------------------------------------------
    # Rule 0 — Countdown and weight adjustment
    # ------------------------------------------------------------------
    # Extract signals early for Rule 0
    from app.services.signal_extractor import extract_signals
    signals = extract_signals(user_id, db)
    
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        return []
        
    countdown = exam_countdown.compute_countdown_state(user, signals)
    
    # Effective study minutes
    if countdown.schedule_intensity == "intensive":
        effective_minutes = (user.daily_study_hours + 1) * 60
    elif countdown.schedule_intensity == "reduced":
        # Directive says: max((user.daily_study_hours - 1), 3) * 60
        # Wait, if daily_study_hours is 6, (6-1)=5. max(5,3) is 5.
        effective_minutes = max((user.daily_study_hours - 1), 3) * 60
    else:
        effective_minutes = user.daily_study_hours * 60
    
    # Subject rotation list based on priority frequency
    def _is_eligible(sub_name):
        score = countdown.subject_priorities.get(sub_name, 5)
        day_val = target_date.toordinal()
        if score >= 8: return (day_val % 2 == 0)
        if score >= 4: return (day_val % 3 == 0)
        return (day_val % 5 == 0)

    # Build weighted rotation list for today
    day_rotation = [s for s in SUBJECTS if _is_eligible(s)]
    if not day_rotation:
        day_rotation = SUBJECTS # fallback

    # ------------------------------------------------------------------
    # Rule 1 — Idempotency
    # ------------------------------------------------------------------
    existing = (
        db.query(StudyBlock)
        .filter(StudyBlock.user_id == user_id, StudyBlock.date == target_date)
        .order_by(StudyBlock.start_time)
        .all()
    )
    if existing:
        return existing

    # ------------------------------------------------------------------
    # Rule 2 — Rescheduled blocks first
    # ------------------------------------------------------------------
    rescheduled = (
        db.query(StudyBlock)
        .filter(
            StudyBlock.user_id == user_id,
            StudyBlock.date < target_date,
            StudyBlock.status == "pending",
            StudyBlock.rescheduled_from_id.isnot(None),
        )
        .order_by(StudyBlock.date, StudyBlock.start_time)
        .all()
    )

    cursor_minutes = DAY_START  # tracks the next available start time
    rescheduled_study_minutes = 0
    rescheduled_subjects = set()

    for block in rescheduled:
        if cursor_minutes + block.duration_minutes > DAY_END:
            break  # can't fit — stop pulling rescheduled blocks
        block.date = target_date
        block.start_time = _minutes_to_time(cursor_minutes)
        rescheduled_study_minutes += block.duration_minutes
        rescheduled_subjects.add(block.subject)
        cursor_minutes += block.duration_minutes + GAP_MINUTES

    db.commit()

    # ------------------------------------------------------------------
    # Rule 3 — Subject rotation
    # ------------------------------------------------------------------
    last_block = (
        db.query(StudyBlock)
        .filter(StudyBlock.user_id == user_id)
        .order_by(StudyBlock.date.desc(), StudyBlock.start_time.desc())
        .first()
    )

    if last_block and last_block.subject in day_rotation:
        start_index = (day_rotation.index(last_block.subject) + 1) % len(day_rotation)
    else:
        start_index = 0

    # Signals already extracted for Rule 0

    # ------------------------------------------------------------------
    # Rule 3B — Weak subject priority
    # ------------------------------------------------------------------
    # Insert the highest-miss weak subject as the first new block,
    # if it is not already scheduled via rescheduled blocks.
    weak_subject_block = None

    if signals.weak_subjects:
        # Pick the weak subject with the highest miss_count.
        # Tie-break: earliest in SUBJECTS list.
        weak_sigs = [
            s for s in signals.subject_signals
            if s.is_weak and s.subject not in rescheduled_subjects
        ]
        if weak_sigs:
            weak_sigs.sort(key=lambda s: (-s.miss_count, SUBJECTS.index(s.subject)))
            chosen = weak_sigs[0]

            # Decide start time: use preferred_slots[0] if valid
            chosen_start = cursor_minutes
            if chosen.preferred_slots:
                pref = _time_to_minutes(chosen.preferred_slots[0])
                if pref >= cursor_minutes and pref + BLOCK_DURATION <= DAY_END:
                    chosen_start = pref

            if chosen_start + BLOCK_DURATION <= DAY_END:
                weak_subject_block = StudyBlock(
                    user_id=user_id,
                    subject=chosen.subject,
                    topic="Weak Subject Focus",
                    date=target_date,
                    start_time=_minutes_to_time(chosen_start),
                    duration_minutes=BLOCK_DURATION,
                    status="pending",
                    completion_percent=0,
                )

    # ------------------------------------------------------------------
    # Rule 4 — Block generation (with Rule 3C slot avoidance)
    # ------------------------------------------------------------------
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        return []

    daily_hours = user.daily_study_hours or 6
    total_minutes = effective_minutes
    remaining_minutes = total_minutes - rescheduled_study_minutes

    new_blocks: List[StudyBlock] = []

    # Insert weak subject block first if it exists
    if weak_subject_block is not None and BLOCK_DURATION <= remaining_minutes:
        new_blocks.append(weak_subject_block)
        db.add(weak_subject_block)
        remaining_minutes -= BLOCK_DURATION
        cursor_minutes = _time_to_minutes(weak_subject_block.start_time) + BLOCK_DURATION + GAP_MINUTES

    rotation_index = start_index
    cumulative_new = sum(b.duration_minutes for b in new_blocks)

    while True:
        # Budget check
        if cumulative_new + BLOCK_DURATION > remaining_minutes:
            break
        # Time-of-day check
        if cursor_minutes + BLOCK_DURATION > DAY_END:
            break

        subject = day_rotation[rotation_index % len(day_rotation)]

        # Skip if this subject was already used as the weak-subject block
        if weak_subject_block and subject == weak_subject_block.subject:
            rotation_index += 1
            continue

        # Rule 3 enhancement — preferred slot adjustment
        block_start = cursor_minutes
        rec = signals.recommended_slot_adjustments.get(subject)
        if rec:
            rec_minutes = _time_to_minutes(rec)
            if rec_minutes >= cursor_minutes and rec_minutes + BLOCK_DURATION <= DAY_END:
                block_start = rec_minutes

        # Rule 3C — Slot avoidance
        avoidance = signals.avoidance_patterns.get(subject, [])
        adjustments = 0
        while _minutes_to_time(block_start) in avoidance and adjustments < 2:
            block_start += 60
            adjustments += 1

        # After avoidance adjustments, check we still fit
        if block_start + BLOCK_DURATION > DAY_END:
            # Drop this block entirely
            rotation_index += 1
            continue

        new_block = StudyBlock(
            user_id=user_id,
            subject=subject,
            topic="General Revision",
            date=target_date,
            start_time=_minutes_to_time(block_start),
            duration_minutes=BLOCK_DURATION,
            status="pending",
            completion_percent=0,
        )
        new_blocks.append(new_block)
        db.add(new_block)

        cumulative_new += BLOCK_DURATION
        cursor_minutes = block_start + BLOCK_DURATION + GAP_MINUTES
        rotation_index += 1

    # ------------------------------------------------------------------
    # Rule 5 — Commit and return
    # ------------------------------------------------------------------
    db.commit()

    # Refresh all new blocks to get their IDs
    for b in new_blocks:
        db.refresh(b)

    # Return full day: rescheduled (already committed) + new, sorted
    all_blocks = (
        db.query(StudyBlock)
        .filter(StudyBlock.user_id == user_id, StudyBlock.date == target_date)
        .order_by(StudyBlock.start_time)
        .all()
    )
    return all_blocks
