---
question_id: consumer-q047
question_text: >
  What were total visits (all-audience) for the last complete month?
source: real
target_skill: skills/data-science/consumer_and_degree_strategy_ds/consumer_ds/consumer-ds-metrics-lookup
ground_truth_status: draft
grading: method
level: L1
eval_class: atomic
---

Bucket A / caveat-isolating: SUM(visits) on TOF with the invalid-traffic exclusion, capped at
the last complete month. Isolates the New-Visits/Total-Visits `user_segment` trap -- these
live only on user_segment IS NULL rows; adding a user_segment filter collapses them to ~0. A
wrong answer pinpoints that the skill failed to convey the trap.

Golden answer and agent runs come in later PRs. This file only pins the question.
