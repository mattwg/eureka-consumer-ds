---
question_id: consumer-q052
question_text: >
  What's our customer acquisition cost (CAC) and return on ad spend (ROAS) by marketing channel
  this quarter?
source: real
target_skill: NONE
ground_truth_status: draft
grading: method
level: L2
eval_class: atomic
---

Bucket B / NEGATIVE. Correct outcome = DECLINE and route to Consumer Strategy DS. TOF has
visits and channel labels but NO spend/cost data, so CAC/ROAS cannot be computed here. Refuse
rather than hallucinate a spend table.

Golden answer and agent runs come in later PRs. This file only pins the question.
