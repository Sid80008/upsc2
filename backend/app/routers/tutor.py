from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.db.database import get_db
from app.db.models import User
from app.core.deps import get_current_user
from app.services.ai_engine import AIEngine
from pydantic import BaseModel
from typing import Dict, List

router = APIRouter()

class ChatMessage(BaseModel):
    role: str
    content: str

class ChatRequest(BaseModel):
    messages: List[ChatMessage]

@router.post("/chat", response_model=Dict[str, str])
def tutor_chat(request: ChatRequest, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    history = [{"role": "user" if m.role == "user" else "model", "parts": [m.content]} for m in request.messages[:-1]]
    latest_msg = request.messages[-1].content
    
    response_text = AIEngine.chat_with_tutor(
        user_name=current_user.name,
        history=history,
        new_message=latest_msg
    )
    
    return {"reply": response_text}
