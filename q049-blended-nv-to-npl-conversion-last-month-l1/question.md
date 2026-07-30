---
question_id: consumer-q049
question_text: >
  What was the blended New-Visit->NPL conversion rate for the last complete month?
source: real
target_skill: skills/data-science/consumer_and_degree_strategy_ds/consumer_ds/consumer-ds-metrics-lookup
ground_truth_status: draft
grading: method
level: L1
eval_class: atomic
---

Bucket A / caveat-isolating: SUM(npls)*100.0/NULLIF(SUM(new_visits),0) on TOF, invalid-traffic
exclusion, last complete month, NO user_segment filter and NO join. Isolates the disjoint-
rowset grain-safety point (npls on segment rows, new_visits on user_segment IS NULL rows) and
the all-audience-numerator default.

Golden answer and agent runs come in later PRs. This file only pins the question.
