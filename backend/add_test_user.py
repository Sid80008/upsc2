import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from app.db.database import SessionLocal
from app.db.models import User
from app.core.security import get_password_hash
from datetime import date, timedelta

db = SessionLocal()
existing = db.query(User).filter(User.email == "user@mail.com").first()
if not existing:
    test_user = User(
        name="Test User",
        email="user@mail.com",
        hashed_password=get_password_hash("user"),
        daily_study_hours=6,
        exam_date=date.today() + timedelta(days=180)
    )
    db.add(test_user)
    db.commit()
    print("Test user created successfully.")
else:
    # Update password if user already exists
    existing.hashed_password = get_password_hash("user")
    db.commit()
    print("User already exists, password updated.")
db.close()
