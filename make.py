# make.py - simple task runner for Windows (replacement for Makefile)
import sys, os, subprocess

def run(cmd):
    print(f"> {cmd}")
    res = subprocess.run(cmd, shell=True)
    if res.returncode != 0:
        sys.exit(res.returncode)

def ingest():
    run("python ingest_py.py")

def models():
    run("python run_sql.py")

def compare():
    run("python compare.py")

def api():
    run("uvicorn api.main:app --host 0.0.0.0 --port 8000")

def init():
    for d in ["data", "db", "api", "n8n", "agent"]:
        os.makedirs(d, exist_ok=True)
    print("folders initialized")

tasks = {
    "init": init,
    "ingest": ingest,
    "models": models,
    "compare": compare,
    "api": api,
}

if __name__ == "__main__":
    if len(sys.argv) < 2 or sys.argv[1] not in tasks:
        print("Usage: python make.py [init|ingest|models|compare|api]")
        sys.exit(1)
    tasks[sys.argv[1]]()
