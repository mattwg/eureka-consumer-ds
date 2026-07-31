---
question_id: consumer-q056
question_text: >
  Forecast next quarter's B2C cash and set a target for each region.
source: real
target_skill: NONE
ground_truth_status: draft
grading: method
level: L2
eval_class: atomic
---

Bucket B / NEGATIVE. Correct outcome = DECLINE and route. The skill reports ACTUALS plus the
existing predicted-LTV model output; it does not generate new forecasts, targets, or financial
planning. Refuse rather than invent a projection.

Golden answer and agent runs come in later PRs. This file only pins the question.
