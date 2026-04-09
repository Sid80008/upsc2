import logging
import json
import time
from datetime import datetime
from fastapi import Request
from starlette.middleware.base import BaseHTTPMiddleware

class JSONFormatter(logging.Formatter):
    def format(self, record):
        log_record = {
            "timestamp": datetime.utcnow().isoformat(),
            "level": record.levelname,
            "message": record.getMessage(),
            "module": record.module,
            "funcName": record.funcName,
        }
        if hasattr(record, "request_id"):
            log_record["request_id"] = record.request_id
        if record.exc_info:
            log_record["exception"] = self.formatException(record.exc_info)
        return json.dumps(log_record)

def setup_logging():
    logger = logging.getLogger("upsc_app")
    logger.setLevel(logging.INFO)
    
    handler = logging.StreamHandler()
    handler.setFormatter(JSONFormatter())
    logger.addHandler(handler)
    return logger

logger = setup_logging()

class LoggingMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        start_time = time.time()
        response = await call_next(request)
        process_time = time.time() - start_time
        
        log_data = {
            "method": request.method,
            "path": request.url.path,
            "status_code": response.statusCode if hasattr(response, "statusCode") else response.status_code,
            "duration": f"{process_time:.4f}s",
            "client_ip": request.client.host if request.client else "unknown"
        }
        
        logger.info(f"Request handled: {json.dumps(log_data)}")
        return response
