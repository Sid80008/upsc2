import subprocess
import sys

def run():
    print("Running database migrations...")
    result = subprocess.run(
        ["python", "-m", "alembic", "upgrade", "head"],
        capture_output=True, text=True
    )
    print(result.stdout)
    if result.returncode != 0:
        print("Migration failed!")
        print(result.stderr)
        sys.exit(1)
    print("Migrations complete.")

if __name__ == "__main__":
    run()
