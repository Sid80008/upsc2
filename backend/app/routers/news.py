from fastapi import APIRouter, Depends
import httpx
from sqlalchemy.orm import Session
from typing import List
from datetime import date
from app.db.database import get_db
from app.db.models import NewsArticle
from app.schemas import NewsOut

from app.core.config import settings

router = APIRouter()

@router.get("/daily", response_model=List[NewsOut])
async def get_daily_news(db: Session = Depends(get_db)):
    # Fetch real news using settings
    if not settings.news_api_key:
        # Fallback to DB if no API key
        return await _get_fallback_news(db)
    
    try:
        async with httpx.AsyncClient() as client:
            # NewsData.io endpoint for UPSC/India related news
            url = f"https://newsdata.io/api/1/latest?apikey={settings.news_api_key}&country=in&language=en"
            response = await client.get(url)
            if response.status_code == 200:
                data = response.json()
                articles = data.get("results", [])
                
                # Transform to our schema
                results = []
                for i, a in enumerate(articles[:10]):
                    results.append(NewsOut(
                        id=i + 1,
                        title=a.get("title", "No Title") or "No Title",
                        content=a.get("description") or a.get("content") or "No Content",
                        source=a.get("source_id", "Unknown") or "Unknown",
                        category="General",
                        date=date.today(),
                        image_url=a.get("image_url")
                    ))
                if results: return results
    except Exception as e:
        print(f"News API error: {e}")

    # Fallback to DB
    today = date.today()
    articles = db.query(NewsArticle).filter(NewsArticle.date == today).all()
    
    if not articles:
        # Fallback to most recent 5 articles if nothing for today
        articles = db.query(NewsArticle).order_by(NewsArticle.date.desc()).limit(5).all()
        
    return articles

@router.post("/seed")
def seed_news(db: Session = Depends(get_db)):
    # Helper to seed some data for testing
    if db.query(NewsArticle).count() > 0:
        return {"message": "Data already exists"}
        
    sample_news = [
        NewsArticle(
            title="Judicial Review of Electoral Bonds: Clarity in Transparency",
            content="The Constitution Bench resumes hearings on the validity of the Electoral Bond Scheme...",
            source="The Hindu",
            category="Polity",
            date=date.today()
        ),
        NewsArticle(
            title="Green Hydrogen: India's Strategic Pivot",
            content="Analyzing the National Green Hydrogen Mission and its role in decarbonizing hard-to-abate sectors.",
            source="Indian Express",
            category="Environment",
            date=date.today()
        )
    ]
    db.add_all(sample_news)
    db.commit()
    return {"message": "Seed successful"}
