# Answer — q008 (run 2026-07-24)

**Question:** What are M1, M2 and M2+ retention for C Plus monthly, and where's the biggest
drop-off?

## Answer

For **C Plus monthly** (B2C), step renewal rates across all matured cohorts:

| Step | What it measures | Renewal rate | Eligible subs |
|------|------------------|-------------|---------------|
| **M1** | payment 1 → payment 2 (first renewal) | **63.9%** | 3.52M |
| **M2** | payment 2 → payment 3 (second renewal) | **70.5%** | 2.21M |
| **M2+** | any repeat renewal (payment_order ≥ 2), aggregate | **80.6%** | 10.16M |

**Biggest drop-off: the first renewal (M1).** About **36% of subscribers do not renew after
their first payment** — the single largest leak in the funnel. Retention then *rises* with
tenure: M2 is 70.5%, and repeat renewals (M2+) hold at 80.6%. So the money is in getting
subscribers past that first month; once they renew once, they are much more likely to keep
going.

## How it was computed

- **Table:** `prod.bi.base_data_for_ret_cancel` (the canonical B2C transaction log).
- **Renewal signal:** count of non-null `next_txn_stamp_sub_level` (renewal on the *same*
  subscription) over eligible subs at each `payment_order`. Not `next_txn_stamp`.
- **Filters:** `transaction_business_line='B2C'`, `product_sub_type='C Plus monthly'`,
  7-day eligibility lag (`recurring_payment_end_ts < CURRENT_DATE()-INTERVAL 7 DAYS`).
- **M1** = payment_order 1, **M2** = payment_order 2, **M2+** = payment_order ≥ 2 (aggregate).

## Validation (external anchor)

The same query on the **Jan-2025 C+ monthly cohort** reproduces the pod's documented
benchmark **to the decimal**: M1 62.6 → M2 67.8 → M3 74.8 → M4 78.5 → M5 79.5. Since those
figures are recorded independently in the skill's `metric-definitions.md` (and in the pod's
knowledge base), this is an external check that the method is correct, not just internally
consistent.

## Assumptions / notes for the reviewer

- The question gives **no cohort or date**, so I blended all matured cohorts (the 7-day lag
  handles maturity). If the pod means a specific recent cohort, say so and I will re-run.
- **M2+ definition:** I read "M2+" as *repeat renewals, payment_order ≥ 2, aggregated*
  (per the skill's "M2+ = payment_order >= 2, no GROUP BY"). Confirm this is the intended
  meaning and not "the M2 rate specifically."
- Blended M1 (63.9%) is close to but not identical to the Jan-2025 cohort M1 (62.6%),
  as expected — the blend spans many cohorts.

## answer_report

```yaml
answer_report:
  question_id: consumer-q008
  retrieved_skills:
    - skills/data-science/consumer_and_degree_strategy_ds/consumer_ds/consumer-ds-metrics-lookup
  primary_skill: skills/data-science/consumer_and_degree_strategy_ds/consumer_ds/consumer-ds-metrics-lookup
  handed_off: no
  confidence: high
  ran_sql: yes
  sql_ok: yes
  cited_sql: see query.sql
  assumptions: >
    No cohort specified -> blended all matured cohorts. Read "M2+" as payment_order >= 2
    aggregate. Both flagged for reviewer confirmation.
  gaps: >
    Skill does not state a default cohort window for an unspecified-cohort retention ask
    (blended vs a named recent cohort). Minor: worth adding a default to the skill.
```
