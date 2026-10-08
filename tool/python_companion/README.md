# Optional real Python / Pandas companion

This is a separate desktop/local development companion with genuine Pandas.
It does not embed Python into the offline Android app.

Prerequisites: local Docker Engine and Python 3.11+.

From repository root:

    docker build -t dataquest-pandas-runner:local tool/python_companion
    python3 tool/python_companion/server.py

The service binds only to 127.0.0.1:8765. To run an exercise directly:

    curl -X POST http://127.0.0.1:8765/run -H 'Content-Type: application/json' -d '{"code":"df.groupby(\"segment\")[\"sales\"].sum()","rows":[{"segment":"A","sales":2},{"segment":"A","sales":3}]}'

The worker executes submitted code inside a fresh Docker container with
network disabled, non-root identity, no Linux capabilities, read-only root
filesystem, capped CPU/RAM/processes and a wall-time limit. This reduces
risk but is not a formal security guarantee. Do not expose this service to
the internet or process personally identifiable data.

Python output is actual Pandas output. It is not sufficient by itself
to verify independent job competence; multiple hidden datasets and expert
review are still needed. Android lab still has a simulator as offline fallback.
