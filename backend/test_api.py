import requests
import time
import sys

BASE_URL = "http://127.0.0.1:8000"

def wait_for_server():
    for _ in range(10):
        try:
            r = requests.get(f"{BASE_URL}/health")
            if r.status_code == 200:
                print("Server is up!")
                return True
        except:
            pass
        time.sleep(1)
    return False

def run_tests():
    if not wait_for_server():
        print("Server did not start in time.")
        sys.exit(1)

    print("\n--- Test 1: Generate Schedule ---")
    data = {"user_id": 1, "date": "2025-08-01"}
    r = requests.post(f"{BASE_URL}/schedule/generate", json=data)
    assert r.status_code == 200, f"Generate failed: {r.text}"
    resp_json = r.json()
    blocks = resp_json.get("blocks", [])
    print(f"Generated {len(blocks)} blocks.")
    assert len(blocks) == 4, "Should be 4 blocks of 90 mins (6 hours total)"
    block1_id = blocks[0]["id"]
    block2_id = blocks[1]["id"]
    block3_id = blocks[2]["id"]

    print("\n--- Test 2: Get Schedule (Duplicate check) ---")
    r2 = requests.get(f"{BASE_URL}/schedule/1/2025-08-01")
    assert r2.status_code == 200
    blocks2 = r2.json().get("blocks", [])
    assert len(blocks2) == 4, "Should return the same 4 blocks"
    assert blocks2[0]["id"] == block1_id, "IDs should match exactly (no duplicates generated)"
    print("No duplicates generated on GET.")

    print("\n--- Test 3: Submit Report ---")
    report_data = {
        "user_id": 1,
        "date": "2025-08-01",
        "blocks": [
            {"block_id": block1_id, "status": "completed", "completion_percent": 100},
            {"block_id": block2_id, "status": "partial", "completion_percent": 50},
            {"block_id": block3_id, "status": "missed", "completion_percent": 0}
        ],
        "notes": "Good focus day"
    }
    r3 = requests.post(f"{BASE_URL}/report/submit", json=report_data)
    assert r3.status_code == 200, f"Submit failed: {r3.text}"
    rep_resp = r3.json()
    print(f"Report Output: {rep_resp}")
    assert rep_resp["blocks_completed"] == 1
    assert rep_resp["blocks_partial"] == 1
    assert rep_resp["blocks_missed"] == 1
    assert rep_resp["rescheduled_count"] == 1, "1 block missed -> 1 block rescheduled"

    print("\n--- Test 4: Get Report ---")
    r4 = requests.get(f"{BASE_URL}/report/1/2025-08-01")
    assert r4.status_code == 200
    get_rep = r4.json()
    assert get_rep["notes"] == "Good focus day"
    assert get_rep["blocks_missed"] == 1
    print("Report retrieved successfully.")

    print("\nALL ACCEPTANCE CRITERIA TESTS PASSED!")

if __name__ == "__main__":
    run_tests()
