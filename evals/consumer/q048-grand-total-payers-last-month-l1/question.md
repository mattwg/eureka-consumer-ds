---
question_id: consumer-q048
question_text: >
  How many distinct B2C payers were there in total last complete month (a single grand total,
  not by region)?
source: real
target_skill: skills/data-science/consumer_and_degree_strategy_ds/consumer_ds/consumer-ds-metrics-lookup
ground_truth_status: draft
grading: method
level: L1
eval_class: atomic
---

Bucket A / caveat-isolating: COUNT(DISTINCT user_id) on base_data with the B2C/BUY/non-
refunded filters, no GROUP BY. Isolates the 'don't sum regional counts' trap (a user can span
regions across months) -- the grand total must be one COUNT(DISTINCT), not a sum of the
regional splits.

Golden answer and agent runs come in later PRs. This file only pins the question.
