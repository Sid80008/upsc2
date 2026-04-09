# FLUTTER_AUDIT.md

## Step 1: Audit Findings

### `lib/services/schedule_service.dart`
- **Current Endpoints Called:**
  - `GET /schedule/{userId}/{dateStr}` (Matches backend)
  - `POST /report/submit` (Matches backend)
  - `POST /add_task` (Matches backend `library.add_subject`? No, there is an `add_task` endpoint in some phases, but Phase 5 used `submit_report` for rescheduling)
  - `POST /schedule/backlog-adjust`
  - `GET /insights/subjects/1` (Hardcoded userId)
  - `PATCH /schedule/block/update-time`
  - `GET /dashboard/summary`
  - `POST /recovery/optimize`
  - `GET /library/subjects`
  - `GET /library/folders`
  - `GET /library/assets`
  - `POST /ai/query`
  - `POST /auth/preferences`
  - `POST /library/add_subject`
  - `GET /news/daily`
  - `POST /library/upload`
- **Observations:** This service is acting as a "God Service", handling everything from news to auth preferences. It should be refactored or at least documented as the primary target for Step 3.

### `lib/services/report_service.dart`
- **`submitDailyReport()` Implementation:**
  - Sends a `DailyReport` object (date, completedMinutes, totalScheduledMinutes, productivityScore, focusSubject).
  - Calls `POST /reports/daily`.
- **Observations:** This **DOES NOT MATCH** the backend `ReportSubmitRequest` (which expects a list of block IDs and statuses). It needs a complete rewrite in Step 3.

### `lib/services/api_service.dart`
- **Base URL:** `http://10.0.2.2:8000` (localhost for Android emulator).
- **Auth Headers:** Not centralized here; currently `ScheduleService` and `ReportService` individually pull `jwt_token` from `SharedPreferences` and set `Authorization: Bearer $token`.

### `lib/screens/home_screen.dart`
- **Data Displayed:**
  - `Daily Progress`: Calculated locally via `_completedMinutes / _totalMinutes`.
  - `Streak`, `XP`, `Pending Units`: Fetched from `_api.fetchDashboardSummary()`.
  - `Up Next`: Selected from the first pending/ongoing block in the `_blocks` list.
  - `Synchronization Log`: List of study blocks for today.
  - `Intelligence Briefing`: List of news items.

### `lib/screens/schedule_screen.dart`
- **Fetch/Render:** Calls `_api.fetchDailySchedule(targetDate: dateStr)`.
- **Render Logic:** Maps `StudyBlock` objects to a `_buildTimelineBlock` widget. 
- **Observations:** Currently renders blocks, but does not yet handle the `topic` field or `rescheduledFromId` indicator requested in Step 5.

### `lib/screens/insights_screen.dart`
- **Current State:** **PLACEHOLDER DATA**.
- **Observations:** Uses hardcoded lists (`days`, `values`) and hardcoded subject rows ('Polity', 'History', 'Geography' with fixed percentages). No external API calls are currently being made in this screen.

### `lib/models/study_block.dart`
- **Fields:** `subject`, `startTime`, `endTime`.
- **Observations:** Missing `id`, `userId`, `topic`, `durationMinutes`, `status`, `completionPercent`, `rescheduledFromId`. Also, `ScheduleService` defines its own `StudyBlock` class which is actually what the screens are using. This needs unification.

### `lib/models/daily_report.dart`
- **Schema:** `date`, `completedTasks`, `partialTasks`, `missedTasks`, `distractionTime`.
- **Observations:** **DOES NOT MATCH** the backend `ReportSubmitRequest`. Needs full replacement.

---
**Audit Complete. Ready to proceed to Step 2: Fix Data Models.**
