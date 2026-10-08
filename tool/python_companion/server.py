"""Opt-in localhost-only Pandas companion. Requires local Docker image."""
import json
import subprocess
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

IMAGE = "dataquest-pandas-runner:local"
WORKER = str(Path(__file__).with_name("worker.py").resolve())
LIMIT = 65536

def run_pandas(payload):
    if not isinstance(payload, dict):
        return {"error": "Invalid request."}
    data = json.dumps(payload).encode()
    if len(data) > LIMIT:
        return {"error": "Payload too large."}
    command = [
        "docker", "run", "--rm", "-i", "--network", "none",
        "--read-only", "--cap-drop", "ALL",
        "--security-opt", "no-new-privileges",
        "--pids-limit", "64", "--memory", "512m", "--cpus", "1",
        "--user", "65534:65534",
        "--tmpfs", "/tmp:rw,nosuid,size=16m",
        "--mount", "type=bind,src=" + WORKER + ",dst=/worker.py,readonly",
        IMAGE, "python", "-I", "/worker.py",
    ]
    try:
        result = subprocess.run(command, input=data, capture_output=True,
                                timeout=12, check=False)
        if len(result.stdout) > LIMIT:
            return {"error": "Output too large."}
        return json.loads(result.stdout) if result.stdout else {
            "error": "No runner response."
        }
    except subprocess.TimeoutExpired:
        return {"error": "Execution timed out."}
    except (OSError, ValueError, json.JSONDecodeError):
        return {"error": "Local Docker runtime unavailable."}

class Handler(BaseHTTPRequestHandler):
    def do_POST(self):
        if self.path != "/run":
            self.send_error(404)
            return
        try:
            size = int(self.headers.get("Content-Length", "0"))
            if size < 1 or size > LIMIT:
                self.send_error(413)
                return
            response = run_pandas(json.loads(self.rfile.read(size)))
        except (ValueError, json.JSONDecodeError):
            response = {"error": "Invalid JSON."}
        body = json.dumps(response).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        self.send_error(405)

    def log_message(self, fmt, *args):
        pass

if __name__ == "__main__":
    print("DataQuest local Pandas runner: http://127.0.0.1:8765/run")
    ThreadingHTTPServer(("127.0.0.1", 8765), Handler).serve_forever()
