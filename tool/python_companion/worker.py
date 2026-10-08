"""Isolated learner-code worker; only execute inside restricted Docker."""
import ast
import contextlib
import io
import json
import sys
import pandas as pd

def main():
    data = json.loads(sys.stdin.read(65536))
    code = data["code"]
    records = data["rows"]
    if not isinstance(code, str) or len(code) > 8000:
        raise ValueError("Code must be shorter than 8 KB.")
    if not isinstance(records, list) or len(records) > 500:
        raise ValueError("No more than 500 synthetic rows.")
    tree = ast.parse(code, mode="exec")
    if len(tree.body) > 30:
        raise ValueError("Use at most 30 statements.")
    if tree.body and isinstance(tree.body[-1], ast.Expr):
        tree.body[-1] = ast.Assign(
            targets=[ast.Name(id="result", ctx=ast.Store())],
            value=tree.body[-1].value,
        )
        ast.fix_missing_locations(tree)
    context = {"pd": pd, "df": pd.DataFrame(records)}
    # The security boundary is the Docker process, NOT the Python globals.
    with contextlib.redirect_stdout(io.StringIO()):
        exec(compile(tree, "<dataquest>", "exec"), context)
    answer = context.get("result", context["df"])
    if isinstance(answer, pd.Series):
        answer = answer.reset_index()
    if isinstance(answer, pd.DataFrame):
        answer = answer.reset_index(drop=True)
        answer = json.loads(answer.to_json(orient="records", date_format="iso"))
    elif isinstance(answer, (float, int, str, bool)):
        answer = [{"result": answer}]
    else:
        raise ValueError("Result must be a DataFrame, Series or scalar.")
    if len(answer) > 100:
        raise ValueError("Too many rows; filter or aggregate first.")
    print(json.dumps({"rows": answer}, allow_nan=False))

if __name__ == "__main__":
    try:
        main()
    except Exception as exc:
        print(json.dumps({"error": type(exc).__name__ + ": " + str(exc)[:300]}))
        sys.exit(2)
