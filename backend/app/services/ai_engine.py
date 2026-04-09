"""
AI Engine
==========
Gemini-powered schedule generation with deterministic fallback.
When USE_AI_SCHEDULER = True, Gemini generates context-aware schedules.
When False, or on any failure, the rule-based scheduler handles it.

Loop position: Decision Engine (swappable)
"""

import os
import json
import re
import logging
from datetime import date, timedelta
from typing import List, Dict, Any, Optional
from sqlalchemy.orm import Session

from groq import Groq
from app.core.config import settings
from app.db.models import StudyBlock, User
from app.services.rule_based_scheduler import (
    SUBJECTS, _time_to_minutes, _minutes_to_time,
)
from app.services import exam_countdown


logger = logging.getLogger("ai_engine")

# ---------------------------------------------------------------------------
# Flag — imported by orchestrator.py
# ---------------------------------------------------------------------------
USE_AI_SCHEDULER = settings.use_ai_scheduler

try:
    client = Groq(api_key=settings.groq_api_key)
except Exception as e:
    logger.warning("Failed to initialize Groq client")
    client = None


# ═══════════════════════════════════════════════════════════════════════════
# Main entry — called by Orchestrator.get_schedule when flag is True
# ═══════════════════════════════════════════════════════════════════════════

def generate_schedule(user_id: int, target_date: date, db: Session) -> List[StudyBlock]:
    """
    AI-powered schedule generation with guaranteed fallback.
    Always returns a valid list of StudyBlocks (possibly empty on catastrophic failure).
    """

    # Step 1 — Idempotency
    existing = (
        db.query(StudyBlock)
        .filter(StudyBlock.user_id == user_id, StudyBlock.date == target_date)
        .order_by(StudyBlock.start_time)
        .all()
    )
    if existing:
        return existing

    # Step 2 — Gather context
    try:
        user = db.query(User).filter(User.id == user_id).first()
        if not user:
            return _ai_schedule_with_fallback(user_id, target_date, db, "user not found")

        from app.services.signal_extractor import extract_signals
        signals = extract_signals(user_id, db)

        lookback = target_date - timedelta(days=7)
        recent_blocks = (
            db.query(StudyBlock)
            .filter(StudyBlock.user_id == user_id, StudyBlock.date >= lookback)
            .order_by(StudyBlock.date.desc(), StudyBlock.start_time.desc())
            .all()
        )

        pending_rescheduled = (
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
    except Exception as e:
        return _ai_schedule_with_fallback(user_id, target_date, db, f"context fetch error: {e}")

    # Step 3 — Build prompt
    countdown = exam_countdown.compute_countdown_state(user, signals)
    prompt = _build_schedule_prompt(user, signals, recent_blocks, pending_rescheduled, target_date, countdown)

    # Step 4 — Call Gemini with timeout + retry
    raw_text = None
    retries = settings.max_ai_retries + 1  # 1 initial + 1 retry
    last_error = ""

    for attempt in range(retries):
        try:
            if not settings.groq_api_key:
                return _ai_schedule_with_fallback(user_id, target_date, db, "no API key")

            response = client.chat.completions.create(
                model="llama-3.1-8b-instant",
                messages=[
                    {"role": "system", "content": "You are a UPSC study scheduler. Return only valid JSON arrays. No other text."},
                    {"role": "user", "content": prompt}
                ],
                temperature=0.3,
                max_tokens=1000,
                timeout=settings.gemini_timeout_seconds
            )
            raw_text = response.choices[0].message.content.strip()
            logger.info(f"Groq responded for user={user_id} date={target_date} (attempt {attempt+1})")
            break
        except Exception as e:
            last_error = str(e)
            logger.warning(f"Groq attempt {attempt+1} failed: {e}")

    if raw_text is None:
        return _ai_schedule_with_fallback(user_id, target_date, db, f"Groq failed after {retries} attempts: {last_error}")

    # Step 5 — Parse and validate
    validated = _validate_ai_response(raw_text, user, target_date)
    if validated is None:
        return _ai_schedule_with_fallback(user_id, target_date, db, f"validation failed, raw={raw_text[:200]}")

    # Step 6 — Write to DB
    try:
        # Handle rescheduled blocks first — update their date
        DAY_START = _time_to_minutes(user.wake_time or "07:00")
        GAP = 10
        cursor = DAY_START

        for block in pending_rescheduled:
            block.date = target_date
            block.start_time = _minutes_to_time(cursor)
            cursor += block.duration_minutes + GAP
        db.commit()

        # Insert AI-generated blocks
        new_blocks: List[StudyBlock] = []
        for item in validated:
            topic_raw = item.get("topic", "") or ""
            topic = topic_raw[:120] if topic_raw else f"{item['subject']} — General Study"

            new_block = StudyBlock(
                user_id=user_id,
                subject=item["subject"],
                topic=topic,
                date=target_date,
                start_time=item["start_time"],
                duration_minutes=item["duration_minutes"],
                status="pending",
                completion_percent=0,
                rescheduled_from_id=item.get("rescheduled_from_id"),
            )
            new_blocks.append(new_block)
            db.add(new_block)

        db.commit()
        for b in new_blocks:
            db.refresh(b)

    except Exception as e:
        db.rollback()
        return _ai_schedule_with_fallback(user_id, target_date, db, f"DB write error: {e}")

    # Step 7 — Return full block list
    all_blocks = (
        db.query(StudyBlock)
        .filter(StudyBlock.user_id == user_id, StudyBlock.date == target_date)
        .order_by(StudyBlock.start_time)
        .all()
    )
    return all_blocks


# ═══════════════════════════════════════════════════════════════════════════
# Prompt builder
# ═══════════════════════════════════════════════════════════════════════════

def _build_schedule_prompt(user, signals, recent_blocks, pending_rescheduled, target_date, countdown) -> str:
    """Deterministic prompt — same inputs always produce same prompt string."""

    # Recent history summary
    if recent_blocks:
        total = len(recent_blocks)
        completed = sum(1 for b in recent_blocks if b.status == "completed")
        partial = sum(1 for b in recent_blocks if b.status == "partial")
        missed = sum(1 for b in recent_blocks if b.status == "missed")

        # Most missed subject
        missed_subjects = [b.subject for b in recent_blocks if b.status == "missed"]
        top_missed = max(set(missed_subjects), key=missed_subjects.count) if missed_subjects else "None"

        # Most consistent subject
        completed_subjects = [b.subject for b in recent_blocks if b.status == "completed"]
        most_consistent = max(set(completed_subjects), key=completed_subjects.count) if completed_subjects else "None"

        recent_summary = (
            f"Last 7 days: {total} blocks — {completed} completed, "
            f"{partial} partial, {missed} missed.\n"
            f"Most missed: {top_missed}. Best streak subject: {most_consistent}."
        )
    else:
        recent_summary = "No study history in last 7 days."

    # Rescheduled block summary
    if pending_rescheduled:
        resched_lines = []
        for i, b in enumerate(pending_rescheduled, 1):
            resched_lines.append(f"Block {i}: {b.subject} (originally missed on {b.date})")
        resched_summary = "\n".join(resched_lines)
    else:
        resched_summary = "None"

    wake = user.wake_time or "07:00"
    sleep = user.sleep_time or "23:00"
    session_len = user.session_length or 90

    return f"""You are a UPSC study scheduler. Generate a daily study schedule as a JSON array.

STUDENT PROFILE:
- Daily study hours: {user.daily_study_hours}
- Exam date: {user.exam_date}
- Weak subjects: {signals.weak_subjects}
- Strong subjects: {user.strong_subjects}
- Preferred study slots: {user.preferred_study_slots}
- Wake time: {wake} | Sleep time: {sleep}
- Peak focus time: {user.peak_focus_time}
- Distraction level: {user.distraction_level}
- Session length preference: {session_len} minutes
- Study style: {user.study_style}

BEHAVIORAL SIGNALS (last 14 days):
- Consistency score: {signals.consistency_score}
- Avoidance patterns: {json.dumps(signals.avoidance_patterns)}
- Recommended slot adjustments: {json.dumps(signals.recommended_slot_adjustments)}

EXAM COUNTDOWN:
- Days remaining: {countdown.days_remaining}
- Mode: {countdown.mode}
- Revision weight: {countdown.revision_weight}
- Subject priorities: {countdown.subject_priorities}
- Intensity: {countdown.schedule_intensity}

RECENT HISTORY (last 7 days summary):
{recent_summary}

RESCHEDULED BLOCKS (must appear first, in this order):
{resched_summary}

SCHEDULING RULES — FOLLOW EXACTLY:
1. You MUST generate EXACTLY { (user.daily_study_hours * 60) // session_len } blocks so that the total time is EXACTLY {user.daily_study_hours * 60} minutes. Do not generate more blocks than this.
2. Each block is {session_len} minutes (min 45, max 120).
3. Gap between blocks: 10 minutes minimum. (i.e. The start_time of the next block MUST be at least 10 minutes after the start_time + duration_minutes of the previous block).
4. Schedule must start at or after {wake}. Must end before {sleep}.
5. Do not schedule any subject at times listed in avoidance_patterns for that subject.
6. Place weak subjects during peak_focus_time window when possible.
7. Rescheduled blocks must appear first in the schedule, at their assigned times.
8. Use only these subjects: History, Geography, Polity, Economy, Environment, Current Affairs, Essay.
9. Do not repeat the same subject more than twice in one day.

DATE: {target_date}

RESPOND WITH ONLY A JSON ARRAY. NO OTHER TEXT. Format:
[
  {{"subject": "History", "start_time": "07:00", "duration_minutes": {session_len}, "topic": "Ancient India — Indus Valley Civilization", "rescheduled_from_id": null}}
]"""


# ═══════════════════════════════════════════════════════════════════════════
# Response validation (Step 3)
# ═══════════════════════════════════════════════════════════════════════════

def _validate_ai_response(raw_json: str, user, target_date) -> Optional[List[dict]]:
    """
    Validate Gemini's response against 10 rules.
    Returns parsed list on success, None on any failure (triggers fallback).
    """

    # Clean markdown fences if present
    text = raw_json
    if "```json" in text:
        text = text.split("```json")[1].split("```")[0].strip()
    elif "```" in text:
        text = text.split("```")[1].split("```")[0].strip()

    # Rule 1 — Must parse as valid JSON array
    try:
        data = json.loads(text)
    except json.JSONDecodeError as e:
        logger.warning(f"Validation rule 1 fail (JSON parse): {e}")
        return None

    if not isinstance(data, list):
        logger.warning("Validation rule 1 fail: not a list")
        return None

    # Rule 2 — Array must not be empty
    if len(data) == 0:
        logger.warning("Validation rule 2 fail: empty array")
        return None

    # Rule 10 — Array length between 1 and 12
    if len(data) > 12:
        logger.warning(f"Validation rule 10 fail: {len(data)} items")
        return None

    wake = user.wake_time or "07:00"
    wake_min = _time_to_minutes(wake)
    total_study = 0

    for i, item in enumerate(data):
        # Rule 3 — Required fields
        if not all(k in item for k in ("subject", "start_time", "duration_minutes")):
            logger.warning(f"Validation rule 3 fail: missing fields in item {i}")
            return None

        # Rule 4 — Valid subject
        if item["subject"] not in SUBJECTS:
            logger.warning(f"Validation rule 4 fail: invalid subject '{item['subject']}'")
            return None

        # Rule 5 — start_time format HH:MM
        if not re.match(r"^\d{2}:\d{2}$", str(item["start_time"])):
            logger.warning(f"Validation rule 5 fail: bad time format '{item['start_time']}'")
            return None

        # Rule 6 — duration between 45 and 120
        try:
            dur = int(item["duration_minutes"])
            item["duration_minutes"] = dur
        except (ValueError, TypeError):
            logger.warning(f"Validation rule 6 fail: bad duration '{item['duration_minutes']}'")
            return None
        if dur < 45 or dur > 120:
            logger.warning(f"Validation rule 6 fail: duration {dur} out of range")
            return None

        total_study += dur

        # Rule 8 — No block before wake_time
        block_start = _time_to_minutes(item["start_time"])
        if block_start < wake_min:
            logger.warning(f"Validation rule 8 fail: block at {item['start_time']} before wake {wake}")
            return None

        # Rule 9 — No block start after 21:00
        if block_start > _time_to_minutes("21:00"):
            logger.warning(f"Validation rule 9 fail: block at {item['start_time']} after 21:00")
            return None

    # Rule 7 — Total study minutes check (allow 30min tolerance)
    max_allowed = (user.daily_study_hours or 6) * 60 + 30
    if total_study > max_allowed:
        logger.warning(f"Validation rule 7 fail: total {total_study} > max {max_allowed}")
        return None

    logger.info(f"Validation passed: {len(data)} blocks, {total_study} minutes")
    return data


# ═══════════════════════════════════════════════════════════════════════════
# Fallback handler (Step 4)
# ═══════════════════════════════════════════════════════════════════════════

def _ai_schedule_with_fallback(user_id: int, target_date: date, db: Session, reason: str) -> List[StudyBlock]:
    """Silent fallback to rule-based scheduler. Never raises."""
    logger.warning(f"AI scheduler fallback triggered: {reason}")
    try:
        from app.services import rule_based_scheduler
        return rule_based_scheduler.generate(user_id, target_date, db)
    except Exception as e:
        logger.critical(f"CRITICAL: both AI and fallback scheduler failed for user {user_id} date {target_date}: {e}")
        return []


# ═══════════════════════════════════════════════════════════════════════════
# Legacy methods — kept for out-of-scope routers (Phase 2 disabled)
# ═══════════════════════════════════════════════════════════════════════════

class AIEngine:
    """Legacy class wrapper. Kept for backward compatibility with disabled routers."""

    @classmethod
    def analyze_performance(cls, completed_blocks: int, total_blocks: int, focus_rating: int) -> str:
        current_key = settings.gemini_api_key
        if not current_key:
            return "Keep pushing forward! Consistency is key."
        genai.configure(api_key=current_key)
        model = _get_model()
        prompt = f"""A UPSC aspirant completed {completed_blocks} out of {total_blocks} scheduled blocks.
Focus rating: {focus_rating}/5. Give 2-3 sentences of concise feedback."""
        try:
            response = model.generate_content(prompt)
            return response.text.strip()
        except Exception as e:
            logger.warning(f"Gemini API Error: {e}")
            return "Keep pushing forward! Consistency is key."

    @classmethod
    def generate_comprehensive_insights(cls, user_data: dict, completed_blocks: int, total_blocks: int) -> str:
        current_key = settings.gemini_api_key
        if not current_key:
            return "AI Insights currently unavailable."
        genai.configure(api_key=current_key)
        model = _get_model()
        prompt = f"""Analyze UPSC aspirant: {user_data.get('name','Aspirant')}.
Weak: {user_data.get('weak_subjects','Unknown')}. Target: {user_data.get('daily_study_hours',6)}h.
Completed {completed_blocks}/{total_blocks} blocks in last 7 days.
Write 3 paragraphs of mentor insight. Plain text only."""
        try:
            response = model.generate_content(prompt)
            return response.text.strip()
        except Exception as e:
            logger.warning(f"Gemini API Error: {e}")
            return "Unable to generate insights at this moment."

    @classmethod
    def chat_with_tutor(cls, user_name: str, history: list, new_message: str) -> str:
        current_key = settings.gemini_api_key
        if not current_key:
            return "AI Tutor is currently offline."
        genai.configure(api_key=current_key)
        model = _get_model()
        system = f"You are an expert UPSC mentor talking to {user_name}."
        try:
            chat = model.start_chat(history=history)
            response = chat.send_message(f"System: {system}\n\nStudent: {new_message}")
            return response.text.strip()
        except Exception as e:
            logger.warning(f"Gemini API Error: {e}")
            return "I am currently unable to answer. Please try again later."
