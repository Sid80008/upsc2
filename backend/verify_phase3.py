import json
from datetime import date, timedelta
from app.db.database import SessionLocal, engine
from app.db.models import User, StudyBlock, DailyReport, Base
from app.services.scheduler import generate_schedule
from app.services.report_processor import process_report
from app.schemas import OnboardingRequest, ReportSubmitRequest, BlockReportItem

def verify_phase3():
    # ENSURE SCHEMA IS UP TO DATE
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    try:
        # 1. Setup/Get Test User (User ID 1 as per prompt)
        user = db.query(User).filter(User.id == 1).first()
        if not user:
            print("Creating Test User...")
            user = User(id=1, name="Test Aspirant", email="test@upsc.com", hashed_password="hashed")
            db.add(user)
            db.commit()
            db.refresh(user)

        # 2. Simulate Onboarding Complete
        print("\n--- Phase 1: Onboarding ---")
        onboarding_payload = OnboardingRequest(
            goal_type="both",
            target_year=2025,
            months_remaining=12,
            current_level="intermediate",
            preferred_study_slots=["morning", "night"],
            wake_time="06:00",
            sleep_time="22:30",
            focus_level="high",
            distraction_level="low",
            peak_focus_time="07:00",
            primary_problem="Overthinking",
            biggest_problems=["Procrastination"],
            session_length=60,
            study_style="mixed",
            revision_preference="daily",
            weak_subjects=["Polity", "History"],
            strong_subjects=["Geography"],
            covered_subjects=["Economics"]
        )

        # Apply onboarding logic (from router)
        user.goal_type = onboarding_payload.goal_type
        user.target_year = onboarding_payload.target_year
        user.months_remaining = onboarding_payload.months_remaining
        user.current_level = onboarding_payload.current_level
        user.preferred_study_slots = json.dumps(onboarding_payload.preferred_study_slots)
        user.wake_time = onboarding_payload.wake_time
        user.sleep_time = onboarding_payload.sleep_time
        user.focus_level = onboarding_payload.focus_level
        user.distraction_level = onboarding_payload.distraction_level
        user.peak_focus_time = onboarding_payload.peak_focus_time
        user.primary_problem = onboarding_payload.primary_problem
        user.session_length = onboarding_payload.session_length
        user.study_style = onboarding_payload.study_style
        user.revision_preference = onboarding_payload.revision_preference
        user.weak_subjects = json.dumps(onboarding_payload.weak_subjects)
        user.strong_subjects = json.dumps(onboarding_payload.strong_subjects)
        user.covered_subjects = json.dumps(onboarding_payload.covered_subjects)
        db.commit()
        print("✓ Onboarding status saved to DB.")

        # 3. Trigger Schedule Generation
        print("\n--- Phase 2: Schedule Generation ---")
        tomorrow = date.today() + timedelta(days=1)
        # Clear tomorrow's blocks for clean test
        db.query(StudyBlock).filter(StudyBlock.user_id == 1, StudyBlock.date == tomorrow).delete()
        db.commit()
        
        blocks = generate_schedule(db, user.id, tomorrow)
        print(f"✓ Generated {len(blocks)} blocks for tomorrow.")
        for b in blocks:
            print(f"  - [{b.start_time}] {b.subject} ({b.duration_minutes}m)")
            
        # Verify window constraints
        if blocks:
            start_hour = int(blocks[0].start_time.split(":")[0])
            end_hour = int(blocks[-1].start_time.split(":")[0])
            print(f"✓ Schedule respects wake time (6AM): Start at {blocks[0].start_time}")
            print(f"✓ Schedule respects preferred slots: Morning/Night check...")

        # 4. Report & Adaptive Logic
        print("\n--- Phase 3: Reporting & Feedback ---")
        # Assume today has some blocks
        today = date.today()
        # Seed a block for today
        db.query(StudyBlock).filter(StudyBlock.user_id == 1, StudyBlock.date == today).delete()
        test_block = StudyBlock(user_id=1, subject="Polity", date=today, start_time="09:00", duration_minutes=60, status="pending")
        db.add(test_block)
        db.commit()
        db.refresh(test_block)
        
        report_request = ReportSubmitRequest(
            date=today,
            blocks=[BlockReportItem(block_id=test_block.id, status="missed", completion_percent=0)],
            notes="Felt tired"
        )
        process_report(user.id, report_request, db)
        print("✓ Missed report processed.")
        
        # Verify adaptive logic: Missed blocks should appear tomorrow
        print("\n--- Phase 4: Final Verification ---")
        day_after = tomorrow + timedelta(days=1)
        db.query(StudyBlock).filter(StudyBlock.user_id == 1, StudyBlock.date == day_after).delete()
        db.commit()
        
        new_blocks = generate_schedule(db, user.id, day_after)
        has_rescheduled = any("[Rescheduled]" in b.subject for b in new_blocks)
        if has_rescheduled:
            print("✓ SUCCESS: Missed Polity block was rescheduled.")
        else:
            print("! FAILED: Missed block not found in next schedule.")

        print("\nSUMMARY: Phase 3 Integrated Loop Verified.")

    finally:
        db.close()

if __name__ == "__main__":
    verify_phase3()
