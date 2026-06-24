# consumer_ds — Table Schema & Join Reference

The core tables behind every metric in `metric-definitions.md`, the columns you actually use, how
they join, and which **lens** to pick. Full column dictionaries live in the source dbt / Unity
Catalog comments; this file lists the analytically-relevant columns only.

> **Rule:** always query the `prod.gold.*_vw` view (or the curated `prod.bi.*` mart), never a
> `prod.gold_base.*` / raw table, unless a column only exists on the base.

---

## Which table for which metric

| Metric family | Canonical table | Lens |
|---|---|---|
| Cash, Total Payers, Retention (MN), cohort LTV, completion-vs-churn | `prod.bi.base_data_for_ret_cancel` | transaction event log |
| NRL, NPL, New Visits, New-Visit→NPL conversion | `prod.bi.tof_consolidated_tracking_table` | TOF aggregate / trend |
| NRL / NPL **user-level** funnel, 14-day conversion | `prod.gold.users_vw` + `base_data_for_ret_cancel` (+ `user_stats_vw`) | user-level funnel |
| Predicted LTV | `prod.ml.user_level_ltv_prediction_npls_adj` | per-NPL model output |
| s12n completion (for good-cancel split) | `prod.gold.phoenix_specialization_enrollments_derived_metrics_vw` | completion lens |

**Two-lens rule (NRL & NPL):** aggregate/trend → TOF; "users who paid"/funnel → user-level. The
two need not tie to the exact same number — never mix them in one view.

---

## 1. `prod.bi.base_data_for_ret_cancel`  — B2C transaction event log (one row per payment event)
**Grain:** one BUY event per `subscription_id` × `payment_order`. Already B2C-scoped via the filter
(no enterprise/degree exclusion needed). **Verified:** for B2C this table holds only `transaction_type='BUY'`
rows with `was_buy_transaction_refunded=FALSE`, and `cash_receipt_usd_estimate ≡ transaction_amount_usd_estimate`.

| Column | Type | Use |
|---|---|---|
| `transaction_dt` | date | date filtering (cohort / period) |
| `transaction_business_line` | string | filter `= 'B2C'` |
| `transaction_type` | string | filter `= 'BUY'` (defensive no-op here) |
| `product_sub_type` | string | product variant — filter on this, not `product_type` |
| `product_type` | string | category (do not filter on this) |
| `subscription_id` | string | same across all renewals of a subscription |
| `payment_order` | int | 1 = first payment, 2 = first renewal (M1→M2), … |
| `recurring_payment_end_ts` | timestamp | billing-period end = renewal due date → eligibility |
| `next_txn_stamp_sub_level` | timestamp | **renewal signal** (same sub) — count non-nulls for retention |
| `next_txn_stamp` | timestamp | next purchase of *anything* — **do NOT use for retention** |
| `transaction_amount_usd_estimate` | decimal | gross bookings (always positive) |
| `cash_receipt_usd_estimate` | decimal | net cash (≡ gross here; excludes tax) |
| `was_buy_transaction_refunded` | boolean | filter `= FALSE` (defensive no-op here) |
| `was_chargeback_reversed` | boolean | part of the official net-cashflow recipe (see metric-definitions Cash) |
| `is_cplus_upsell` | boolean | TRUE = subscriber came via C+ upsell flow |
| `promotion_name` / `promotion_id` | string / bigint | promo detection (see 40% promo rule below) |
| `country_group_finance` | string | **region** (NAMER/EMEA/LatAm/Non-India APAC/India); pre-joined |
| `country_cd` | string | country (IP-based — inaccurate; prefer `country_group_finance`) |
| `underlying_product_item_id` | string | s12n id → join key to the completion view |
| `rn1` | int | `=1` is the latest row per `subscription_id` (current state) |
| `subscription_status` | string | ACTIVE / INACTIVE / CANCELLED / PAST_DUE |
| `is_subscription_active` | boolean | still owns the product through this sub |
| `inferred_client` / `inferred_os` | string | app/web · ios/android/web |

**40% promo / upsell / full-price segment rule:**
- `40pct_promo` = `product_sub_type='C Plus monthly'` AND (`promotion_name ILIKE '%40% off 3 months of C+%'` OR `promotion_name='global_2026_q2_cplusm__courseraplus_xpp_40_p____google'`). NEVER bare `LIKE '%40%'` (catches the C+ Annual affiliate promo).
- `upsell` = C+ monthly AND `is_cplus_upsell = TRUE` (and not 40%).
- `full_price` = C+ monthly, not 40%, `is_cplus_upsell = FALSE`.

---

## 2. `prod.bi.tof_consolidated_tracking_table`  — top-of-funnel aggregate (TOF V4)
**Grain:** `event_dt` × channel × geo × segment. Data from 2025-01-01.

| Column | Type | Use |
|---|---|---|
| `event_dt` | date | date filtering; cap at last complete month |
| `user_segment` | string | `B2C` / `B2B_ENTERPRISE` / `DEGREES` / **NULL** |
| `user_finaid_status` | string | `FINAID_user` / `Non-FINAID_user` / NULL |
| `new_visits` | bigint | first-time visits |
| `visits` | bigint | all visits (Total Visits) |
| `nrls` | bigint | new registered learners |
| `npls` | bigint | new paying learners |
| `referrer_cons_l0–l3_mktg_chnl` | string | channel taxonomy (L0 organic/paid → L1 detail) |
| `country_cd` | string | geo (IP-based) |

> ⚠️ **Verified grain gotcha:** `new_visits` / `visits` live **only** on `user_segment IS NULL`
> (all-audience) rows and are **0** on the segment rows; `nrls` / `npls` live **only** on
> segment-labeled rows. So: `SUM(new_visits)` over all rows does **not** multi-count, but **never**
> group/filter visits by `user_segment`. For Consumer NRL/NPL you **must** filter `user_segment='B2C'`.

**Standard TOF filters:** invalid-traffic exclusion
`NOT ((referrer_cons_l1_mktg_chnl='Direct' AND country_cd='CN') OR (referrer_cons_l2_mktg_chnl IN ('E2C') AND country_cd='SG'))`;
report through the last complete month; NPL also `user_finaid_status <> 'FINAID_user'`.

---

## 3. `prod.gold.users_vw`  — registration / user-level (apply B2C user filter)
| Column | Type | Use |
|---|---|---|
| `user_id` | bigint | join key |
| `registration_ts` | timestamp | registration cohort date |
| `registration_os_l1` / `registration_client` / `registration_device_family` | string | device dimension |
| `country_cd` | string | join to `static_countries_vw` for region |

## 4. `prod.gold.user_stats_vw`  — user payment stats
| `user_id` | bigint | join key |
| `first_unrefund_payment_ts` | timestamp | match to `transaction_ts` to flag true NPL |

## 5. `prod.silver.static_countries_vw`  — country → region
| `country_cd` | string | join key |
| `country_group_finance` | string | region grouping |

## 6. `prod.ml.user_level_ltv_prediction_npls_adj`  — predicted LTV (already NPL-scoped)
| `user_id` | bigint | join key (apply B2C user filter for a pure-B2C number) |
| `first_payment_dt` | date | NPL cohort month (partition column) |
| `adjusted_predicted_ltv` | float | predicted next-12-mo LTV (incl. VAT) |
| `adjusted_predicted_ltv_ex_vat` | float | ex-VAT variant |
| `state` | string | lifecycle state at scoring time (NOT an NPL filter) |

## 7. `prod.gold.phoenix_specialization_enrollments_derived_metrics_vw`  — s12n completion
| `user_id` | bigint | join key |
| `phoenix_specialization_id` | string | = `base_data.underlying_product_item_id` (verified 99.99% match) |
| `phoenix_specialization_completion_ts` | string | s12n completed when NOT NULL (cast to timestamp for comparisons) |

> Use the `prod.gold._vw`, **not** `coursera_warehouse.edw_core.*` — verified identical results.
> Completion records are learner education data (FERPA/GDPR) — keep output aggregate.

---

## B2C user filter (for user-level tables only)
`users_vw`, `user_stats_vw`, the LTV table — exclude enterprise + degree users
(`base_data_for_ret_cancel` does NOT need this):
```sql
LEFT ANTI JOIN prod.gold.enterprise_contract_program_memberships_vw e ON t.user_id = e.user_id
LEFT ANTI JOIN prod.gold_base.degree_course_session_enrollments     d ON t.user_id = d.user_id
```

## Join keys at a glance
- Retention / cash / payers: all within `base_data_for_ret_cancel` (no join).
- User-level NPL: `users_vw.user_id = base_data.user_id`, NPL flag `transaction_ts = user_stats_vw.first_unrefund_payment_ts`.
- Region for user-level: `users_vw.country_cd = static_countries_vw.country_cd`.
- Completion split: `base_data.underlying_product_item_id = completion_vw.phoenix_specialization_id` AND `user_id`.
