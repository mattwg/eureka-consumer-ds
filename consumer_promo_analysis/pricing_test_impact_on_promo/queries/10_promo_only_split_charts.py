# Query 10 plotting logic — pair with 10_promo_only_split_charts.sql.
# Two separate single-axis line charts (Cash-only, Users-only), 2 lines each
# (Control, Test), filtered to promo_status == "Promo" only, Early Bird shaded.
# This is the preferred default going forward over Query 3's dual-axis combo chart
# — a dual y-axis makes trend comparisons harder to read correctly.
#
# Note: filtering to promo_status == "Promo" means dates before the promo starts
# (2026-06-08) have no rows at all, so the x-axis here naturally starts at the
# promo start, not the pricing-test start — see SKILL.md Section 3, Query 10 for
# the "why is pre-promo missing" discussion and the alternate fix (hardcoding the
# x-axis start to the pricing-test date, which leaves a blank lead-in instead).

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

df = spark.sql(query).toPandas()
df["transaction_dt"] = pd.to_datetime(df["transaction_dt"])
df["cash"] = df["cash"].astype(float)
df["users"] = df["users"].astype(float)

df_promo = df[df["promo_status"] == "Promo"].copy()

dates = pd.date_range(df_promo["transaction_dt"].min(), df_promo["transaction_dt"].max(), freq="D")
x = np.arange(len(dates))

cash_p = df_promo.pivot_table(index="transaction_dt", columns="arm", values="cash", aggfunc="sum").reindex(dates)
user_p = df_promo.pivot_table(index="transaction_dt", columns="arm", values="users", aggfunc="sum").reindex(dates)

eb_idx = [i for i, d in enumerate(dates) if pd.Timestamp("2026-06-08") <= d <= pd.Timestamp("2026-06-17")]

COLORS = {"Control": "#2a78d6", "Test": "#1baf7a"}  # fixed categorical order, consistent across both charts
LBL_STEP = 3
lbl_bbox = dict(boxstyle="round,pad=0.15", fc="white", ec="none", alpha=0.75)

def plot_metric(data_p, ylabel, title, value_fmt):
    fig, ax = plt.subplots(figsize=(14, 6))
    if eb_idx:
        ax.axvspan(min(eb_idx) - 0.5, max(eb_idx) + 0.5, color="grey", alpha=0.15, label="Early Bird (Jun 8-17)")
    for arm in ["Control", "Test"]:
        vals = data_p[arm].values if arm in data_p.columns else np.full(len(dates), np.nan)
        line, = ax.plot(x, vals, marker="o", ms=4, lw=2, color=COLORS[arm], label=arm)
        for j in range(len(dates)):
            if j % LBL_STEP == 0 and pd.notna(vals[j]):
                ax.annotate(value_fmt(vals[j]), (x[j], vals[j]), textcoords="offset points",
                            xytext=(0, 8), ha="center", fontsize=7, color=line.get_color(), bbox=lbl_bbox)
    ax.set_title(title, fontsize=14, pad=12)
    ax.set_ylabel(ylabel, fontsize=11)
    ax.set_xticks(x[::LBL_STEP])
    ax.set_xticklabels([dates[k].strftime("%b %d") for k in range(0, len(dates), LBL_STEP)], rotation=45, ha="right", fontsize=9)
    ax.legend(loc="upper left", fontsize=9, frameon=False)
    ax.spines[["top", "right"]].set_visible(False)
    plt.tight_layout()
    plt.show()

plot_metric(cash_p, "Daily promo cash (USD)", "C+ Annual — Daily Promo Cash, Test vs Control", lambda v: f"${v/1000:.0f}k")
plot_metric(user_p, "Daily promo users", "C+ Annual — Daily Promo Users, Test vs Control", lambda v: f"{int(v)}")
