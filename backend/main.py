from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from datetime import date, timedelta

from app.db.database import engine, SessionLocal
from app.db.models import Base, User
from app.routers import (
    schedule, report, auth, onboarding,
    insights, library, news, health
)
from app.core.security import get_password_hash
import logging
from app.core.config import settings

logger = logging.getLogger("upsc_app")


def seed_default_user():
    """
    Seeds a default user if none exist. 
    In production, skips seeding if SEED_USER_PASSWORD is not set.
    """
    if settings.environment == "production" and not settings.seed_user_password:
        return

    db = SessionLocal()
    try:
        user_count = db.query(User).count()
        if user_count == 0:
            # Use environment variable for seed password
            password = settings.seed_user_password
            if not password:
                # If no password is provided even in dev, we skip seeding to avoid hardcoded defaults
                return
            exam_dt = date.today() + timedelta(days=180) # 6 months
            seed_user = User(
                name="Aspirant",
                email="test@upsc.com",
                hashed_password=get_password_hash(password),
                daily_study_hours=6,
                exam_date=exam_dt
            )
            db.add(seed_user)
            db.commit()
    finally:
        db.close()

from app.core.logging import LoggingMiddleware

app = FastAPI(title="UPSC Preparation System Phase 2")

# Add structured logging middleware
app.add_middleware(LoggingMiddleware)

app.add_middleware(
    CORSMiddleware,
    allow_origins=[o.strip() for o in settings.allowed_origins.split(",")],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.on_event("startup")
def on_startup():
    logger.info("Application starting up...")
    try:
        seed_default_user()
        logger.info("Default user seeding check completed.")
    except Exception as e:
        logger.error(f"Startup seeding failed: {e}", exc_info=True)

app.include_router(health.router, prefix="/health", tags=["Health"])
app.include_router(auth.router, prefix="/auth", tags=["Authentication"])
app.include_router(onboarding.router, prefix="/onboarding", tags=["Onboarding"])
app.include_router(schedule.router, prefix="/schedule", tags=["Schedule"])
app.include_router(report.router, prefix="/report", tags=["Report"])
app.include_router(insights.router, prefix="/insights", tags=["Insights"])
# app.include_router(insights_advanced.router, prefix="/insights/advanced", tags=["Advanced Insights"])  # Phase 2: disabled
# app.include_router(tutor.router, prefix="/tutor", tags=["Tutor"])                     # Phase 2: disabled
# app.include_router(dashboard.router, prefix="/dashboard", tags=["Dashboard"])          # Phase 2: disabled
# app.include_router(recovery.router, prefix="/recovery", tags=["Recovery"])             # Phase 2: disabled
app.include_router(library.router, prefix="/library", tags=["Library"])
# app.include_router(ai.router, prefix="/ai", tags=["AI"])                              # Phase 2: disabled
app.include_router(news.router, prefix="/news", tags=["News"])

@app.get("/health")

def health_check():
    return {"status": "ok"}
