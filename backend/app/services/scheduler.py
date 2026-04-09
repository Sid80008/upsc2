import json
import random
from datetime import date, datetime, timedelta
from typing import List
from sqlalchemy.orm import Session
from app.db.models import StudyBlock, User, DailyReport
from app.services.ai_engine import AIEngine

def parse_time(time_str: str, default: str) -> datetime:
    if not time_str:
        time_str = default
    try:
        if ":" in time_str:
            return datetime.strptime(time_str, "%H:%M")
        return datetime.strptime(default, "%H:%M")
    except Exception:
        return datetime.strptime(default, "%H:%M")

def get_json_list(json_str: str, default: List[str]) -> List[str]:
    if not json_str:
        return default
    try:
        data = json.loads(json_str)
        if isinstance(data, list) and len(data) > 0:
            return data
        return default
    except Exception:
        return default

def generate_schedule(db: Session, user_id: int, target_date: date) -> List[StudyBlock]:
    # 1. Check if StudyBlocks already exist
    existing_blocks = db.query(StudyBlock).filter(
        StudyBlock.user_id == user_id,
        StudyBlock.date == target_date
    ).all()
    if existing_blocks:
        return existing_blocks

    # 2. Fetch User
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        return []

    # 3. Parse boundaries
    wake_dt = parse_time(user.wake_time, "07:00")
    sleep_dt = parse_time(user.sleep_time, "23:00")
    
    daily_hours = user.daily_study_hours or 6
    session_length = user.session_length if user.session_length and user.session_length > 0 else 90
    
    total_minutes = int(daily_hours * 60)
    num_blocks = max(1, total_minutes // session_length)

    # 4. Parse subjects & weightings (50% weak, 30% normal, 20% strong)
    default_subs = ["General Studies"]
    weak = get_json_list(user.weak_subjects, [])
    strong = get_json_list(user.strong_subjects, [])
    covered = get_json_list(user.covered_subjects, default_subs)
    
    pool = []
    for _ in range(5):
        pool.extend(weak if weak else covered)
    for _ in range(3):
        pool.extend(covered)
    for _ in range(2):
        pool.extend(strong if strong else covered)
        
    random.shuffle(pool)

    # 5. Inject Revision Behavior
    is_revision_day = False
    if user.revision_preference == "daily":
        is_revision_day = True
    elif user.revision_preference == "weekly" and target_date.weekday() == 6:
        is_revision_day = True
    elif user.revision_preference == "alternate" and target_date.toordinal() % 2 == 0:
        is_revision_day = True

    blocks_to_create = []
    current_time_dt = wake_dt
    
    # 6. Missed/Partial Block Handling (Reschedule following deterministic logic)
    missed_blocks = db.query(StudyBlock).filter(
        StudyBlock.user_id == user_id,
        ((StudyBlock.status == "missed") | (StudyBlock.completion_percent < 50)),
        StudyBlock.date < target_date,
        StudyBlock.rescheduled_from_id == None
    ).order_by(StudyBlock.date.desc()).limit(2).all()
    
    used_subjects = []
    
    # 7. Generate Blocks Iteratively using AI feedback
    last_report = db.query(DailyReport).filter(
        DailyReport.user_id == user_id,
        DailyReport.date < target_date
    ).order_by(DailyReport.date.desc()).first()
    
    previous_feedback = "No previous feedback."
    if last_report:
        previous_feedback = f"Completed {last_report.blocks_completed}, partial {last_report.blocks_partial}, missed {last_report.blocks_missed}."
        if last_report.notes:
            previous_feedback += f" Notes: {last_report.notes}"
            
    unique_pool = list(set(pool))
    
    ai_generated_blocks = AIEngine.generate_schedule(
        user_id=user_id,
        subjects=unique_pool,
        daily_hours=daily_hours,
        session_length=session_length,
        previous_feedback=previous_feedback,
        exam_mode=user.goal_type
    )
    
    preferred_slots = get_json_list(user.preferred_study_slots, ["morning", "evening", "night"])
    
    def is_in_preferred_slot(dt: datetime) -> bool:
        hour = dt.hour
        if "morning" in preferred_slots and 6 <= hour < 12: return True
        if "evening" in preferred_slots and 12 <= hour < 18: return True
        if "night" in preferred_slots and 18 <= hour < 24: return True
        return False

    i = 0
    for block_data in ai_generated_blocks:
        if i >= num_blocks:
            break
            
        ai_duration = block_data.get("duration_minutes", session_length)

        # Prevent scheduling past sleep boundary
        if current_time_dt + timedelta(minutes=ai_duration) > sleep_dt:
            break
            
        # Respect preferred study slots
        attempts = 0
        while not is_in_preferred_slot(current_time_dt) and attempts < 48:
            current_time_dt += timedelta(minutes=15)
            attempts += 1
            if current_time_dt + timedelta(minutes=ai_duration) > sleep_dt:
                break
        
        if current_time_dt + timedelta(minutes=ai_duration) > sleep_dt:
            break

        subject_name = block_data.get("subject", "General Studies")
        topic = block_data.get("topic", "General Revision")
        
        # 8. PREFERENCE-DRIVEN INJECTION (System Hardening)
        # Injection Logic
        if is_revision_day and i == 0:
            subject_name = "Revision Cycle"
            topic = "Reflecting on previous week"
        elif i == 1 and (user.current_affairs_weight or 20) > 40:
            subject_name = "Current Affairs (Deep-Dive)"
            topic = "Recent News Analysis"
        elif missed_blocks:
            mb = missed_blocks.pop(0)
            subject_name = f"[Rescheduled] {mb.subject}"
            topic = mb.topic or "Recovery Topic"
            mb.rescheduled_from_id = -1 
            
        used_subjects.append(subject_name)
        
        # Adjust duration if "aggressive"
        actual_duration = ai_duration
        if user.study_style == "aggressive" and i > 1:
            actual_duration = max(45, ai_duration - 15)

        new_block = StudyBlock(
            user_id=user_id,
            subject=subject_name,
            topic=topic,
            date=target_date,
            start_time=current_time_dt.strftime("%H:%M"),
            duration_minutes=actual_duration,
            status="pending",
            completion_percent=0
        )
        blocks_to_create.append(new_block)
        db.add(new_block)
        
        # Add buffer break (Shorter if aggressive)
        break_min = 15 if user.study_style != "aggressive" else 10
        current_time_dt += timedelta(minutes=actual_duration + break_min)
        i += 1

    db.commit()
    for b in blocks_to_create:
        db.refresh(b)

    return blocks_to_create
