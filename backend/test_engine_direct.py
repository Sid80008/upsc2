import os
import sys

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
from app.services.ai_engine import AIEngine

try:
    print("Testing AI Tutor Direct...")
    history = [{"role": "user", "parts": ["How do I clear UPSC?"]}]
    reply = AIEngine.chat_with_tutor(
        user_name="Student",
        history=history,
        new_message="Please help me with Modern History."
    )
    print("Success:", reply)
except Exception as e:
    import traceback
    traceback.print_exc()
