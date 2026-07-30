---
question_id: consumer-q042
question_text: >
  New Visits dropped sharply this month while NPLs held steady -- is that a real top-of-funnel
  falloff or a tracking artifact, and how much weight should the NV->NPL conversion trend get?
source: real
target_skill: skills/data-science/consumer_and_degree_strategy_ds/consumer_ds/consumer-ds-metrics-lookup
ground_truth_status: draft
grading: method
level: L4
eval_class: complex
---

Check whether new_visits/total_visits (~60% normally) moved sharply in the same window -- a
sudden swing there usually signals a cookie/identity tracking change, not real demand.
Artifact-vs-real + judgment -> complex: confirm the window and which channels/geos are in
scope.

Golden answer and agent runs come in later PRs. This file only pins the question.
