from fastapi import APIRouter


router = APIRouter()


@router.post("/submit-daily-report")
async def submit_daily_report(report: dict) -> dict:
    """
    Submit a daily study report.

    This placeholder endpoint simply echoes a success status.
    It will later validate and forward the report to the
    DailyReportProcessor.
    """
    return {
        "status": "pending",
        "detail": "Daily report submission placeholder.",
        "received": report,
    }


@router.get("/report-history")
async def get_report_history() -> dict:
    """
    Retrieve the user's historical daily reports.

    This placeholder currently returns an empty list. In a
    future version it will query persisted reports and return
    a structured history.
    """
    return {"reports": []}

