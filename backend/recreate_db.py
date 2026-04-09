import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from app.db.database import engine, Base
from app.db.models import User, StudyBlock, DailyReport

def recreate_database():
    print("Dropping all tables...")
    Base.metadata.drop_all(bind=engine)
    print("Creating all tables from current models...")
    Base.metadata.create_all(bind=engine)
    print("Database recreated successfully.")

if __name__ == "__main__":
    recreate_database()
