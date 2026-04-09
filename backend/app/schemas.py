from datetime import date, datetime
from typing import List, Optional, Dict
from pydantic import BaseModel

# ---------------------------------------------------------------------------
# Signal Schemas (Phase 3)
# ---------------------------------------------------------------------------

class SubjectSignalOut(BaseModel):
    subject: str
    miss_count: int
    partial_count: int
    complete_count: int
    avg_completion_pct: float
    is_weak: bool
    preferred_slots: List[str]

class BehavioralFingerprintOut(BaseModel):
    best_study_day: Optional[str] = None
    worst_study_day: Optional[str] = None
    avg_daily_completion_pct: Optional[float] = None
    longest_streak_days: Optional[int] = None
    current_streak_days: Optional[int] = None
    most_avoided_subject: Optional[str] = None
    most_consistent_subject: Optional[str] = None
    peak_performance_hour: Optional[str] = None

class UserSignalsOut(BaseModel):
    user_id: int
    computed_at: datetime
    consistency_score: float
    weak_subjects: List[str]
    avoidance_patterns: Dict[str, List[str]]
    recommended_slot_adjustments: Dict[str, str]
    subject_signals: List[SubjectSignalOut]
    fingerprint: Optional[BehavioralFingerprintOut] = None

# ---------------------------------------------------------------------------
# Schedule Schemas
# ---------------------------------------------------------------------------


class ScheduleGenerateRequest(BaseModel):
    user_id: Optional[int] = None
    date: date

class TaskAddRequest(BaseModel):
    user_id: Optional[int] = None
    date: date
    subject: str
    topic: str
    start_time: str
    duration_minutes: int

class StudyBlockOut(BaseModel):
    id: int
    subject: str
    topic: Optional[str] = None
    date: date
    start_time: str
    end_time: Optional[str] = None
    duration_minutes: int
    status: str
    completion_percent: int
    time_spent_minutes: int = 0
    rescheduled_from_id: Optional[int] = None

    class Config:
        from_attributes = True

class ScheduleGenerateResponse(BaseModel):
    date: date
    total_planned_time: int = 0
    total_completed_time: int = 0
    # Legacy compatibility fields for mobile app
    total_planned_minutes: int = 0
    total_completed_minutes: int = 0
    blocks: List[StudyBlockOut]

class BlockReportItem(BaseModel):
    block_id: int
    status: str
    completion_percent: int = 0
    time_spent_minutes: int = 0

class ReportSubmitRequest(BaseModel):
    user_id: Optional[int] = None
    date: date
    blocks: List[BlockReportItem]
    notes: Optional[str] = None

class ReportSubmitResponse(BaseModel):
    report_id: int
    blocks_completed: int
    blocks_partial: int
    blocks_missed: int
    rescheduled_count: int

class UserCreate(BaseModel):
    name: str
    email: str
    password: str
    daily_study_hours: Optional[int] = 6

class UserOut(BaseModel):
    id: int
    name: str
    email: str
    daily_study_hours: Optional[int] = 6
    xp: Optional[int] = 0
    streak_days: Optional[int] = 0

    class Config:
        from_attributes = True

class UserUpdate(BaseModel):
    daily_study_hours: Optional[int] = None
    name: Optional[str] = None
    target_year: Optional[int] = None
    weak_subjects: Optional[List[str]] = None

class Token(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str

class TokenRefreshRequest(BaseModel):
    refresh_token: str

class OnboardingRequest(BaseModel):
    goal_type: str
    target_year: int
    months_remaining: int
    current_level: str
    
    preferred_study_slots: List[str]
    wake_time: str
    sleep_time: str
    
    focus_level: str
    distraction_level: str
    peak_focus_time: str
    primary_problem: str
    biggest_problems: Optional[List[str]] = []
    
    session_length: int
    study_style: str
    revision_preference: str
    
    weak_subjects: List[str]
    strong_subjects: List[str]
    covered_subjects: List[str]

class UserSetupRequest(BaseModel):
    name: str
    exam_date: date
    daily_study_hours: int
    selected_subjects: List[str]
    preferred_study_time: str # morning / afternoon / evening
    difficulty_preference: str # light / medium / heavy

class DashboardSummary(BaseModel):
    total_study_hours_today: float
    total_study_hours_week: float
    completion_percentage_today: int
    streak_days: int
    pending_blocks_today: int
    missed_blocks_last_3_days: int
    xp: int = 0

class SubjectStats(BaseModel):
    subject_name: str
    total_hours_studied: float
    last_studied_date: Optional[date]
    strength_score: int

class AIQueryRequest(BaseModel):
    query: str
    context: Optional[str] = None

class AIQueryResponse(BaseModel):
    response: str
    is_fallback: bool = False

class RecoveryOptimizeResponse(BaseModel):
    number_of_blocks_rescheduled: int
    affected_dates: List[date]

class UserPreferencesRequest(BaseModel):
    study_style: Optional[str] = None
    focus_level: Optional[str] = None
    revision_preference: Optional[str] = None
    current_affairs_weight: Optional[int] = None

class SubjectAddRequest(BaseModel):
    subject_name: str
    topic: Optional[str] = None
    time_period: Optional[str] = None # e.g. "4 weeks"
    priority: Optional[str] = "medium" # high, medium, low

class NewsOut(BaseModel):
    id: int
    title: str
    content: str
    source: str
    date: date
    category: str
    image_url: Optional[str] = None

    class Config:
        from_attributes = True

class ClearDataResponse(BaseModel):
    status: str
    message: str

class TimeUpdateRequest(BaseModel):
    block_id: int
    time_spent_minutes: int

class FolderCreate(BaseModel):
    name: str
    description: Optional[str] = None
    icon: Optional[str] = "folder"

class FolderOut(BaseModel):
    id: int
    name: str
    description: Optional[str]
    icon: Optional[str]
    created_at: datetime

    class Config:
        from_attributes = True

class KnowledgeAssetCreate(BaseModel):
    title: str
    folder_id: Optional[int] = None
    asset_type: str
    meta_info: Optional[str] = None
    content_url: Optional[str] = None

class KnowledgeAssetOut(BaseModel):
    id: int
    folder_id: Optional[int]
    title: str
    asset_type: str
    status: str
    meta_info: Optional[str]
    content_url: Optional[str]
    created_at: datetime

    class Config:
        from_attributes = True

class WeeklyReviewOut(BaseModel):
    user_id: int
    week_start: date
    week_end: date
    generated_at: datetime
    total_blocks: int
    completed_blocks: int
    partial_blocks: int
    missed_blocks: int
    completion_rate: float
    strongest_subject: str
    weakest_subject: str
    most_improved: Optional[str] = None
    most_declined: Optional[str] = None
    recommended_weight_adjustments: Dict[str, int]
    summary_text: str
