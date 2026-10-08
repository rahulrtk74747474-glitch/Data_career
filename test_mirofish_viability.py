"""Offline tests of the DataQuest/MiroFish research bridge. No API keys/network."""
import importlib.util
import json
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("mirofish_bridge",
                                               ROOT / "tool" / "mirofish_viability.py")
bridge = importlib.util.module_from_spec(spec)
spec.loader.exec_module(bridge)


class FakeMiroFish:
    """Faked HTTP protocol; never represents an actual MiroFish run."""
    def __init__(self):
        self.posts = []

    def upload(self, seed, requirement, name):
        assert seed.exists()
        assert "Synthetic actor map" in seed.read_text(encoding="utf-8")
        self.posts.append(("upload", {"requirement": requirement, "name": name}))
        return {"project_id": "test_proj"}

    def get(self, endpoint):
        if endpoint == "/api/graph/task/test_graph_task":
            return {"status": "completed", "result": {"graph_id": "test_graph"}}
        if endpoint == "/api/graph/project/test_proj":
            return {"graph_id": "test_graph"}
        if endpoint == "/api/simulation/test_sim/run-status":
            return {"runner_status": "completed", "current_round": 8}
        if endpoint == "/api/report/test_report":
            return {"markdown_content": "Synthetic discussion of competing opinions."}
        raise AssertionError("Unexpected GET: " + endpoint)

    def post(self, endpoint, data):
        self.posts.append((endpoint, data))
        responses = {
            "/api/graph/build": {"task_id": "test_graph_task"},
            "/api/simulation/create": {"simulation_id": "test_sim"},
            "/api/simulation/prepare": {"status": "ready", "already_prepared": True},
            "/api/simulation/start": {"runner_status": "running"},
            "/api/report/generate": {"task_id": "test_report_task"},
            "/api/report/generate/status": {
                "status": "completed", "report_id": "test_report"},
        }
        assert endpoint in responses, "Unexpected POST: " + endpoint
        return responses[endpoint]


class ResearchBridgeTests(unittest.TestCase):
    def test_seed_and_source_references_are_grounded(self):
        config = bridge.load_scenarios()
        self.assertEqual(len(config["scenarios"]), 3)
        self.assertEqual(config["external_engine"]["license"], "AGPL-3.0")
        text = bridge.make_seed(config["scenarios"][0])
        self.assertIn("NOT observed real people", text)
        self.assertIn("NO", text.upper())

    def test_prepare_creates_mirofish_supported_markdown_and_explanation(self):
        s = bridge.select_scenario(bridge.load_scenarios(), "evidence_first")
        with tempfile.TemporaryDirectory() as out:
            f, requirement = bridge.prepare(s, Path(out))
            self.assertEqual(f.suffix, ".md")
            self.assertTrue(f.exists())
            self.assertIn("baseline", bridge.SEED.read_text(encoding="utf-8").lower())
            self.assertIn(s["requirement"], requirement.read_text(encoding="utf-8"))
            data = json.loads((Path(out) / "experiment_manifest.json")
                              .read_text(encoding="utf-8"))
            self.assertEqual(data["status"], "not_run")
            self.assertIn("not real product testing", data["method"])

    def test_localhost_only(self):
        for base in ("http://127.0.0.1:5001", "http://localhost:5001"):
            self.assertIsInstance(bridge.MiroFishClient(base), bridge.MiroFishClient)
        for base in ("https://localhost:5001",
                     "https://thirdparty.example/api",
                     "http://192.168.1.2:5001"):
            with self.assertRaises(ValueError):
                bridge.MiroFishClient(base)

    def test_mock_protocol_report_is_marked_synthetic(self):
        s = bridge.select_scenario(bridge.load_scenarios(), "baseline")
        with tempfile.TemporaryDirectory() as out:
            p = Path(out)
            seed, _ = bridge.prepare(s, p)
            fake = FakeMiroFish()
            bridge.simulate(fake, seed, s, p, max_minutes=1, max_rounds=8)
            report = (p / "mirofish_simulation_report.md").read_text()
            metadata = json.loads((p / "simulation_run_metadata.json").read_text())
            self.assertIn("UNVALIDATED SYNTHETIC", report)
            self.assertFalse(metadata["human_beta_validated"])
            self.assertEqual(metadata["rounds_requested"], 8)
            starts = [d for path, d in fake.posts
                      if path == "/api/simulation/start"]
            self.assertEqual(starts[0]["max_rounds"], 8)
            self.assertIs(starts[0]["enable_graph_memory_update"], False)

    def test_offline_check_command(self):
        self.assertEqual(bridge.main(["check"]), 0)


if __name__ == "__main__":
    unittest.main()
