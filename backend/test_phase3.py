"""Phase 3 acceptance tests — Signal extraction + signal-aware scheduling."""
import requests
import json
from datetime import date, timedelta

BASE = "http://127.0.0.1:8000"
today = date.today()

def t(name, passed, detail=""):
    s = "PASS" if passed else "FAIL"
    print(f"[{s}] {name}")
    if detail:
        print(f"       {detail}")
    return passed

ok = True

# ═══════════════════════════════════════════════════════════════════════════
# TEST 1 — Signals endpoint with no history
# ═══════════════════════════════════════════════════════════════════════════
print("\n=== TEST 1: GET /schedule/signals/1 (no history) ===")
r = requests.get(f"{BASE}/schedule/signals/1")
d = r.json()
print(f"  Status: {r.status_code}")
print(f"  consistency_score: {d.get('consistency_score')}")
print(f"  weak_subjects: {d.get('weak_subjects')}")
print(f"  subject_signals count: {len(d.get('subject_signals', []))}")

ok &= t("HTTP 200", r.status_code == 200)
ok &= t("consistency_score = 0.0", d["consistency_score"] == 0.0)
ok &= t("weak_subjects empty", d["weak_subjects"] == [])
ok &= t("7 subject_signals", len(d["subject_signals"]) == 7)
ok &= t("all counts zero", all(
    s["miss_count"] == 0 and s["partial_count"] == 0 and s["complete_count"] == 0
    for s in d["subject_signals"]
))

# ═══════════════════════════════════════════════════════════════════════════
# TEST 2 — Seed history + verify signals
# ═══════════════════════════════════════════════════════════════════════════
print("\n=== TEST 2: Seed history + GET /schedule/signals/1 ===")

# Seed 10 blocks over the last 10 days via schedule/generate + report/submit
# Strategy: generate schedules for each day, then submit reports with the
# desired statuses. But this is complex — easier to insert directly via Python.
# We'll use a helper script approach: call generate for 10 separate dates,
# then submit reports marking specific blocks.

# Simpler approach: generate schedule for 10 different dates, then submit
# reports. But we need specific subjects at specific times.

# Easiest: use the API to generate + submit for each of 10 days.
# The scheduler will rotate subjects. Let's figure out what subjects come out.

results = []
for i in range(1, 11):
    d_i = today - timedelta(days=i)
    r_gen = requests.post(f"{BASE}/schedule/generate", json={"user_id": 1, "date": str(d_i)})
    blocks_i = r_gen.json().get("blocks", [])
    results.append((d_i, blocks_i))
    print(f"  Day -{i} ({d_i}): {len(blocks_i)} blocks - [{', '.join(b['subject'] for b in blocks_i)}]")

# Now submit reports. We want:
#   History missed 3+ times, Geography completed 3+ times at 09:00,
#   Polity partial 2+, Economy completed 2+.
# 
# The actual subjects depend on rotation. Let's just mark blocks by their subject:
#   - Any "History" block → missed
#   - Any "Geography" block → completed  
#   - Any "Polity" block → partial (50%)
#   - Any "Economy" block → completed
#   - Others → completed (so they don't pollute weak detection)

for d_i, blocks_i in results:
    if not blocks_i:
        continue
    report_blocks = []
    for b in blocks_i:
        subj = b["subject"]
        if subj == "History":
            report_blocks.append({"block_id": b["id"], "status": "missed", "completion_percent": 0})
        elif subj == "Polity":
            report_blocks.append({"block_id": b["id"], "status": "partial", "completion_percent": 50})
        else:
            report_blocks.append({"block_id": b["id"], "status": "completed", "completion_percent": 100})
    
    r_rep = requests.post(f"{BASE}/report/submit", json={
        "user_id": 1,
        "date": str(d_i),
        "blocks": report_blocks,
        "notes": f"Day {d_i}"
    })
    if r_rep.status_code != 200:
        print(f"  WARN: report submit for {d_i} returned {r_rep.status_code}: {r_rep.text}")

# Now fetch signals
r2 = requests.get(f"{BASE}/schedule/signals/1")
d2 = r2.json()
print(f"\n  Signals after seeding:")
print(f"  consistency_score: {d2['consistency_score']}")
print(f"  weak_subjects: {d2['weak_subjects']}")
for s in d2["subject_signals"]:
    if s["miss_count"] > 0 or s["complete_count"] > 0 or s["partial_count"] > 0:
        print(f"    {s['subject']}: miss={s['miss_count']} partial={s['partial_count']} complete={s['complete_count']} weak={s['is_weak']} preferred={s['preferred_slots']}")

hist_sig = next((s for s in d2["subject_signals"] if s["subject"] == "History"), None)
if hist_sig:
    ok &= t("History is_weak = True", hist_sig["is_weak"] == True, f"miss_count={hist_sig['miss_count']}")
else:
    ok &= t("History signal exists", False)

ok &= t("weak_subjects includes History", "History" in d2["weak_subjects"])
ok &= t("consistency_score > 0 and < 1", 0.0 < d2["consistency_score"] < 1.0,
         f"got {d2['consistency_score']}")

# ═══════════════════════════════════════════════════════════════════════════
# TEST 3 — Scheduler uses signals (weak subject first)
# ═══════════════════════════════════════════════════════════════════════════
print("\n=== TEST 3: POST /schedule/generate (tomorrow) ===")
tomorrow = today + timedelta(days=1)
r3 = requests.post(f"{BASE}/schedule/generate", json={"user_id": 1, "date": str(tomorrow)})
d3 = r3.json()
blocks3 = d3.get("blocks", [])
print(f"  Status: {r3.status_code}")
for b in blocks3:
    print(f"    ID={b['id']} | {b['subject']} | {b['start_time']}-{b.get('end_time','')} | resched={b.get('rescheduled_from_id')}")

# The weak subject (History) should appear in the schedule.
# It may arrive via rescheduled blocks (from past missed History) or via Rule 3B.
if blocks3:
    first = blocks3[0]
    ok &= t("First block is weak subject (History)",
             first["subject"] == "History",
             f"got {first['subject']}")
    # Check History is present at all
    hist_present = any(b["subject"] == "History" for b in blocks3)
    ok &= t("History present in schedule", hist_present)
else:
    ok &= t("Has blocks", False, "no blocks returned")

# ═══════════════════════════════════════════════════════════════════════════
# TEST 4 — Consistency score updates on User after report
# ═══════════════════════════════════════════════════════════════════════════
print("\n=== TEST 4: Consistency score on User ===")
# Query user directly
import sqlite3
conn = sqlite3.connect("upsc.db")
cur = conn.execute("SELECT consistency_score FROM users WHERE id = 1")
row = cur.fetchone()
conn.close()
user_cs = row[0] if row else None
print(f"  User.consistency_score = {user_cs}")
ok &= t("consistency_score is not 0.0", user_cs is not None and user_cs != 0.0,
         f"got {user_cs}")
ok &= t("consistency_score = signals.consistency_score",
         user_cs is not None and abs(user_cs - d2["consistency_score"]) < 0.01,
         f"user={user_cs}, signals={d2['consistency_score']}")

# ═══════════════════════════════════════════════════════════════════════════
# TEST 5 — Phase 2 regression (clean date)
# ═══════════════════════════════════════════════════════════════════════════
print("\n=== TEST 5: Phase 2 regression ===")
clean_date = today + timedelta(days=30)  # far future, no existing blocks

# 5a: POST /schedule/generate
r5a = requests.post(f"{BASE}/schedule/generate", json={"user_id": 1, "date": str(clean_date)})
d5a = r5a.json()
blocks5a = d5a.get("blocks", [])
print(f"  Generate: {r5a.status_code}, {len(blocks5a)} blocks")
ok &= t("5a: Returns 200", r5a.status_code == 200)
ok &= t("5a: Has blocks", len(blocks5a) > 0)

# 5b: GET same schedule
r5b = requests.get(f"{BASE}/schedule/1/{clean_date}")
d5b = r5b.json()
ids_a = [b["id"] for b in blocks5a]
ids_b = [b["id"] for b in d5b.get("blocks", [])]
ok &= t("5b: Idempotent", ids_a == ids_b, f"ids_a={ids_a}, ids_b={ids_b}")

# 5c: Submit report
if len(blocks5a) >= 2:
    r5c = requests.post(f"{BASE}/report/submit", json={
        "user_id": 1,
        "date": str(clean_date),
        "blocks": [
            {"block_id": blocks5a[0]["id"], "status": "completed", "completion_percent": 100},
            {"block_id": blocks5a[1]["id"], "status": "missed", "completion_percent": 0},
        ],
        "notes": "regression test"
    })
    d5c = r5c.json()
    ok &= t("5c: Report submit 200", r5c.status_code == 200)
    ok &= t("5c: blocks_completed=1", d5c.get("blocks_completed") == 1)
    ok &= t("5c: blocks_missed=1", d5c.get("blocks_missed") == 1)
    ok &= t("5c: rescheduled_count=1", d5c.get("rescheduled_count") == 1)

    # 5d: GET report
    r5d = requests.get(f"{BASE}/report/1/{clean_date}")
    d5d = r5d.json()
    ok &= t("5d: Report GET 200", r5d.status_code == 200)
    ok &= t("5d: notes match", d5d.get("notes") == "regression test")

# ═══════════════════════════════════════════════════════════════════════════
# SUMMARY
# ═══════════════════════════════════════════════════════════════════════════
print("\n" + "="*60)
if ok:
    print("ALL PHASE 3 ACCEPTANCE CRITERIA PASSED")
else:
    print("SOME CRITERIA FAILED")
print("="*60)
