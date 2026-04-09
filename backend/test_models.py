import os
import google.generativeai as genai
from app.core.config import settings

api_key = os.environ.get("GEMINI_API_KEY") or settings.gemini_api_key
genai.configure(api_key=api_key)

print("Listing supported models:")
for m in genai.list_models():
    if 'generateContent' in m.supported_generation_methods:
        print(m.name)
