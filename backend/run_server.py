"""
Development-only entrypoint to run the UPSC FastAPI backend.

This script is intended for local use while developing the API.
It does not configure databases, authentication, or production
deployment settings.
"""

import uvicorn

from main import app


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)

