from sqlalchemy import Column, Integer, String, DateTime, Date, ForeignKey, Float
from datetime import datetime
from .database import Base

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, autoincrement=True)
    name = Column(String, nullable=False)
    email = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    exam_date = Column(Date, nullable=True)
    daily_study_hours = Column(Integer, default=6)
    created_at = Column(DateTime, default=datetime.utcnow)
    refresh_token = Column(String, nullable=True)

    # Phase 7: Behavioral & Onboarding State
    goal_type = Column(String, nullable=True)
    target_year = Column(Integer, nullable=True)
    months_remaining = Column(Integer, nullable=True)
    current_level = Column(String, nullable=True)
    
    preferred_study_slots = Column(String, nullable=True) # JSON array of slots
    wake_time = Column(String, nullable=True)
    sleep_time = Column(String, nullable=True)
    
    focus_level = Column(String, nullable=True)
    distraction_level = Column(String, nullable=True)
    peak_focus_time = Column(String, nullable=True)
    primary_problem = Column(String, nullable=True)
    biggest_problems = Column(String, nullable=True) # JSON array (Legacy)
    
    session_length = Column(Integer, default=90)
    study_style = Column(String, nullable=True)
    revision_preference = Column(String, nullable=True)
    
    weak_subjects = Column(String, nullable=True) # JSON array
    strong_subjects = Column(String, nullable=True) # JSON array
    covered_subjects = Column(String, nullable=True) # JSON array
    difficulty_preference = Column(String, nullable=True) # light / medium / heavy
    current_affairs_weight = Column(Integer, default=20) # 0-100
    # Phase 4: Gamification & Experience
    xp = Column(Integer, default=0)
    streak_days = Column(Integer, default=0)
    consistency_score = Column(Float, default=0.0)


class StudyBlock(Base):
    __tablename__ = "study_blocks"

    id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    subject = Column(String, nullable=False)
    topic = Column(String, nullable=True)
    date = Column(Date, nullable=False)
    start_time = Column(String, nullable=False)
    duration_minutes = Column(Integer, nullable=False)
    status = Column(String, default="pending")
    completion_percent = Column(Integer, default=0)
    time_spent_minutes = Column(Integer, default=0)
    rescheduled_from_id = Column(Integer, ForeignKey("study_blocks.id"), nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)


class DailyReport(Base):
    __tablename__ = "daily_reports"

    id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    date = Column(Date, nullable=False)
    submitted_at = Column(DateTime, default=datetime.utcnow)
    blocks_completed = Column(Integer, default=0)
    blocks_partial = Column(Integer, default=0)
    blocks_missed = Column(Integer, default=0)
    notes = Column(String, nullable=True)

class NewsArticle(Base):
    __tablename__ = "news_articles"

    id = Column(Integer, primary_key=True, autoincrement=True)
    title = Column(String, nullable=False)
    content = Column(String, nullable=False)
    source = Column(String, nullable=False)
    date = Column(Date, default=datetime.utcnow().date())
    category = Column(String, nullable=False)
    image_url = Column(String, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)

class Folder(Base):
    __tablename__ = "folders"

    id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    name = Column(String, nullable=False)
    description = Column(String, nullable=True)
    icon = Column(String, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)

class KnowledgeAsset(Base):
    __tablename__ = "knowledge_assets"

    id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    folder_id = Column(Integer, ForeignKey("folders.id"), nullable=True)
    title = Column(String, nullable=False)
    asset_type = Column(String, nullable=False) # e.g. "pdf", "note"
    status = Column(String, default="Processing") # "Analyzed", "Processing"
    meta_info = Column(String, nullable=True) # e.g. "POLITY • 4 PDFS"
    content_url = Column(String, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
