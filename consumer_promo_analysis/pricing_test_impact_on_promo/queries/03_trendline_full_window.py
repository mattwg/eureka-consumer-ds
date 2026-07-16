# Query 3 plotting logic — pair with 03_trendline_full_window.sql.
# Dual-axis chart: Cash (lines) + Users (bars), one subplot per arm (Control, Test),
# Early Bird shaded. This is the ORIGINAL dual-axis pattern from the live analysis —
# a later iteration (see the promo-only single-axis charts built later in this project)
# split Cash and Users into two separate single-axis line charts instead, since dual
# y-axis charts make trend comparisons harder to read. Prefer that split version for
# new work; keep this one for the specific "full pricing-test-to-promo-end" directional
# view described in SKILL.md Section 3, Query 3.

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

df = spark.sql(query).toPandas()
df["transaction_dt"] = pd.to_datetime(df["transaction_dt"])
df["cash"] = df["cash"].astype(float)
df["users"] = df["users"].astype(float)

dates = pd.to_datetime(sorted(df["transaction_dt"].unique()))   # DatetimeIndex, not raw np.datetime64
x = np.arange(len(dates))
arms = ["Control", "Test"]
promos = ["Promo", "Non-promo"]
width = 0.8 / len(promos)
LBL_STEP = 3

# pivot once, reindex onto the full date axis
cash_p = (df.pivot_table(index="transaction_dt", columns=["arm", "promo_status"],
                         values="cash", aggfunc="sum").reindex(dates))
user_p = (df.pivot_table(index="transaction_dt", columns=["arm", "promo_status"],
                         values="users", aggfunc="sum").reindex(dates))

eb = [i for i, d in enumerate(dates)
      if pd.Timestamp("2026-06-08") <= d <= pd.Timestamp("2026-06-17")]

fig, axes = plt.subplots(2, 1, figsize=(24, 15))
lbl_bbox = dict(boxstyle="round,pad=0.15", fc="white", ec="none", alpha=0.75)

for ax_bar, arm in zip(axes, arms):
    ax_line = ax_bar.twinx()
    if eb:
        ax_bar.axvspan(min(eb) - 0.5, max(eb) + 0.5, color="grey", alpha=0.15, label="Early bird (Jun 8-17)")
    for i, promo in enumerate(promos):
        col = (arm, promo)
        cash_vals = cash_p[col].values if col in cash_p.columns else np.full(len(dates), np.nan)
        user_vals = user_p[col].values if col in user_p.columns else np.full(len(dates), np.nan)
        xpos = x + (i - (len(promos) - 1) / 2) * width

        ax_bar.bar(xpos, np.nan_to_num(user_vals), width=width, alpha=0.45, label=f"{promo} (users)")
        line, = ax_line.plot(x, cash_vals, marker="o", ms=4, lw=1.6, label=f"{promo} (cash)")

        for j in range(len(dates)):
            if j % LBL_STEP == 0:
                uv, cv = user_vals[j], cash_vals[j]
                if pd.notna(uv) and uv > 0:
                    ax_bar.annotate(f"{int(uv)}", (xpos[j], uv), textcoords="offset points",
                                    xytext=(0, 6), ha="center", va="bottom", fontsize=7, rotation=90)
                if pd.notna(cv) and cv > 0:
                    ax_line.annotate(f"{cv/1000:.0f}k", (x[j], cv), textcoords="offset points",
                                     xytext=(0, 11), ha="center", fontsize=7,
                                     color=line.get_color(), bbox=lbl_bbox)

    ax_bar.set_title(f"C+ Annual — {arm}", fontsize=14, pad=14)
    ax_bar.set_ylabel("Daily users", fontsize=11)
    ax_line.set_ylabel("Daily cash (USD)", fontsize=11)
    ax_bar.set_ylim(0, np.nanmax(np.nan_to_num(user_p.values)) * 1.45)
    ax_line.set_ylim(0, np.nanmax(np.nan_to_num(cash_p.values)) * 1.45)
    ax_bar.set_xticks(x[::LBL_STEP])
    ax_bar.set_xticklabels([dates[k].strftime("%b %d") for k in range(0, len(dates), LBL_STEP)],
                           rotation=45, ha="right", fontsize=9)
    ax_line.legend(loc="upper left", fontsize=9, title="Cash")
    ax_bar.legend(loc="upper right", fontsize=9, title="Users")

fig.suptitle("C+ Annual daily cash (lines) and users (bars) from Apr 28, by experiment arm", fontsize=16, y=1.0)
plt.tight_layout(h_pad=5)
plt.show()
