---
name: high-income-pricing-test-promo-impact
description: >
  DRAFT — description to be finalized once all sections are in. Covers
  analyzing the impact of an A/B pricing test intermingling with a live
  promo, worked through the High Income Pricing Test vs Q2 '26 C+ Annual
  Tentpole Promo case.
---

# High Income Pricing Test — Impact on Q2 '26 C+ Annual Tentpole Promo

## 1. Trigger conditions

This SKILL is created to analyse and understand the impact A/B tests can have on a running promo. We are taking the High Income Pricing test which coincided with our C+Annual promo.

Here, we are laying out the thought process and methodology we used to navigate this situation.

This SKILL should serve as a starting point for developing context on how to go about such situations, how can this problem be broken down into smaller chucks, what metrics and factors to analyse and why, how we calculated and articulated the impact, what nuances were taken care of, what were the learnings, who are the directly impacted stakeholders, etc. In future, we will most likely have new and different tests but with this SKILL, we can get on with the analysis. Most importantly, this SKILL will be quite handy for looking at such inter-mingling effects between promotions & 'pricing tests' in particular.

For starters, proper context should be there for the Test and the Promotion.

### Context for High Income Pricing Test

- High Income Pricing Test was an experiment that was run in 85 selected high income countries.
- A detailed Confluence doc can be found here: Page: [Experiment Plan] Pricing Test for High-income Countries
- This test was designed in such a manner that prices of subscription based products like C+ Monthly and C+ Annual were lowered and prices of Standalone courses or Gateways like products were increased. This was to push users to choose subscription based products over one time products.
- The pricing was also done strategically by playing countries into different buckets where test users would see prices differently compared to what they were accustomed to see. There were 5 primary buckets:
  - Prices higher than the US: 105%
  - Prices similar to the US: 100%
  - Prices 85-99% of the US: 85%
  - Prices 70-84% of the US: 75%
  - Prices below 70% of the US: 70%
- This test was run from 28th April 2026 to 24th June, 2026.
- The key metrics to judge the pricing test performance were: Total Cash, Retention.

### Context on Q2 '26 C+ Annual Tentpole Promo

The Lifecycle Marketing team ran the Q2 '26 C+ Annual Tentpole Promo from 8th June 2026 to 13th July 2026. There was an Early Bird Offer in this promo from 8th June to 17th June where the promotion offer was at 50% off. Post 17th june until the promo end date, this offer ran at 40% off.

This test coincided with the promo from 8th June 2026 to 24th June 2026.

However, the test was running using EPIC and all the users in the population who were impressed with the price they saw during promo (prices were already reduced due to the high income pricing test that were further reduced by the promo) continued to see lesser prices even after the high income pricing test ended. This is because EPIC is "sticky".

In future, similar or other tests will also run but we have to trigger this SKILL whenever we want to understand what kind of impact a test can have on a promo. As much of the nuance as is known is being baked into the SKILL, but new problems and tests will have newer nuances, and that should be taken care of by asking the user beforehand whenever this SKILL is triggered.

## 2. Methodology, step by step

Answering important questions first:

- The test mechanics like splitting between control and test, designing the experiment, identifying the primary, secondary and guardrail metrics and all the experiment related nuances are designed and defined by the Product Managers and Product Data Scientists. Test performance also belongs to the foray of product DS.
- Lifecycle Marketing team orchestrates the promotions and runs them.
- Consumer Strategy DS team which will be the core user of this SKILL. They have performed the analysis on "Effects/Impact of the High Income Pricing Test on the C+ Annual Tentpole Promotion in Q2'26". This is our main problem statement to solve. The final answer we would like to provide is the total impact in terms of cash.

Methodology:

- We limited our analysis to the users who were part of the experiment. We got their categorizations of Control & Test.
- We looked at these users' transactions between their impression start date and end date.
- We based our analysis on 3 metrics: Total User count, Total Cash Count and Cash per user.
- We performed some aggregations to get the sense check on numbers. The aggregation format looks like the table below (template — cells filled in per run):

| arm | period | Cash: promo | Cash: non_promo | Cash: total | Users: promo | Users: non_promo | Users: total | Cash/user: promo | Cash/user: non_promo | Cash/user: total |
|---|---|---|---|---|---|---|---|---|---|---|
| Control | Pre-promo (41 days) | | | | | | | | | |
| Control | During early bird (10 days) | | | | | | | | | |
| Control | After early bird (25 days) | | | | | | | | | |
| Test | Pre-promo (41 days) | | | | | | | | | |
| Test | During early bird (10 days) | | | | | | | | | |
| Test | After early bird (25 days) | | | | | | | | | |

Here, for each control and test group, we looked at 3 different time periods because user behavior would be different across these:

- **Pre-promo:** This was the intended price the Product team wanted the users to see during the experiment.
- **During Early Bird:** Listed price of both Test & Control groups got slashed by 50% during this period. Promotion discount is increased by 10% during early bird period.
- **After Early Bird:** Listed price of both Test & Control groups got slashed by 40% during this period. This was the original promotion discount value.

We also looked at averages during the 3 time periods to assess daily impact, as the time window of each of these 3 periods are different and trailing 3-4 days of promotion period (both during and after Early Bird) come with Urgency messaging and can skew the metrics.

Along with all of these things, we also look at trendlines and graphs:

- **Graph 1:** For both Test & Control groups:
  - Cash and Users graph over the entire time period from when the pricing test started to when the promotion ended — here we can visually see how the impact has changed through these time periods, and this information aids our analysis directionally.
  - This is a dual axis graph with Cash (depicted by Lines) & Users (depicted by bars) and dates on the X axis.
  - Highlight the Early bird time period with a little grey background to make the distinction between the time periods evident.
  - One example graph is attached below: _(see original doc for image)_
- For separate cash & users graph, we plot the line chart for total cash for both test & control users to compare their performance.

Apart from the above, we looked at some more nuances:

- Restricting the data only until 06/24, i.e. the test end period.
- Calculating the averages for each of the metrics in the 3 time periods to assess day level impact.
- Looked at the country level breakdown at the traffic split and transactions split — focussed on top 5 countries.
- As a sense check — check if the traffic split between test and control was 50:50.

To calculate the final impact, we came up with 2 methodologies:

- **Extrapolated:** without the test, we'd expect combined performance to roughly equal control performance × 2, since test and control are equal-sized halves. So the opportunity is calculated as: (Control performance × 2) − (Actual Test + Control performance). This gives us the gap between expected baseline (no test) and actual observed performance — essentially the uplift or shortfall attributable to the test.
- **Actual:** Total Cash Control (EB + Post EB) − Total Cash Test (EB + Post EB).

## 3. Data sources and query patterns

### Query 1 — High Income Pricing Test population (Test/Control + impression window)

Identifies the user base exposed to the High Income Pricing Test — their test/control categorization and impression start ts and end ts.

```sql
WITH variants AS (
  SELECT
    -- Experiment metadata.
    epic_experiment_id
    , epic_experiment_started_at
    , epic_experiment_ended_ts
    , MAX(COALESCE(epic_experiment_ended_ts, CURRENT_DATE)) OVER () AS end_ts
    , epic_experiment_display_name
    -- Variant metadata.
    , epic_variant_id
    , epic_variant_weight
    , TRIM(REGEXP_REPLACE(epic_variant_name, '', '')) AS cleaned_epic_variant_name
    ,
    (MAX(CASE WHEN epic_variant_index = 0 AND epic_experiment_id = 'kEs8FDkHEfGErBK2XQAA3w' THEN 1 ELSE 0 END)
    OVER (PARTITION BY TRIM(REGEXP_REPLACE(epic_variant_name, '', ''))))::BOOLEAN
     AS is_control
    -- Get the order of variants. Order same as EPIC unless control is manually set, in which case control is put first.
    , CASE
    WHEN is_control THEN 1
    ELSE -MIN(epic_variant_index) OVER (PARTITION BY TRIM(REGEXP_REPLACE(epic_variant_name, '', '')))
    END AS sort_by
  FROM prod.bi.epic_variants
  JOIN prod.bi.epic_experiments USING (epic_experiment_id)
  WHERE (
  epic_experiment_id = 'kEs8FDkHEfGErBK2XQAA3w'
  )
  AND epic_experiment_allocation_type = 'BY_USER'
  )

SELECT
  is_control
  , user_id
  -- Get impression start and end timestamps for metrics calculations. This includes users
  , MIN(impression_ts) AS start_ts,
    MAX(end_ts) AS end_ts
FROM prod.bi.epic_user_impressions
JOIN variants USING (epic_experiment_id, epic_variant_id)
WHERE
  impression_dt BETWEEN epic_experiment_started_at::DATE AND COALESCE(epic_experiment_ended_ts::DATE, CURRENT_DATE) -- speeds up the computation
  AND impression_ts BETWEEN epic_experiment_started_at AND COALESCE(epic_experiment_ended_ts, CURRENT_DATE)
  AND 1=1 -- no filter on 'impressions.impression_date'
GROUP BY 1, 2
```

**What this captures:** the reusable `high_pricing_test_users` building block referenced by every downstream query in this analysis. `epic_experiment_id = 'kEs8FDkHEfGErBK2XQAA3w'` pins it to this specific test. `is_control` is derived from `epic_variant_index = 0` on the matching experiment, not from the variant name. `end_ts` is a global constant (`MAX(...) OVER ()` with no partition) — see the pitfall on EPIC stickiness in Section 5 and the caveat below.

**Caveat carried over from chart validation:** because `end_ts` is computed with no `PARTITION BY`, it's the same value for every row (effectively the experiment's official end, or `CURRENT_DATE` if still running) — not a per-user sticky window. Downstream joins that bound transactions to `BETWEEN start_ts AND end_ts` will stop tagging users as Test/Control once that global end date passes, even though EPIC pricing may still be "sticky" for those users in reality. Confirm this is the intended interpretation before trusting Test/Control tagging for any date range extending past the test's official end.

### Query 2 — Base skeleton: marrying test users with transaction data

Sample skeleton query for marrying the test users (Query 1) with transaction data, looking at their transactions from a start date until `today - 2`. **The date bounds in the final `WHERE` change per use case** (promo start, test start, etc.) — the reusable part is the joins and logic below.

```sql
with domain as (
    select distinct
        coalesce(c.course_slug,ps.phoenix_specialization_slug) as product_slug
        ,upp.underlying_product_item_id
        ,coalesce(course_primary_domain,phoenix_specialization_primary_domain) as primary_domain
    from prod.bi.underlying_products_partners upp
    left join prod.gold.courses_vw c
        on c.course_id = upp.underlying_product_item_id
    left join prod.gold.phoenix_specializations_vw ps
        on ps.phoenix_specialization_id = upp.underlying_product_item_id
),
high_pricing_test_users AS (
      -- Query 1 above
      ...
)
SELECT * FROM (
SELECT
    CAST(COALESCE(CAST(hpt.is_control AS STRING),'non-high_pricing_test_population') AS STRING) AS hpt_flag,
    ab.*,
    hpt.start_ts AS hpt_start_ts,
    hpt.end_ts AS hpt_end_ts,
    b.country_group_finance,
    COALESCE(b1.product_sub_type, ab.underlying_product_type) AS product_sub_type,
    d.is_cplus_upsell,
    DATE(ab.transaction_ts) AS transaction_dt,
    a.payment_order,
    recurring_payment_start_ts,
    recurring_payment_end_ts,
    a.subscription_id,
    a.subscription_status,
    a.is_subscription_active,
    cc1.promotion_name,
    cc1.promotion_id,
    CASE WHEN cc1.promotion_id IN (287767, 287768, 287769, 287771, 287775) THEN 1 ELSE 0 END AS Q2_2026_Tentpole_promo_flag,
    subscription_cancel_ts,
    subscription_inactivation_ts,
    f.country_cd,
    CASE
        WHEN primary_domain IS NULL THEN 'Others'
        ELSE primary_domain
    END AS primary_domain,
    COALESCE(subscription_cancel_ts, subscription_inactivation_ts) AS subscription_end_ts,
    ROW_NUMBER() OVER (PARTITION BY ab.transaction_id ORDER BY ab.transaction_ts ASC) AS rn1
FROM prod.gold.transactions_vw ab
LEFT JOIN prod.gold.completed_carts_vw cc1
    ON ab.user_id = cc1.user_id
    AND ab.cart_id = cc1.cart_id
LEFT JOIN prod.gold.users_vw f
    ON ab.user_id = f.user_id
LEFT JOIN prod.silver_base.static_countries b
    ON f.country_cd = b.country_cd
LEFT JOIN prod.bi.subscription_payments a
    ON a.user_id = ab.user_id
    AND a.transaction_id = ab.transaction_id
LEFT JOIN prod.bi.subscriptions bs
    ON a.user_id = bs.user_id
    AND a.subscription_id = bs.subscription_id
LEFT JOIN prod.bi.subscriptions__payment_stats d
    ON a.user_id = d.user_id
    AND a.subscription_id = d.subscription_id
LEFT JOIN domain pt
    ON a.underlying_product_item_id = pt.underlying_product_item_id
LEFT JOIN prod.bi.products_detail b1
    ON ab.product_item_id = b1.product_item_id
    AND ab.product_type = b1.product_type
LEFT JOIN high_pricing_test_users hpt ON ab.user_id = hpt.user_id AND ab.transaction_ts between hpt.start_ts AND hpt.end_ts
WHERE transaction_type = 'BUY'
    AND NOT was_buy_transaction_refunded
    AND transaction_business_line = 'B2C'
    AND DATE(ab.transaction_ts) <= CURRENT_DATE - 2
    AND DATE(ab.transaction_ts) >= (CAST(DATE_FORMAT(CAST('<start_date>' AS DATE), 'yyyy-MM-dd') AS DATE)))
    WHERE rn1=1
```

**What each join is doing:**
- `transactions_vw ab` (base fact table) → `completed_carts_vw cc1` on `user_id + cart_id`: pulls `promotion_name`/`promotion_id` so a transaction can be flagged as belonging to the Q2 '26 Tentpole promo (hardcoded `promotion_id` list — swap per promo).
- → `users_vw f` on `user_id` → `static_countries b` on `country_cd`: attaches `country_group_finance` (finance region rollup).
- → `subscription_payments a` on `user_id + transaction_id`: subscription-level payment attributes — `payment_order`, `recurring_payment_start/end_ts`, `subscription_id`, `subscription_status`, `is_subscription_active`.
- → `subscriptions bs` on `user_id + subscription_id`: joined but no column from it is currently selected — worth checking if this is a dead join before reusing the skeleton.
- → `subscriptions__payment_stats d` on `user_id + subscription_id`: `is_cplus_upsell` flag.
- → `domain pt` on `underlying_product_item_id`: course/specialization primary domain, coalesced to `'Others'` when null.
- → `products_detail b1` on `product_item_id + product_type`: `product_sub_type` (e.g. `'C Plus annual'`), falling back to `ab.underlying_product_type` when missing.
- → `high_pricing_test_users hpt` on `user_id` **and** `transaction_ts BETWEEN hpt.start_ts AND hpt.end_ts`: the tagging join — this is what assigns `hpt_flag` (`'true'`/`'false'`/`'non-high_pricing_test_population'`), and it's the join subject to the `end_ts` stickiness caveat from Query 1.

**Filters:** `transaction_type = 'BUY'`, non-refunded, B2C only, upper bound `CURRENT_DATE - 2` (avoids partial/lagged latest days), lower bound is the use-case-specific start date (test start, promo start, etc — parameterize this).

**Dedup:** `ROW_NUMBER() OVER (PARTITION BY transaction_id ORDER BY transaction_ts ASC)` filtered to `rn1 = 1` in the outer query — guards against row fanout from the joins (a transaction matching more than one row in `completed_carts_vw` or `subscription_payments`, for instance).

### Query 3 — Trendline graph: Control & Test, Cash and Users, pricing-test-start through promo-end

This is **Graph 1** from Section 2's methodology — Cash (lines) and Users (bars) on a dual axis, one subplot per arm (Control, Test), Early Bird shaded, x-axis running from the beginning of the pricing test to the end of the promo. Purpose: see how these users performed *before* the promo kicked in and across the different phases of the promo. **Dates are use-case specific** — swap the pricing-test-start / promo-end bounds and the Early Bird highlight window per analysis.

Builds directly on Query 2's skeleton (`domain`, `high_pricing_test_users`, `base`), adding:
- `cplus_annual`: filters `base` down to `product_sub_type = 'C Plus annual'` AND `hpt_flag IN ('true', 'false')` — i.e. drops the `'non-high_pricing_test_population'` bucket, keeping only users tagged Test or Control.
- Final `SELECT`: aggregates to `(transaction_dt, arm, promo_status)` grain — `arm` from `hpt_flag` (`'true'` → Control, else → Test), `promo_status` from whether `promotion_id` is set **and** it's one of the Q2 '26 Tentpole promo IDs.

```sql
WITH domain AS (
    SELECT DISTINCT
        COALESCE(c.course_slug, ps.phoenix_specialization_slug) AS product_slug,
        upp.underlying_product_item_id,
        COALESCE(course_primary_domain, phoenix_specialization_primary_domain) AS primary_domain
    FROM prod.bi.underlying_products_partners upp
    LEFT JOIN prod.gold.courses_vw c
        ON c.course_id = upp.underlying_product_item_id
    LEFT JOIN prod.gold.phoenix_specializations_vw ps
        ON ps.phoenix_specialization_id = upp.underlying_product_item_id
),
high_pricing_test_users AS (
      -- Query 1 above
      ...
),
base AS (
  SELECT * FROM (
    -- Query 2 above
    ...
  )
  WHERE rn1 = 1
),
cplus_annual AS (
  SELECT * FROM base
  WHERE product_sub_type = 'C Plus annual'
    AND hpt_flag IN ('true', 'false')
)
SELECT
  transaction_dt,
  CASE WHEN hpt_flag = 'true' THEN 'Control' ELSE 'Test' END AS arm,
  CASE WHEN promotion_id IS NOT NULL AND Q2_2026_Tentpole_promo_flag = 1 THEN 'Promo' ELSE 'Non-promo' END AS promo_status,
  ROUND(SUM(cash_receipt_usd_estimate), 2) AS cash,
  COUNT(DISTINCT user_id) AS users
FROM cplus_annual
GROUP BY 1, 2, 3
ORDER BY transaction_dt, arm, promo_status
```

```python
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
```

**Note on chart form:** this dual-axis (Cash-lines + Users-bars sharing one plot) version is the original pattern used during the live analysis. A later iteration of this work split Cash and Users into two separate single-axis line charts, Test vs Control, restricted to promo-only cash/users — since a dual y-axis chart makes trend comparisons harder to read correctly. Consider that split version as the preferred default going forward; keep this dual-axis version for the specific "full pricing-test-to-promo-end" directional view described above.

### Query 4 — Overall impact table: Cash, Users, Cash/User by Promo/Non-promo/Total × 3 periods × arm

This is the query that powers the Section 4 output-contract table and the final USD impact calculation. Grain: `(arm, period)`, where `arm` ∈ {Control, Test} and `period` ∈ {Pre-promo, During early bird, After early bird}. For each combination it produces promo / non-promo / total cuts of Cash, Users, and Cash/User.

Builds on the same `domain`, `high_pricing_test_users`, `base` CTEs as Queries 2–3:

```sql
WITH domain AS ( ... ),          -- Query 1 above
high_pricing_test_users AS ( ... ),  -- Query 1 above
base AS (
  SELECT * FROM ( ... )          -- Query 2 above
  WHERE rn1 = 1
),
cplus_annual AS (
  SELECT *
  FROM base
  WHERE product_sub_type = 'C Plus annual'
    AND hpt_flag IN ('true', 'false')      -- experiment population only
)
SELECT
  CASE WHEN hpt_flag = 'true' THEN 'Control' ELSE 'Test' END AS arm,
  CASE
    WHEN transaction_dt < DATE'2026-06-08' THEN 'Pre-promo'
    WHEN transaction_dt BETWEEN DATE'2026-06-08' AND DATE'2026-06-17' THEN 'During early bird'
    ELSE 'After early bird'
  END AS period,
  -- Cash
  ROUND(SUM(CASE WHEN Q2_2026_Tentpole_promo_flag = 1 THEN cash_receipt_usd_estimate ELSE 0 END),2) AS promo_cash,
  ROUND(SUM(CASE WHEN Q2_2026_Tentpole_promo_flag = 0 THEN cash_receipt_usd_estimate ELSE 0 END),2) AS non_promo_cash,
  ROUND(SUM(cash_receipt_usd_estimate),2) AS total_cash,
  -- Users
  COUNT(DISTINCT CASE WHEN Q2_2026_Tentpole_promo_flag = 1 THEN user_id END) AS promo_users,
  COUNT(DISTINCT CASE WHEN Q2_2026_Tentpole_promo_flag = 0 THEN user_id END) AS non_promo_users,
  COUNT(DISTINCT user_id) AS total_users,
  -- Cash per user
  ROUND(SUM(CASE WHEN Q2_2026_Tentpole_promo_flag = 1 THEN cash_receipt_usd_estimate ELSE 0 END)
        / NULLIF(COUNT(DISTINCT CASE WHEN Q2_2026_Tentpole_promo_flag = 1 THEN user_id END),0),2) AS promo_cash_per_user,
  ROUND(SUM(CASE WHEN Q2_2026_Tentpole_promo_flag = 0 THEN cash_receipt_usd_estimate ELSE 0 END)
        / NULLIF(COUNT(DISTINCT CASE WHEN Q2_2026_Tentpole_promo_flag = 0 THEN user_id END),0),2) AS non_promo_cash_per_user,
  ROUND(SUM(cash_receipt_usd_estimate) / NULLIF(COUNT(DISTINCT user_id),0),2) AS total_cash_per_user
FROM cplus_annual
GROUP BY 1, 2
ORDER BY arm, MIN(transaction_dt);
```

**Joins:** unchanged from Query 2 — this query doesn't add any new joins, it re-aggregates `base`/`cplus_annual` at a coarser grain.

**Calculation logic:**
- `period` is a hardcoded `CASE` on `transaction_dt` against the Early Bird start/end dates — this is the piece that must be updated per use case (whatever the promo's own phase calendar is).
- Cash/Users/Cash-per-user are each split into `promo_` / `non_promo_` / total, using `Q2_2026_Tentpole_promo_flag` (1 = promo, 0 = non-promo) as the switch inside `SUM(CASE WHEN ...)` and `COUNT(DISTINCT CASE WHEN ...)`.
- Cash-per-user divides the matching cash cut by the matching user cut, guarded with `NULLIF(..., 0)` to avoid divide-by-zero (relevant for `Pre-promo`, where `promo_users` is always 0 since no promo is running yet — hence `promo_cash_per_user` is `null` there by design, not a bug).
- `ORDER BY arm, MIN(transaction_dt)` — orders periods chronologically within each arm rather than alphabetically, since `'After early bird' < 'During early bird' < 'Pre-promo'` alphabetically would come out in the wrong order.

**Filters:** same as Query 2 (`transaction_type = 'BUY'`, non-refunded, B2C, lower bound = pricing test start) — restated at the `cplus_annual` step: `product_sub_type = 'C Plus annual'` and `hpt_flag IN ('true', 'false')` (drops the non-experiment population).

**Known date-bound gotcha:** the upper bound in `base` was `DATE(ab.transaction_ts) <= CURRENT_DATE - 2`, not a hardcoded promo-end date. This worked because the analysis was run on 2026-07-15, just after the promo ended (2026-07-13) — `today - 2` happened to land past the promo end. Re-running this query later (or reusing the skeleton for a different promo) will silently include unrelated post-promo transactions in the `'After early bird'` bucket unless the upper bound is hardcoded to the actual promo end date. **Always hardcode the promo-end date explicitly rather than relying on `CURRENT_DATE - 2` lining up.**

### Query 5 — Channel registration split, Test vs Control (the 50:50 sense check)

Of all the users who were impressed during the experiment, what was the channel registration breakup? Captures L0 marketing-channel categorization (Paid, Organic) and the split of impressed users between Test and Control within each channel. **This is the pitfall-list check** ("check if the traffic split between test and control was 50:50") applied at channel granularity, not just in aggregate — a channel-level imbalance can hide inside an overall 50:50 split.

```sql
WITH variants AS (
      SELECT
        -- Experiment metadata.
        epic_experiment_id
        , epic_experiment_started_at
        , epic_experiment_ended_ts
        , MAX(COALESCE(epic_experiment_ended_ts, CURRENT_DATE)) OVER () AS end_ts
        , epic_experiment_display_name
        -- Variant metadata.
        , epic_variant_id
        , epic_variant_weight
        , TRIM(REGEXP_REPLACE(epic_variant_name, '', '')) AS cleaned_epic_variant_name
        ,
        (MAX(CASE WHEN epic_variant_index = 0 AND epic_experiment_id = 'kEs8FDkHEfGErBK2XQAA3w' THEN 1 ELSE 0 END)
        OVER (PARTITION BY TRIM(REGEXP_REPLACE(epic_variant_name, '', ''))))::BOOLEAN
         AS is_control
        -- Get the order of variants. Order same as EPIC unless control is manually set, in which case control is put first.
        , CASE
        WHEN is_control THEN 1
        ELSE -MIN(epic_variant_index) OVER (PARTITION BY TRIM(REGEXP_REPLACE(epic_variant_name, '', '')))
        END AS sort_by
      FROM prod.bi.epic_variants
      JOIN prod.bi.epic_experiments USING (epic_experiment_id)
      WHERE (
      epic_experiment_id = 'kEs8FDkHEfGErBK2XQAA3w'
      )
      AND epic_experiment_allocation_type = 'BY_USER'
      ),
cohort_users_details AS (
      SELECT
        is_control
        , user_id
        -- Get impression start and end timestamps for metrics calculations. This includes users
        , MIN(impression_ts) AS start_ts,
          MAX(end_ts) AS end_ts
      FROM prod.bi.epic_user_impressions
      JOIN variants USING (epic_experiment_id, epic_variant_id)
      WHERE
        impression_dt BETWEEN epic_experiment_started_at::DATE AND COALESCE(epic_experiment_ended_ts::DATE, CURRENT_DATE) -- speeds up the computation
        AND impression_ts BETWEEN epic_experiment_started_at AND COALESCE(epic_experiment_ended_ts, CURRENT_DATE)
        AND 1=1 -- no filter on 'impressions.impression_date'
      GROUP BY 1, 2),
channel_impression_user_level_data AS (
SELECT a.*,
       b.registration_referrer_cons_l0_mktg_chnl_ft14d
FROM cohort_users_details a
LEFT JOIN (SELECT DISTINCT user_id,registration_referrer_cons_l0_mktg_chnl_ft14d
           FROM prod.gold.user_stats_vw
           WHERE user_id IN (SELECT DISTINCT user_id FROM cohort_users_details))b
ON a.user_id=b.user_id)
SELECT registration_referrer_cons_l0_mktg_chnl_ft14d AS L0_channel,
       is_control,
       COUNT(DISTINCT user_id) AS user_count
FROM channel_impression_user_level_data GROUP BY 1,2
ORDER BY 1 DESC, 2
```

**Joins:**
- `cohort_users_details` is the same "impressed users, is_control + impression window" logic as Query 1 (renamed here from an anonymous final `SELECT` to a named CTE).
- `channel_impression_user_level_data`: `cohort_users_details` (a) LEFT JOIN a subquery on `prod.gold.user_stats_vw` (b) for `registration_referrer_cons_l0_mktg_chnl_ft14d` (the L0 channel), matched on `user_id`. The subquery pre-filters `user_stats_vw` to `user_id IN (SELECT DISTINCT user_id FROM cohort_users_details)` — restricts the join to only the experiment's impressed population before joining, rather than joining against the full table.

**Logic:** final `SELECT` groups by `(L0_channel, is_control)` and counts distinct `user_id` — giving impressed-user counts per channel per arm. Compare Control vs Test counts within each `L0_channel` row to check the ~50:50 split holds channel-by-channel, not just in the overall population.

### Query 6 — Final output table with two sensitivity nuances baked in

Same output table as Query 4 (`arm × period`, Cash/Users/Cash-per-user split promo/non-promo/total), plus a `channel` cut, but with **two nuances baked into the filters** to sharpen the isolation:

1. **Capped at the pricing test's own end date (6/24), not the promo end** — restricts the window to strictly isolate the test's effect, rather than running through the full promo (which the EPIC-stickiness caveat means could otherwise blend in behavior after the test's official tagging window closes).
2. **Excludes the last 3 days of Early Bird (6/15–6/17)** — those days carry urgency messaging in the promo banners, which skews the numbers. Excluding them makes "During early bird" and "After early bird" an apples-to-apples comparison. **Dates here are use-case specific** and will change per test/promo.

```sql
with domain as ( ... ),                    -- Query 1 above
high_pricing_test_users AS ( ... ),         -- Query 1 above
 base AS (
  SELECT * FROM (
SELECT
    CAST(COALESCE(CAST(hpt.is_control AS STRING),'non-high_pricing_test_population') AS STRING) AS hpt_flag,
    ab.*,
    hpt.start_ts AS hpt_start_ts,
    hpt.end_ts AS hpt_end_ts,
    b.country_group_finance,
    first_payment_referrer_cons_l0_mktg_chnl_ft28d as channel,
    COALESCE(b1.product_sub_type, ab.underlying_product_type) AS product_sub_type,
    d.is_cplus_upsell,
    DATE(ab.transaction_ts) AS transaction_dt,
    a.payment_order,
    recurring_payment_start_ts,
    recurring_payment_end_ts,
    a.subscription_id,
    a.subscription_status,
    a.is_subscription_active,
    cc1.promotion_name,
    cc1.promotion_id,
    CASE WHEN cc1.promotion_id IN (287767, 287768, 287769, 287771, 287775) THEN 1 ELSE 0 END AS Q2_2026_Tentpole_promo_flag,
    subscription_cancel_ts,
    subscription_inactivation_ts,
    f.country_cd,
    CASE
        WHEN primary_domain IS NULL THEN 'Others'
        ELSE primary_domain
    END AS primary_domain,
    COALESCE(subscription_cancel_ts, subscription_inactivation_ts) AS subscription_end_ts,
    ROW_NUMBER() OVER (PARTITION BY ab.transaction_id ORDER BY ab.transaction_ts ASC) AS rn1
FROM prod.gold.transactions_vw ab
LEFT JOIN prod.gold.completed_carts_vw cc1
    ON ab.user_id = cc1.user_id
    AND ab.cart_id = cc1.cart_id
LEFT JOIN prod.gold.users_vw f
    ON ab.user_id = f.user_id
LEFT JOIN prod.silver_base.static_countries b
    ON f.country_cd = b.country_cd
LEFT JOIN prod.bi.subscription_payments a
    ON a.user_id = ab.user_id
    AND a.transaction_id = ab.transaction_id
LEFT JOIN prod.bi.subscriptions bs
    ON a.user_id = bs.user_id
    AND a.subscription_id = bs.subscription_id
LEFT JOIN prod.bi.subscriptions__payment_stats d
    ON a.user_id = d.user_id
    AND a.subscription_id = d.subscription_id
LEFT JOIN domain pt
    ON a.underlying_product_item_id = pt.underlying_product_item_id
LEFT JOIN prod.bi.products_detail b1
    ON ab.product_item_id = b1.product_item_id
    AND ab.product_type = b1.product_type
LEFT JOIN high_pricing_test_users hpt ON ab.user_id = hpt.user_id AND ab.transaction_ts between hpt.start_ts AND hpt.end_ts
LEFT JOIN prod.gold.user_stats_vw us ON ab.user_id=us.user_id
WHERE transaction_type = 'BUY'
    AND NOT was_buy_transaction_refunded
    AND transaction_business_line = 'B2C'
    AND DATE(ab.transaction_ts) <= (CAST(DATE_FORMAT(CAST('2026-06-24' AS DATE), 'yyyy-MM-dd') AS DATE))
    AND DATE(ab.transaction_ts) NOT between (CAST(DATE_FORMAT(CAST('2026-06-15' AS DATE), 'yyyy-MM-dd') AS DATE)) AND (CAST(DATE_FORMAT(CAST('2026-06-17' AS DATE), 'yyyy-MM-dd') AS DATE))
    AND DATE(ab.transaction_ts) >= (CAST(DATE_FORMAT(CAST('2026-04-28' AS DATE), 'yyyy-MM-dd') AS DATE)))
    WHERE rn1=1
),
cplus_annual AS (
  SELECT *
  FROM base
  WHERE product_sub_type = 'C Plus annual'
    AND hpt_flag IN ('true', 'false')      -- experiment population only
)
SELECT
  CASE WHEN hpt_flag = 'true' THEN 'Control' ELSE 'Test' END AS arm,
  channel,
  CASE
    WHEN transaction_dt < DATE'2026-06-08' THEN 'Pre-promo'
    WHEN transaction_dt BETWEEN DATE'2026-06-08' AND DATE'2026-06-17' THEN 'During early bird'
    ELSE 'After early bird'
  END AS period,
  -- Cash
  ROUND(SUM(CASE WHEN Q2_2026_Tentpole_promo_flag = 1 THEN cash_receipt_usd_estimate ELSE 0 END),2) AS promo_cash,
  ROUND(SUM(CASE WHEN Q2_2026_Tentpole_promo_flag = 0 THEN cash_receipt_usd_estimate ELSE 0 END),2) AS non_promo_cash,
  ROUND(SUM(cash_receipt_usd_estimate),2) AS total_cash,
  -- Users
  COUNT(DISTINCT CASE WHEN Q2_2026_Tentpole_promo_flag = 1 THEN user_id END) AS promo_users,
  COUNT(DISTINCT CASE WHEN Q2_2026_Tentpole_promo_flag = 0 THEN user_id END) AS non_promo_users,
  COUNT(DISTINCT user_id) AS total_users,
  -- Cash per user
  ROUND(SUM(CASE WHEN Q2_2026_Tentpole_promo_flag = 1 THEN cash_receipt_usd_estimate ELSE 0 END)
        / NULLIF(COUNT(DISTINCT CASE WHEN Q2_2026_Tentpole_promo_flag = 1 THEN user_id END),0),2) AS promo_cash_per_user,
  ROUND(SUM(CASE WHEN Q2_2026_Tentpole_promo_flag = 0 THEN cash_receipt_usd_estimate ELSE 0 END)
        / NULLIF(COUNT(DISTINCT CASE WHEN Q2_2026_Tentpole_promo_flag = 0 THEN user_id END),0),2) AS non_promo_cash_per_user,
  ROUND(SUM(cash_receipt_usd_estimate) / NULLIF(COUNT(DISTINCT user_id),0),2) AS total_cash_per_user
FROM cplus_annual
GROUP BY 1, 2, 3
ORDER BY arm, MIN(transaction_dt);
```

**What changed vs Query 4:**
- Upper date bound: `<= '2026-06-24'` (test end) instead of `<= CURRENT_DATE - 2`.
- New filter: `DATE(ab.transaction_ts) NOT BETWEEN '2026-06-15' AND '2026-06-17'` — drops the urgency-messaging tail.
- Adds `first_payment_referrer_cons_l0_mktg_chnl_ft28d AS channel` and groups by it (`GROUP BY 1, 2, 3` → arm, channel, period), vs Query 4's `GROUP BY 1, 2` (arm, period only).
- Adds `LEFT JOIN prod.gold.user_stats_vw us ON ab.user_id = us.user_id`.

**Subtlety worth flagging on the period boundaries:** the `period` CASE statement's boundaries are unchanged (`'During early bird'` is still defined as `transaction_dt BETWEEN '2026-06-08' AND '2026-06-17'`). The urgency-window exclusion happens one level up, in the `base` CTE's `WHERE` clause — so rows for 6/15–6/17 are dropped entirely before they ever reach the `period` labeling. Net effect: `'During early bird'` still carries that label, but only ever contains 6/8–6/14 data once the exclusion filter is applied. Worth being explicit about this when reusing the pattern, since the period boundary alone doesn't tell you the window was shortened — you have to read the `WHERE` clause to know that.

**Flag for confirmation — possible dead/unclear join:** `prod.gold.user_stats_vw us` is joined on `user_id`, but the `channel` column (`first_payment_referrer_cons_l0_mktg_chnl_ft28d`) is selected unqualified, and no other column from `us` appears in the `SELECT`. If that field exists on `transactions_vw` (`ab`) directly, this join may be unused (similar to the `subscriptions bs` join flagged in Query 2); if it only exists on `user_stats_vw`, the column should probably be qualified as `us.first_payment_referrer_cons_l0_mktg_chnl_ft28d` to avoid ambiguity. Worth confirming which table it's actually resolving from before reusing this pattern.

### Query 7 — Trendline graph with Query 6's nuances baked in

Same chart shape as Query 3 (dual-axis Cash-lines + Users-bars, one subplot per arm, Early Bird shaded), but applied to Query 6's isolation nuances — capped at the pricing test's own end date and with the urgency-messaging days excluded — to see the same effect visually rather than just in the table.

```sql
WITH domain AS ( ... ),                    -- Query 1 above
high_pricing_test_users AS ( ... ),        -- Query 1 above
base AS (
  SELECT * FROM (
    ...                                    -- same SELECT/joins as Query 3's base
  )
  WHERE rn1 = 1
    -- date filters, differing from Query 3:
    -- AND DATE(ab.transaction_ts) <= CURRENT_DATE - 2
    -- AND DATE(ab.transaction_ts) <= (CAST(DATE_FORMAT(CAST('2026-06-24' AS DATE), 'yyyy-MM-dd') AS DATE))
    -- AND DATE(ab.transaction_ts) NOT BETWEEN (CAST(DATE_FORMAT(CAST('2026-06-15' AS DATE), 'yyyy-MM-dd') AS DATE)) AND (CAST(DATE_FORMAT(CAST('2026-06-17' AS DATE), 'yyyy-MM-dd') AS DATE))
    -- AND DATE(ab.transaction_ts) >= (CAST(DATE_FORMAT(CAST('2026-04-28' AS DATE), 'yyyy-MM-dd') AS DATE))
),
cplus_annual AS (
  SELECT * FROM base
  WHERE product_sub_type = 'C Plus annual'
    AND hpt_flag IN ('true', 'false')
)
SELECT
  transaction_dt,
  CASE WHEN hpt_flag = 'true' THEN 'Control' ELSE 'Test' END AS arm,
  CASE WHEN promotion_id IS NOT NULL AND Q2_2026_Tentpole_promo_flag = 1 THEN 'Promo' ELSE 'Non-promo' END AS promo_status,
  ROUND(SUM(cash_receipt_usd_estimate), 2) AS cash,
  COUNT(DISTINCT user_id) AS users
FROM cplus_annual
GROUP BY 1, 2, 3
ORDER BY transaction_dt, arm, promo_status
```

Python plotting logic is identical to Query 3 — same pivot-and-plot structure, same Early Bird shading, same dual-axis-per-arm layout. See Query 3 for the full code.

**Differences vs Query 3's date filters:**
- Adds the `<= '2026-06-24'` test-end cap alongside the pre-existing `<= CURRENT_DATE - 2` (the latter is now redundant here since 6/24 already predates `CURRENT_DATE - 2`, but harmless left in).
- Adds the `NOT BETWEEN '2026-06-15' AND '2026-06-17'` urgency-messaging exclusion.

**Chart-reuse caveat — silent x-axis gap:** `dates` is built from `sorted(df["transaction_dt"].unique())`, i.e. only the dates that actually appear in the query result. Since 6/15–6/17 are excluded entirely at the SQL level (not zeroed out, genuinely absent), those three dates won't appear in `dates` at all — the x-axis will jump directly from Jun 14 to Jun 18 with no visual gap or marker indicating days were dropped. The Early Bird shading still lands correctly on the surviving dates (6/8–6/14), so it isn't misleading on that front, but anyone reading the chart without knowing about the exclusion could mistake Jun 14 and Jun 18 as adjacent days. Worth adding an explicit annotation or gap marker if this chart is shared outside the immediate analysis.

## 4. Output contract

A table with data like this:

| arm | period | Cash: promo | Cash: non_promo | Cash: total | Users: promo | Users: non_promo | Users: total | Cash/user: promo | Cash/user: non_promo | Cash/user: total | Total Promo Cash (EB+Post EB) |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Control | Pre-promo | $0.00 | $303,957.64 | $303,957.64 | 0 | 845 | 845 | null | $359.71 | $359.71 | Total Promo Cash Control |
| Control | During early bird | $538,904.28 | $22,753.09 | $561,657.36 | 2,811 | 61 | 2,872 | $191.71 | $373.00 | $195.56 | $838,278.76 |
| Control | After early bird | $299,374.48 | $20,451.48 | $319,825.97 | 1,363 | 58 | 1,421 | $219.64 | $352.61 | $225.07 | |
| Test | Pre-promo | $0.00 | $289,832.50 | $289,832.50 | 0 | 991 | 991 | null | $292.46 | $292.46 | Total Promo Cash Test |
| Test | During early bird | $479,889.51 | $18,772.64 | $498,662.15 | 3,146 | 61 | 3,207 | $152.54 | $307.75 | $155.49 | $794,675.90 |
| Test | After early bird | $314,786.39 | $21,579.88 | $336,366.27 | 1,770 | 72 | 1,842 | $177.85 | $299.72 | $182.61 | |
| **Overall Impact** (Control − Test, "Actual" method) | | | | | | | | | | | **$43,602.86*** |

\* footnote marker in the original doc — exact annotation wasn't captured in the plain-text export; flag if it matters.

## 5. Known pitfalls

- Got to know about the EPIC stickiness that experiment users will continue to see reduced prices even if the pricing test has ended, so consideration of the right time period window for analysis is important.
- Checking the traffic split to rule out any variant split issues beforehand.
- Using the right methodology to calculate impact. This is very important. Rely on Actuals.

## 6. Generalization boundary

This particular SKILL is specific to that, but it can be used for getting started on other such problem statements.
