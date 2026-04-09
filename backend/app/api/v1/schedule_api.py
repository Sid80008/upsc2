from fastapi import APIRouter


router = APIRouter()


@router.get("/daily-schedule")
async def get_daily_schedule() -> dict:
    """
    Retrieve the user's daily study schedule.

    This is a placeholder endpoint that currently returns an
    empty structure. It will later be backed by the study
    scheduling engine.
    """
    return {"subjects": [], "blocks": []}


@router.post("/adjust-backlog")
async def adjust_backlog(payload: dict) -> dict:
    """
    Request adjustment of backlog tasks.

    In the future this will:
    - Accept structured data about missed tasks and backlog.
    - Invoke the StudyScheduler to redistribute work.
    """
    return {
        "status": "pending",
        "detail": "Backlog adjustment placeholder.",
        "received": payload,
    }


@router.get("/weak-subjects")
async def get_weak_subjects() -> dict:
    """
    Retrieve a list of weak subjects for the user.

    This placeholder currently returns an empty list. It will
    later be powered by analytics and AI hooks.
    """
    return {"weak_subjects": []}

