#!/usr/bin/env python3
"""Validate a fresh q008 run against the frozen golden METHOD.

Method-only check (per evals/README.md): we assert the run follows the frozen approach --
right table, right renewal signal, right filters, right steps -- NOT an exact number.
A optional numeric guard-band (off by default) catches gross right-method-wrong-number bugs.

Usage:
    python validate.py <run_dir>
        run_dir must contain query.sql (and result.csv if the guard-band is on).

Exit code 0 = pass, 1 = fail. Prints a short reason either way.
Stdlib only, so CI can run it with a bare Python.
"""
import csv
import os
import re
import sys

try:
    import yaml  # optional; we fall back to a tiny parser if unavailable
except ImportError:
    yaml = None

HERE = os.path.dirname(os.path.abspath(__file__))
GOLDEN = os.path.join(HERE, "golden", "method.yaml")

# Method invariants the run's SQL MUST satisfy. (label, regex) -- case-insensitive.
REQUIRED = [
    ("source table prod.bi.base_data_for_ret_cancel",
     r"prod\.bi\.base_data_for_ret_cancel"),
    ("renewal signal next_txn_stamp_sub_level",
     r"next_txn_stamp_sub_level"),
    ("B2C business line filter",
     r"transaction_business_line\s*=\s*'B2C'"),
    ("C Plus monthly product filter",
     r"product_sub_type\s*=\s*'C Plus monthly'"),
    ("7-day eligibility lag",
     r"recurring_payment_end_ts\s*<\s*CURRENT_DATE\(\)\s*-\s*INTERVAL\s*7\s*DAYS"),
    ("M1 step (payment_order = 1)",
     r"payment_order\s*(=\s*1|between\s*1)"),
    ("M2+ step (payment_order >= 2)",
     r"payment_order\s*>=\s*2"),
]

# Must NOT appear: the wrong renewal signal used as the signal.
# (next_txn_stamp_sub_level contains "next_txn_stamp", so match the bare column only.)
FORBIDDEN = [
    ("bare next_txn_stamp used as renewal signal",
     r"next_txn_stamp(?!_sub_level)"),
]


def read_method():
    with open(GOLDEN) as f:
        text = f.read()
    if yaml:
        return yaml.safe_load(text)
    # tiny fallback: we only need numeric_guardband.enabled + m1 range
    enabled = re.search(r"enabled:\s*(true|false)", text)
    rng = re.search(r"m1_blended_pct_range:\s*\[\s*([\d.]+)\s*,\s*([\d.]+)\s*\]", text)
    return {
        "numeric_guardband": {
            "enabled": (enabled.group(1) == "true") if enabled else False,
            "m1_blended_pct_range": [float(rng.group(1)), float(rng.group(2))] if rng else None,
        }
    }


def strip_sql_comments(sql):
    """Drop SQL comments before checking method invariants.

    Comments describe intent ("use next_txn_stamp_sub_level, never next_txn_stamp") and must NOT
    count as executed SQL: otherwise a comment mentioning the WRONG signal false-fails a correct
    query (the bug this fixes), and symmetrically a comment naming a REQUIRED table could
    false-pass a query that never uses it. We strip `/* ... */` blocks and `-- ...` line comments.
    String literals are preserved (the REQUIRED filters match values like 'B2C'); the naive
    line-comment strip could over-cut a literal containing '--', which these metric queries never
    have -- acceptable for this lightweight stdlib checker.
    """
    sql = re.sub(r"/\*.*?\*/", " ", sql, flags=re.DOTALL)   # block comments
    sql = re.sub(r"--[^\n]*", " ", sql)                     # line comments
    return sql


def check_sql(sql):
    problems = []
    low = strip_sql_comments(sql)
    for label, pat in REQUIRED:
        if not re.search(pat, low, re.IGNORECASE):
            problems.append(f"missing: {label}")
    for label, pat in FORBIDDEN:
        if re.search(pat, low, re.IGNORECASE):
            problems.append(f"forbidden: {label}")
    return problems


def check_guardband(run_dir, method):
    gb = (method or {}).get("numeric_guardband") or {}
    if not gb.get("enabled"):
        return []  # guard-band off -> nothing to check
    rng = gb.get("m1_blended_pct_range")
    csv_path = os.path.join(run_dir, "result.csv")
    if not rng or not os.path.exists(csv_path):
        return ["guard-band on but no range or no result.csv to check"]
    lo, hi = rng
    with open(csv_path) as f:
        for row in csv.DictReader(f):
            if row.get("step") == "M1" and "blended" in (row.get("query") or ""):
                val = float(row["renewal_pct"])
                if not (lo <= val <= hi):
                    return [f"M1 blended {val}% outside guard-band [{lo}, {hi}]"]
    return []


def main():
    if len(sys.argv) != 2:
        print("usage: python validate.py <run_dir>")
        return 2
    run_dir = sys.argv[1]
    sql_path = os.path.join(run_dir, "query.sql")
    if not os.path.exists(sql_path):
        print(f"FAIL: no query.sql in {run_dir}")
        return 1
    with open(sql_path) as f:
        sql = f.read()

    method = read_method()
    problems = check_sql(sql) + check_guardband(run_dir, method)

    if problems:
        print("FAIL q008:")
        for p in problems:
            print(f"  - {p}")
        return 1
    print("PASS q008: run follows the frozen method.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
