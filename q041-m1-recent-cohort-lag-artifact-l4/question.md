---
question_id: consumer-q041
question_text: >
  Recent M1 cohorts for C+ monthly look like they're cratering -- is that a real decline or an
  artifact of the 7-day eligibility lag, and should reporting switch to the T1 cut for the
  current month?
source: real
target_skill: skills/data-science/consumer_and_degree_strategy_ds/consumer_ds/consumer-ds-metrics-lookup
ground_truth_status: draft
grading: method
level: L4
eval_class: complex
---

Compare the standard 7-day-lag cut vs the T1 cut (2-day lag + next_txn_stamp_sub_level <=
recurring_payment_end_ts + INTERVAL 1 DAY) for the most recent cohort. Artifact-vs-real +
reporting recommendation -> complex: confirm which recent cohort/month and whether T1 is
acceptable for the pod's reporting.

Golden answer and agent runs come in later PRs. This file only pins the question.
