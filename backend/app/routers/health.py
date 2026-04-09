from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import text
from app.db.database import get_db
import time

router = APIRouter()

@router.get("/detailed")
async def health_detailed(db: Session = Depends(get_db)):
    start_time = time.time()
    try:
        # Check database connection
        db.execute(text("SELECT 1"))
        db_status = "healthy"
    except Exception as e:
        db_status = f"unhealthy: {str(e)}"
    
    latency = f"{(time.time() - start_time):.3f}s"
    
    return {
        "status": "online",
        "version": "1.0.0",
        "database": db_status,
        "latency": latency,
        "timestamp": time.time()
    }
