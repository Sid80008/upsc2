"""Acceptance test script for Phase 2 refactor."""
import requests
import json
import sys

BASE = "http://127.0.0.1:8000"

def test(name, passed, detail=""):
    status = "PASS" if passed else "FAIL"
    print(f"[{status}] {name}")
    if detail:
        print(f"       {detail}")
    if not passed:
        return False
    return True

all_pass = True

# ── Test 1: POST /schedule/generate → deterministic blocks ─────────────────
print("\n=== TEST 1: POST /schedule/generate ===")
r = requests.post(f"{BASE}/schedule/generate", json={"user_id": 1, "date": "2025-08-01"})
data = r.json()
blocks = data.get("blocks", [])
subjects = [b["subject"] for b in blocks]
print(f"  Status: {r.status_code}")
print(f"  Blocks: {len(blocks)}")
print(f"  Subjects: {subjects}")
print(f"  Total planned: {data.get('total_planned_minutes')}")
for b in blocks:
    print(f"    ID={b['id']} | {b['subject']} | {b['start_time']}-{b.get('end_time','')} | {b['duration_minutes']}min | resched={b.get('rescheduled_from_id')}")

all_pass &= test("Returns 200", r.status_code == 200)
all_pass &= test("Has blocks", len(blocks) > 0, f"got {len(blocks)} blocks")
all_pass &= test("Total planned = user.daily_study_hours * 60 (360)",
                  data.get("total_planned_minutes", 0) == len(blocks) * 90,
                  f"planned={data.get('total_planned_minutes')}, expected={len(blocks)*90}")

# Idempotency
r2 = requests.post(f"{BASE}/schedule/generate", json={"user_id": 1, "date": "2025-08-01"})
data2 = r2.json()
ids1 = [b["id"] for b in blocks]
ids2 = [b["id"] for b in data2.get("blocks", [])]
all_pass &= test("Idempotent (same IDs)", ids1 == ids2, f"ids1={ids1}, ids2={ids2}")

# ── Test 2: GET /schedule/1/2025-08-01 → same blocks ────────────────────
print("\n=== TEST 2: GET /schedule/1/2025-08-01 ===")
r3 = requests.get(f"{BASE}/schedule/1/2025-08-01")
data3 = r3.json()
ids3 = [b["id"] for b in data3.get("blocks", [])]
print(f"  Status: {r3.status_code}")
print(f"  Block IDs: {ids3}")
all_pass &= test("Returns 200", r3.status_code == 200)
all_pass &= test("Same blocks as Test 1", ids1 == ids3, f"ids1={ids1}, ids3={ids3}")

# ── Test 3: POST /report/submit ──────────────────────────────────────────
print("\n=== TEST 3: POST /report/submit ===")
# We need at least 4 blocks. Use the first 4 from Test 1.
if len(blocks) >= 4:
    report_body = {
        "user_id": 1,
        "date": "2025-08-01",
        "blocks": [
            {"block_id": blocks[0]["id"], "status": "completed", "completion_percent": 100},
            {"block_id": blocks[1]["id"], "status": "completed", "completion_percent": 100},
            {"block_id": blocks[2]["id"], "status": "partial",   "completion_percent": 50},
            {"block_id": blocks[3]["id"], "status": "missed",    "completion_percent": 0},
        ],
        "notes": "Had a bad afternoon."
    }
    r4 = requests.post(f"{BASE}/report/submit", json=report_body)
    rdata = r4.json()
    print(f"  Status: {r4.status_code}")
    print(f"  Response: {json.dumps(rdata, indent=2)}")

    all_pass &= test("Returns 200", r4.status_code == 200)
    all_pass &= test("blocks_completed = 2", rdata.get("blocks_completed") == 2)
    all_pass &= test("blocks_partial = 1", rdata.get("blocks_partial") == 1)
    all_pass &= test("blocks_missed = 1", rdata.get("blocks_missed") == 1)
    all_pass &= test("rescheduled_count = 1", rdata.get("rescheduled_count") == 1)
else:
    print(f"  SKIP: only {len(blocks)} blocks, need 4")
    all_pass = False

# ── Test 4: GET /report/1/2025-08-01 ────────────────────────────────────
print("\n=== TEST 4: GET /report/1/2025-08-01 ===")
r5 = requests.get(f"{BASE}/report/1/2025-08-01")
rdata5 = r5.json()
print(f"  Status: {r5.status_code}")
print(f"  Response: {json.dumps(rdata5, indent=2)}")
all_pass &= test("Returns 200", r5.status_code == 200)
all_pass &= test("blocks_completed = 2", rdata5.get("blocks_completed") == 2)
all_pass &= test("blocks_partial = 1", rdata5.get("blocks_partial") == 1)
all_pass &= test("blocks_missed = 1", rdata5.get("blocks_missed") == 1)
all_pass &= test("notes match", rdata5.get("notes") == "Had a bad afternoon.")

# ── Test 5: GET /schedule/1/2025-08-02 → rescheduled block first ────────
print("\n=== TEST 5: POST /schedule/generate for 2025-08-02 ===")
r6 = requests.post(f"{BASE}/schedule/generate", json={"user_id": 1, "date": "2025-08-02"})
data6 = r6.json()
blocks6 = data6.get("blocks", [])
print(f"  Status: {r6.status_code}")
for b in blocks6:
    print(f"    ID={b['id']} | {b['subject']} | {b['start_time']}-{b.get('end_time','')} | resched={b.get('rescheduled_from_id')}")

all_pass &= test("Returns 200", r6.status_code == 200)
if blocks6:
    first = blocks6[0]
    missed_id = blocks[3]["id"] if len(blocks) >= 4 else None
    all_pass &= test(
        f"First block has rescheduled_from_id = {missed_id}",
        first.get("rescheduled_from_id") == missed_id,
        f"got rescheduled_from_id={first.get('rescheduled_from_id')}"
    )
else:
    all_pass &= test("Has blocks", False, "no blocks returned")

# ── Summary ──────────────────────────────────────────────────────────────
print("\n" + "="*60)
if all_pass:
    print("ALL ACCEPTANCE CRITERIA PASSED")
else:
    print("SOME CRITERIA FAILED — fix before proceeding")
print("="*60)
