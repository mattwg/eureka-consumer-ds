# Rubric — q008 (what a correct answer MUST contain)

A fresh answer passes if all of these hold. This is the grading contract for the LLM judge
and the human reviewer. It checks the **method**, not an exact number.

## Must have (fail if missing)

1. Uses `prod.bi.base_data_for_ret_cancel` as the source.
2. Uses `next_txn_stamp_sub_level` as the renewal signal (NOT `next_txn_stamp`).
3. Filters to `transaction_business_line='B2C'` and `product_sub_type='C Plus monthly'`.
4. Applies the 7-day eligibility lag (`recurring_payment_end_ts < CURRENT_DATE()-INTERVAL 7 DAYS`).
5. Reports **M1** (payment_order=1), **M2** (payment_order=2), and **M2+** (payment_order>=2 aggregate).
6. Identifies the **biggest drop-off as M1** (the first renewal).
7. States that retention **rises with tenure** (does not call it declining).

## Must NOT do (fail if present)

- Present a single-cohort survival curve as if it were the step-retention answer.
- Use `next_txn_stamp` (any-purchase) as the renewal signal.
- Quote a number without the B2C + C+ monthly + eligibility-lag filters.

## Allowed variation (do not fail on these)

- Blended-across-cohorts vs a named recent cohort (either is fine unless the pod pins one).
- Exact percentages (data drifts; method-only).
- Extra steps (M3, M4, M5) or extra segmentation, as long as M1/M2/M2+ are covered.

## Escalate to human (judge answers "Unknown")

- A different but plausibly valid method the rubric does not cover -> send to codeowner,
  do not auto-fail.
