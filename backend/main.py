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


def seed_default_user():
    # Migrations are run manually via: alembic upgrade head
    # Do not auto-migrate here. Use run_migrations.py for production startup.
    db = SessionLocal()
    try:
        user_count = db.query(User).count()
        if user_count == 0:
            exam_dt = date.today() + timedelta(days=180) # 6 months
            seed_user = User(
                name="Aspirant",
                email="test@upsc.com",
                hashed_password=get_password_hash("password123"),
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
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.on_event("startup")
def on_startup():
    seed_default_user()

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
