#!/usr/bin/env python3
"""DataQuest -> MiroFish research bridge (standard library, Python >=3.11).

This is an external, opt-in social simulation experiment. It is NOT an
app test, retention prediction, or independent validation of user demand.
No private user files or API credentials are read by this helper.
MiroFish itself needs LLM_API_KEY and ZEP_API_KEY configured separately.
"""
from __future__ import annotations

import argparse
import json
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
import uuid
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
EXPERIMENT = ROOT / "experiments" / "mirofish"
SCENARIOS = EXPERIMENT / "scenarios.json"
SEED = EXPERIMENT / "dataquest_seed.md"
VALID_STATES = {"completed", "failed"}


def load_scenarios():
    payload = json.loads(SCENARIOS.read_text(encoding="utf-8"))
    assert payload["schema_version"] == 1, "Unsupported schema version"
    assert payload["external_engine"]["repository"] == "https://github.com/666ghj/MiroFish"
    assert payload["external_engine"]["license"] == "AGPL-3.0"
    assert SEED.exists() and len(SEED.read_text(encoding="utf-8")) > 1000
    assert len(payload["scenarios"]) >= 3
    ids = [x["id"] for x in payload["scenarios"]]
    assert len(ids) == len(set(ids)), "Scenario IDs must be unique"
    for item in payload["scenarios"]:
        assert item["requirement"].strip()
        assert 1 <= item["recommended_rounds"] <= 20
        assert item["hypotheses"] and item["falsifiers"] and item["real_test"]
    for path in payload["evidence_sources"]:
        assert (ROOT / path).is_file(), "Missing grounded evidence source: " + path
    return payload


def select_scenario(payload, scenario_id):
    return next(x for x in payload["scenarios"] if x["id"] == scenario_id)


def make_seed(scenario):
    """MiroFish accepts .md/.txt/.pdf but NOT JSON as an input upload."""
    return (SEED.read_text(encoding="utf-8") +
            "\n\n## Simulation variation\n" + scenario["name"] +
            "\n\n" + scenario["requirement"] +
            "\n\n## Required output discipline\n"
            "Interpret all simulated votes, posts and opinions as fictitious. "
            "State concrete counterarguments. Propose real-world tests, "
            "not prediction percentages. No fabricated retention or revenue.\n")


def prepare(scenario, output: Path):
    output.mkdir(parents=True, exist_ok=True)
    seed_path = output / ("dataquest_" + scenario["id"] + "_mirofish_seed.md")
    requirement_path = output / "simulation_requirement.txt"
    seed_path.write_text(make_seed(scenario), encoding="utf-8")
    requirement_path.write_text(scenario["requirement"] + "\n", encoding="utf-8")
    meta_path = output / "experiment_manifest.json"
    meta_path.write_text(json.dumps({
        "scenario_id": scenario["id"],
        "source_repo": "rahulrtk74747474-glitch/Data_career",
        "mirofish_repo": "666ghj/MiroFish",
        "status": "not_run",
        "method": "synthetic social-agent simulation, not real product testing",
        "seed_filename": seed_path.name,
        "requirement_filename": requirement_path.name,
        "hypotheses": scenario["hypotheses"],
        "real_world_falsifiers": scenario["falsifiers"],
        "real_user_test": scenario["real_test"],
    }, indent=2) + "\n", encoding="utf-8")
    return seed_path, requirement_path


class MiroFishClient:
    def __init__(self, base_url: str):
        # Avoid accidentally sending product material to an arbitrary cloud host.
        u = urllib.parse.urlsplit(base_url)
        if u.scheme != "http" or u.hostname not in ("localhost", "127.0.0.1"):
            raise ValueError("Only localhost HTTP is supported; run MiroFish locally.")
        self.base = base_url.rstrip("/")

    def _request(self, method: str, path: str, data=None, content_type=None):
        payload = data
        headers = {}
        if isinstance(data, dict):
            payload = json.dumps(data).encode("utf-8")
            headers["Content-Type"] = "application/json"
        elif content_type:
            headers["Content-Type"] = content_type
        req = urllib.request.Request(self.base + path, data=payload,
                                     method=method, headers=headers)
        try:
            with urllib.request.urlopen(req, timeout=90) as response:
                body = json.loads(response.read().decode("utf-8"))
        except urllib.error.HTTPError as exc:
            # Do not echo response bodies that could contain echoed seed text.
            raise RuntimeError("MiroFish returned HTTP " + str(exc.code) +
                               " for " + path.split("?")[0]) from exc
        except urllib.error.URLError as exc:
            raise RuntimeError("Cannot connect to local MiroFish at " +
                               self.base + "; start it before running.") from exc
        if not body.get("success", False):
            raise RuntimeError("MiroFish operation failed at " + path +
                               " (inspect server logs for details)")
        return body.get("data", {})

    def get(self, path):
        return self._request("GET", path)

    def post(self, path, data):
        return self._request("POST", path, data=data)

    def upload(self, seed_path: Path, requirement: str, name: str):
        boundary = "DQ_MIRO_" + uuid.uuid4().hex
        def field(k, v):
            return (("--" + boundary + "\r\n" +
                     'Content-Disposition: form-data; name="' + k + '"\r\n\r\n' +
                     v + "\r\n").encode("utf-8"))
        chunks = [field("simulation_requirement", requirement),
                  field("project_name", name)]
        chunks.append(("--" + boundary + "\r\n"
                       'Content-Disposition: form-data; name="files"; filename="' +
                       seed_path.name + '"\r\n'
                       "Content-Type: text/markdown\r\n\r\n").encode("utf-8"))
        chunks.append(seed_path.read_bytes())
        chunks.append(b"\r\n")
        chunks.append(("--" + boundary + "--\r\n").encode("utf-8"))
        return self._request("POST", "/api/graph/ontology/generate",
                             data=b"".join(chunks),
                             content_type="multipart/form-data; boundary=" + boundary)


def wait_for(check, label: str, max_minutes: int, interval: int = 8):
    deadline = time.monotonic() + max_minutes * 60
    last = ""
    while time.monotonic() < deadline:
        state = check()
        status = str(state.get("status", state.get("runner_status", ""))).lower()
        if status != last:
            print(label + ": " + status, flush=True)
            last = status
        if status in ("completed", "ready"):
            return state
        if status in ("failed", "stopped", "error"):
            raise RuntimeError(label + " stopped unsuccessfully; examine local server logs.")
        time.sleep(interval)
    raise TimeoutError(label + " exceeded polling timeout. MiroFish may continue running.")


def simulate(client: MiroFishClient, seed_path: Path, scenario: dict,
             out_dir: Path, max_minutes: int, max_rounds: int):
    """Follows the public MiroFish HTTP workflow. Each call is opt-in."""
    result = client.upload(seed_path, scenario["requirement"],
                           "DataQuest " + scenario["id"])
    project_id = result["project_id"]
    print("Ontology generated; project:", project_id, flush=True)

    task = client.post("/api/graph/build", {"project_id": project_id})
    wait_for(lambda: client.get("/api/graph/task/" + task["task_id"]),
             "Knowledge graph", max_minutes)
    project = client.get("/api/graph/project/" + project_id)
    graph_id = project.get("graph_id")
    if not graph_id:
        raise RuntimeError("Graph build finished but project has no graph_id.")

    simulation = client.post("/api/simulation/create", {
        "project_id": project_id, "graph_id": graph_id,
        "enable_twitter": True, "enable_reddit": True})
    simulation_id = simulation["simulation_id"]
    prep = client.post("/api/simulation/prepare", {
        "simulation_id": simulation_id, "use_llm_for_profiles": True,
        "parallel_profile_count": 2})
    if prep.get("status") != "ready":
        prep_task = prep.get("task_id")
        if not prep_task:
            raise RuntimeError("Prepare did not return a task_id.")
        wait_for(lambda: client.post("/api/simulation/prepare/status", {
            "task_id": prep_task, "simulation_id": simulation_id}),
            "Agent preparation", max_minutes)

    client.post("/api/simulation/start", {
        "simulation_id": simulation_id, "platform": "parallel",
        "max_rounds": max_rounds, "enable_graph_memory_update": False})
    wait_for(lambda: client.get("/api/simulation/" + simulation_id +
                                "/run-status"), "Simulation", max_minutes)
    report_job = client.post("/api/report/generate", {
        "simulation_id": simulation_id})
    report_task = report_job.get("task_id")
    if not report_task:
        raise RuntimeError("Report service did not return task_id.")
    done = wait_for(lambda: client.post("/api/report/generate/status", {
        "task_id": report_task, "simulation_id": simulation_id}),
        "AI report", max_minutes)
    report_id = done.get("report_id")
    if not report_id:
        info = client.get("/api/report/by-simulation/" + simulation_id)
    else:
        info = client.get("/api/report/" + report_id)
    text = info.get("markdown_content", "")
    if not text:
        raise RuntimeError("No report text returned; inspect the MiroFish web UI.")

    out_dir.mkdir(parents=True, exist_ok=True)
    (out_dir / "mirofish_simulation_report.md").write_text(
        "# UNVALIDATED SYNTHETIC MIROFISH OUTPUT\n\n"
        "**This is generated agent dialogue, not measured app success, forecast "
        "or actual customer research.**\n\n" + text, encoding="utf-8")
    (out_dir / "simulation_run_metadata.json").write_text(json.dumps({
        "scenario_id": scenario["id"], "project_id": project_id,
        "simulation_id": simulation_id, "report_id": report_id,
        "rounds_requested": max_rounds,
        "evidence_level": "hypothetical synthetic simulation, not observational",
        "human_beta_validated": False,
    }, indent=2) + "\n", encoding="utf-8")
    print("Synthetic report created:", out_dir, flush=True)


def main(argv=None):
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("action", choices=["check", "prepare", "run"])
    p.add_argument("--scenario", default="baseline",
                   choices=["baseline", "evidence_first", "growth_first"])
    p.add_argument("--output", default="mirofish_local_outputs")
    p.add_argument("--url", default="http://127.0.0.1:5001")
    p.add_argument("--rounds", type=int, default=8)
    p.add_argument("--max-minutes", type=int, default=40)
    p.add_argument("--allow-cloud-processing", action="store_true",
                   help="Explicitly acknowledge that MiroFish transmits uploaded "
                        "seed text to configured LLM and Zep Cloud services.")
    args = p.parse_args(argv)
    payload = load_scenarios()
    if args.action == "check":
        print("PASS: scenario schema, checked-in evidence references and seed format")
        print("Status: NOT RUN. No external LLM or Zep API calls made.")
        return 0
    item = select_scenario(payload, args.scenario)
    out_dir = Path(args.output)
    seed_file, requirement_file = prepare(item, out_dir)
    print("Prepared:", seed_file, "and", requirement_file)
    if args.action == "prepare":
        print("NOT RUN. Upload the .md file in local MiroFish and paste the requirement.")
        return 0
    if not args.allow_cloud_processing:
        p.error("--run requires --allow-cloud-processing")
    if not (1 <= args.rounds <= 20):
        p.error("--rounds must be between 1 and 20")
    if not (1 <= args.max_minutes <= 120):
        p.error("--max-minutes must be between 1 and 120")
    client = MiroFishClient(args.url)
    simulate(client, seed_file, item, out_dir, args.max_minutes, args.rounds)
    return 0


if __name__ == "__main__":
    sys.exit(main())
