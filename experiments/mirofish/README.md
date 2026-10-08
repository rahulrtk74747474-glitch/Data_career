# MiroFish external simulation experiment — DataQuest

This is an **isolated experiment**, not a Flutter plugin and not a dependency of the Android app. It uses the open-source [666ghj/MiroFish](https://github.com/666ghj/MiroFish) service as a hypothetical social simulation tool. MiroFish is licensed **AGPL-3.0**; no MiroFish source code is copied into DataQuest. Assess license obligations separately if you plan to redistribute or operate a modified engine commercially.

## Files
- `dataquest_seed.md` — grounded product facts and **synthetic** learner, recruiter and educator personas.
- `scenarios.json` — three contrasting hypotheses and real-world falsifiers.
- `ASSESSMENT.md` — current engineering + educational + commercial feasibility verdict.
- `tool/mirofish_viability.py` — offline pack validator, scenario exporter and optional local-only API runner.
- `test_mirofish_viability.py` — offline tests with a fake MiroFish client; fake interactions are **not** a real run.
- `RESULT_STATUS.json` — explicit non-execution marker until an audited run is available.

## Verified upstream API compatibility
MiroFish source revision `7657031ac01184afe2cb220f5ee3545573b5e843` (2026-10-01):
- `backend/app/utils/file_parser.py` accepts Markdown, PDF or TXT seed files.
- `backend/app/api/graph.py` handles `POST /api/graph/ontology/generate`, `POST /api/graph/build`, graph tasks.
- `backend/app/api/simulation.py` handles create, prepare, start, run-status.
- `backend/app/api/report.py` handles report generation and retrieval.
- Requires separate **LLM_API_KEY**, **ZEP_API_KEY** and cloud API quotas.
- OASIS agent network uses simulated Twitter/Reddit-style interactions, NOT actual Android workday journeys.

## Safe local usage
Run inside this DataQuest experiment branch:

```sh
python3 tool/mirofish_viability.py check
python3 -m unittest -v test_mirofish_viability.py
python3 tool/mirofish_viability.py prepare --scenario baseline
```

`prepare` generates `mirofish_local_outputs/dataquest_baseline_mirofish_seed.md`,
`simulation_requirement.txt`, and `experiment_manifest.json`. You can upload the `.md` file and paste the requirement into the MiroFish UI manually.

To run MiroFish on your OWN computer/service, separately:

```sh
git clone https://github.com/666ghj/MiroFish.git
cd MiroFish
git checkout 7657031ac01184afe2cb220f5ee3545573b5e843
cp .env.example .env
# Edit .env locally with your own real LLM_API_KEY and ZEP_API_KEY.
# Never commit .env or the API keys to DataQuest/GitHub.
npm run setup:all
npm run dev
```

MiroFish requires Python 3.11–3.12, Node >= 18 and `uv`. Its README also supports `docker compose up -d` after configuring `.env`. API server is at `http://127.0.0.1:5001`. The API itself sends uploaded seed data to configured LLM and Zep services.

Return to the DataQuest checkout and run **only if you explicitly accept external cloud processing and possible API charges**:

```sh
python3 tool/mirofish_viability.py run --scenario baseline \
  --url http://127.0.0.1:5001 \
  --rounds 8 --max-minutes 40 --allow-cloud-processing
```

Repeat for `--scenario evidence_first` and `--scenario growth_first`, each with **a different --output directory** to avoid overwriting local results. When successful, the runner saves a report headed `UNVALIDATED SYNTHETIC MIROFISH OUTPUT` and metadata. The simulation can fail because the external LLM, Zep graph, profiles or report agent may not converge; consult local server logs. The integration protocol is checked with stubs, but **has not been end-to-end exercised against a live external MiroFish server**.

## Compare results responsibly
Use simulated responses to identify objections, competing views, sensitivity to claims, and questions to ask real users. Never translate agent sentiment into predicted installs, D7 retention, job placements, or subscription sales. Final product decisions require actual consented learner and hiring-manager evidence.

## Data privacy
Seed pack is deliberately public/product-level plus fictional characters only. Do NOT add accounts, private code, chat transcripts, learner records, emails, phone numbers or actual identifiable people. Outputs and `.env` are never committed.

## Versioning and validation
CI runs `python -m unittest` and `python tool/mirofish_viability.py check` with no cloud keys. It also prepares a scenario pack for review. This checks the **research integration and packaging**, not market demand or agent behavior. Existing Flutter CI remains authoritative for app compilability.
