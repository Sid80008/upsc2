import requests
import json
import datetime

base_url = "http://127.0.0.1:8000"

def run_tests():
    try:
        # 1. Login
        login_data = {"username": "user@mail.com", "password": "user"}
        r = requests.post(f"{base_url}/auth/login", data=login_data)
        if r.status_code != 200:
            print("Login failed:", r.text)
            return
            
        token = r.json().get("access_token")
        headers = {"Authorization": f"Bearer {token}"}
        
        # 2. Fire Onboarding
        onboarding_p = {
            "goal_type": "both", "target_year": 2025, "months_remaining": 12, "current_level": "intermediate",
            "preferred_study_slots": ["morning", "afternoon"], "wake_time": "08:00", "sleep_time": "22:00",
            "focus_level": "high", "distraction_level": "low", "peak_focus_time": "morning",
            "primary_problem": "burnout", "biggest_problems": ["burnout"], "session_length": 60, "study_style": "multi",
            "revision_preference": "daily", "weak_subjects": ["History"], "strong_subjects": ["Polity"],
            "covered_subjects": ["History", "Geography", "Polity", "Economy"]
        }
        
        print(f"--- Firing Onboarding API ---")
        r2 = requests.post(f"{base_url}/onboarding/complete", json=onboarding_p, headers=headers)
        print("Status:", r2.status_code)
        if r2.status_code != 200:
            print("Onboarding Error:", r2.text)
        
        # 3. Schedule verification
        tomorrow = (datetime.date.today() + datetime.timedelta(days=1)).isoformat()
        r3 = requests.get(f"{base_url}/schedule/1/{tomorrow}", headers=headers)
        if r3.status_code != 200:
            print("Schedule Gen Error:", r3.text)
        else:
            data = r3.json()
            print(f"\n--- Schedule Generation Payload ({tomorrow}) ---")
            print(f"Total Blocks Generated: {len(data.get('blocks', []))}")
            print(f"Total Planned Mins: {data.get('total_planned_minutes')}")
            
            for idx, block in enumerate(data.get('blocks', [])):
                print(f"Block {idx+1}: {block['start_time']} - [{block['subject']}] (Duration: {block['duration_minutes']}m)")
            
        # 4. Endpoints Check
        print("\n--- Insights Endpoint Check ---")
        r5 = requests.get(f"{base_url}/insights/weekly/1", headers=headers)
        print("Weekly Insights Return OK?", r5.status_code == 200)
        
        r6 = requests.get(f"{base_url}/insights/subjects/1", headers=headers)
        print("Subject Insights Return OK?", r6.status_code == 200)
        
        print("\n--- AI Tutor Chat Check ---")
        chat_payload = {
            "messages": [
                {"role": "user", "content": "Hello, I am struggling with Modern History."}
            ]
        }
        r7 = requests.post(f"{base_url}/tutor/chat", json=chat_payload, headers=headers)
        if r7.status_code == 200:
            print("Chat Response:", r7.json().get("reply")[:100] + "...")
            print("Tutor API OK? True")
        else:
            print("Tutor Error:", r7.text)
            
    except Exception as e:
        print(f"Test failed with Exception: {e}")

if __name__ == "__main__":
    run_tests()
