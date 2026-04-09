from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base, sessionmaker
from app.core.config import settings

SQLALCHEMY_DATABASE_URL = settings.database_url

connect_args = {}
engine_kwargs = {
    "pool_pre_ping": True,  # Detect stale connections
}

if "sqlite" in settings.database_url:
    connect_args = {"check_same_thread": False}
else:
    # Postgres (Supabase) — add connection timeout
    connect_args = {"connect_timeout": 10}
    engine_kwargs["pool_size"] = 5
    engine_kwargs["max_overflow"] = 10
    engine_kwargs["pool_timeout"] = 15

engine = create_engine(
    settings.database_url,
    connect_args=connect_args,
    **engine_kwargs
)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
