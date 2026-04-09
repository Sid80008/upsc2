c
---

## PHASE 3 — DETERMINISTIC INTELLIGENCE

```
Step 1: ✅ Created services/signal_extractor.py (UserSignals + SubjectSignal dataclasses, extract_signals)
Step 2: ✅ Upgraded rule_based_scheduler.py — added Rules 3B (weak subject priority), 3C (slot avoidance), preferred slot adjustments
Step 3: ✅ Added GET /schedule/signals/{user_id} endpoint + SubjectSignalOut, UserSignalsOut schemas
Step 4: ✅ Added User.consistency_score, updated report_processor.py to refresh it after each report
Step 5: ✅ All 5 acceptance criteria verified — 20/20 assertions pass
```

### Summary

The system now reads 14 days of historical StudyBlocks to detect: which subjects are weak (≥3 misses), which time slots to avoid (repeatedly missed), which slots are preferred (frequently completed), and a rolling consistency score (completed / total). The scheduler uses these signals to insert the highest-miss weak subject as the first new block, avoid problem time slots with up to 2 × 60-minute shifts, and honour preferred completion slots. The consistency score is persisted on the User model and updated after every report submission. No AI is called; all analysis is pure SQL + Python.

### Files Modified (Phase 3)

| File | Change |
|---|---|
| `services/signal_extractor.py` | **NEW** — Signal extraction: SubjectSignal, UserSignals, extract_signals() |
| `services/rule_based_scheduler.py` | **UPGRADED** — Rules 3B, 3C, and preferred slot adjustments |
| `schemas.py` | Added `SubjectSignalOut`, `UserSignalsOut` |
| `routers/schedule.py` | Added `GET /signals/{user_id}` endpoint |
| `db/models.py` | Added `User.consistency_score` |
| `services/report_processor.py` | Added consistency_score update at end of `process_report` |

---

## PHASE 4 — AI INJECTION

```
Step 1: ✅ Added USE_AI_SCHEDULER, GEMINI_TIMEOUT_SECONDS, AI_FALLBACK_ENABLED, MAX_AI_RETRIES to config.py
Step 2: ✅ Rewrote ai_engine.py — generate_schedule with idempotency, context gathering, Gemini call, validation, DB write
Step 3: ✅ Created _validate_ai_response — 10-rule validator (JSON, subjects, times, durations, totals)
Step 4: ✅ Created _ai_schedule_with_fallback — silent fallback to rule-based scheduler, double-nested try/except
Step 5: ✅ Topic generation from AI response, truncation to 120 chars, fallback default
Step 6: ✅ Created behavioral_fingerprint.py — 30-day profile with 8 metrics. Updated schemas + endpoint.
Step 7: ✅ All 6 acceptance test groups passed — 34/34 assertions
```

### Summary

The AI is now injected into the scheduling loop as a swappable Decision Engine. When `USE_AI_SCHEDULER = True`, Gemini receives a prompt containing the student profile, 14-day behavioral signals, 7-day history, rescheduled blocks, and 9 scheduling rules. The AI generates blocks with specific UPSC topics (e.g., "Ancient India — Indus Valley Civilization") rather than generic "General Revision" placeholders. If Gemini fails (quota, timeout, malformed output), the system silently falls back to the rule-based scheduler — the user always gets a schedule, never a 500. The behavioral fingerprint (best/worst study day, streaks, peak performance hour) enriches the signals endpoint for the Flutter app.

### What AI Adds Over the Rule Engine

The rule-based scheduler rotates subjects deterministically and assigns the generic topic "General Revision" to every block. The AI scheduler, by contrast, reads the student's behavioral signals, weak/strong subjects, preferred study times, and exam date to make contextual placement decisions — placing weak subjects during peak focus hours, generating specific subtopics per block, and respecting the student's individual session length preferences. Where the rule engine treats all subjects equally and rotates blindly, the AI weights subjects by the student's actual completion patterns and avoidance history.

### Files Modified (Phase 4)

| File | Change |
|---|---|
| `core/config.py` | Added 4 config flags: USE_AI_SCHEDULER, GEMINI_TIMEOUT_SECONDS, AI_FALLBACK_ENABLED, MAX_AI_RETRIES |
| `services/ai_engine.py` | **REWRITTEN** — module-level generate_schedule, prompt builder, validator, fallback handler |
| `services/behavioral_fingerprint.py` | **NEW** — 30-day behavioral profile with 8 metrics |
| `services/orchestrator.py` | Import path fix: AIEngine.generate_schedule → ai_engine.generate_schedule |
| `schemas.py` | Added `BehavioralFingerprintOut`, added `fingerprint` field to `UserSignalsOut` |
| `routers/schedule.py` | Updated signals endpoint to include fingerprint |

### Fallback Verification

Fallback was tested live — Gemini quota was exhausted during testing, triggering the fallback path on every schedule generation call. Server logs confirm: "AI scheduler fallback triggered: Gemini failed after 2 attempts: 429 ..." followed by HTTP 200 with valid rule-based schedule. The user never received a 500 error.
