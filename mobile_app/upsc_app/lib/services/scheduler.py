from datetime import datetime, timedelta
from backend.app.models.study_block import StudyBlock
from backend.app.models.subject import Subject
from backend.app.models.study_plan import StudyPlan
from backend.app.models.schedule_response import DailySchedule, ScheduleResponse

class StudyScheduler:
    def generate_daily_schedule(self, user_id: int) -> ScheduleResponse:
        # Create dummy subjects
        subjects = [
            Subject(id=1, name="History"),
            Subject(id=2, name="Polity"),
            Subject(id=3, name="Science")
        ]

        # Starting time for schedule
        start_time = datetime.now().replace(hour=6, minute=0, second=0, microsecond=0)

        # Create study blocks
        blocks = []
        for i, subject in enumerate(subjects):
            block_start = start_time + timedelta(hours=i*2)
            block_end = block_start + timedelta(hours=2)
            blocks.append(
                StudyBlock(
                    subject_id=subject.id,
                    subject_name=subject.name,
                    start_time=block_start,
                    end_time=block_end,
                    type="Study"
                )
            )

        # Wrap in DailySchedule
        daily_schedule = DailySchedule(
            date=datetime.now().date(),
            study_blocks=blocks
        )

        return ScheduleResponse(
            user_id=user_id,
            daily_schedule=daily_schedule
        )