import importlib.util
import json
import subprocess
import sys
import unittest
from pathlib import Path
from unittest.mock import patch

HERE = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location("dq_server", HERE / "server.py")
server = importlib.util.module_from_spec(spec)
spec.loader.exec_module(server)


class RealPandasCompanionTests(unittest.TestCase):
    def test_worker_executed_real_groupby(self):
        data = {
            "code": "df.groupby('segment')['revenue'].sum()",
            "rows": [
                {"segment": "A", "revenue": 10},
                {"segment": "A", "revenue": 30},
                {"segment": "B", "revenue": 5},
            ],
        }
        result = subprocess.run(
            [sys.executable, str(HERE / "worker.py")],
            input=json.dumps(data).encode(), capture_output=True, check=True,
        )
        rows = json.loads(result.stdout)["rows"]
        self.assertEqual(rows, [
            {"segment": "A", "revenue": 40},
            {"segment": "B", "revenue": 5},
        ])
        data["rows"][0]["revenue"] = 19
        changed = subprocess.run(
            [sys.executable, str(HERE / "worker.py")],
            input=json.dumps(data).encode(), capture_output=True, check=True,
        )
        self.assertEqual(json.loads(changed.stdout)["rows"][0]["revenue"], 49)

    def test_sandbox_has_explicit_isolation_flags(self):
        response = subprocess.CompletedProcess(
            args=[], returncode=0, stdout=b'{"rows":[]}', stderr=b"",
        )
        with patch.object(server.subprocess, "run", return_value=response) as fake:
            result = server.run_pandas({"code": "df", "rows": []})
            self.assertEqual(result, {"rows": []})
            args = fake.call_args.args[0]
            for flag in ["--network", "none", "--read-only",
                         "--cap-drop", "ALL", "--pids-limit", "64",
                         "--user", "65534:65534"]:
                self.assertIn(flag, args)
            self.assertIn("dataquest-pandas-runner:local", args)

    def test_excessive_payload_is_rejected_before_container_launch(self):
        with patch.object(server.subprocess, "run") as fake:
            value = server.run_pandas({"code": "x" * 66000, "rows": []})
            self.assertIn("error", value)
            fake.assert_not_called()


if __name__ == "__main__":
    unittest.main()
