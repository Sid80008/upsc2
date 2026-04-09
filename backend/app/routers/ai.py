from fastapi import APIRouter, Depends
from app.schemas import AIQueryRequest, AIQueryResponse
from app.core.deps import get_current_user
from app.db.models import User

router = APIRouter()

@router.post("/query", response_model=AIQueryResponse)
def query_ai_buddy(request: AIQueryRequest, current_user: User = Depends(get_current_user)):
    # Real logic would call Gemini/OpenAI here.
    # We'll implement a fallback-first pattern for stability.
    
    query = request.query.lower()
    
    # Greetings & General Conversation
    if any(greet in query for greet in ["hi", "hello", "hey", "hola"]):
        return AIQueryResponse(response="Hello! I'm your Aspirant Buddy. How can I help you architect your success today?")
    elif "how are you" in query:
        return AIQueryResponse(response="I'm fully operational and monitoring your progress! Ready to dive into your next study block?")
    elif any(who in query for who in ["who are you", "what are you"]):
        return AIQueryResponse(response="I am the Aspirant Buddy, your dedicated AI architect for UPSC preparation. I analyze your focus, retention, and schedule to ensure peak performance.")
    
    # Simple keyword-based logic for demo/fallback
    if "motivation" in query:
        return AIQueryResponse(response="Success is not final, failure is not fatal: it is the courage to continue that counts. Keep pushing!")
    elif any(kw in query for kw in ["schedule", "plan", "time"]):
        return AIQueryResponse(response="Your session is synchronized with your peak circadian rhythm. Stick to the current focus area for 100% efficiency.")
    elif "revision" in query:
        return AIQueryResponse(response="I've flagged high-yield topics for your Sunday revision cycle. Don't skip the consolidation phase!")
    
    # Default Fallback
    return AIQueryResponse(
        response="Interesting point. While I process that through my analytical engine, I recommend focusing on your active subject to maintain your streak.",
        is_fallback=True
    )
