---
question_id: consumer-q050
question_text: >
  What is the free-trial-to-paid conversion rate for the last complete trial-end month?
source: real
target_skill: skills/data-science/consumer_and_degree_strategy_ds/consumer_ds/consumer-ds-metrics-lookup
ground_truth_status: draft
grading: method
level: L1
eval_class: atomic
---

Bucket A / coverage-gap probe: cohort = subscriptions with a free trial, bucket by trial_end
month with the 2-day lag; conversion = share with periods_paid_for_nonrefunded > 0, from
prod.bi.subscriptions__payment_stats. This metric is in the table inventory but THIN in
metric-definitions.md -- a clean atomic here tests a likely skill coverage gap (may surface as
a skill-hardening item).

Golden answer and agent runs come in later PRs. This file only pins the question.
