---
name: high-income-pricing-test-promo-impact
description: >
  DRAFT — description to be finalized once all sections are in. Covers
  analyzing the impact of an A/B pricing test intermingling with a live
  promo, worked through the High Income Pricing Test vs Q2 '26 C+ Annual
  Tentpole Promo case.
---

# High Income Pricing Test — Impact on Q2 '26 C+ Annual Tentpole Promo

## 1. Trigger conditions

This SKILL is created to analyse and understand the impact A/B tests can have on a running promo. We are taking the High Income Pricing test which coincided with our C+Annual promo.

Here, we are laying out the thought process and methodology we used to navigate this situation.

This SKILL should serve as a starting point for developing context on how to go about such situations, how can this problem be broken down into smaller chucks, what metrics and factors to analyse and why, how we calculated and articulated the impact, what nuances were taken care of, what were the learnings, who are the directly impacted stakeholders, etc. In future, we will most likely have new and different tests but with this SKILL, we can get on with the analysis. Most importantly, this SKILL will be quite handy for looking at such inter-mingling effects between promotions & 'pricing tests' in particular.

For starters, proper context should be there for the Test and the Promotion.

### Context for High Income Pricing Test

- High Income Pricing Test was an experiment that was run in 85 selected high income countries.
- A detailed Confluence doc can be found here: Page: [Experiment Plan] Pricing Test for High-income Countries
- This test was designed in such a manner that prices of subscription based products like C+ Monthly and C+ Annual were lowered and prices of Standalone courses or Gateways like products were increased. This was to push users to choose subscription based products over one time products.
- The pricing was also done strategically by playing countries into different buckets where test users would see prices differently compared to what they were accustomed to see. There were 5 primary buckets:
  - Prices higher than the US: 105%
  - Prices similar to the US: 100%
  - Prices 85-99% of the US: 85%
  - Prices 70-84% of the US: 75%
  - Prices below 70% of the US: 70%
- This test was run from 28th April 2026 to 24th June, 2026.
- The key metrics to judge the pricing test performance were: Total Cash, Retention.

### Context on Q2 '26 C+ Annual Tentpole Promo

The Lifecycle Marketing team ran the Q2 '26 C+ Annual Tentpole Promo from 8th June 2026 to 13th July 2026. There was an Early Bird Offer in this promo from 8th June to 17th June where the promotion offer was at 50% off. Post 17th june until the promo end date, this offer ran at 40% off.

This test coincided with the promo from 8th June 2026 to 24th June 2026.

However, the test was running using EPIC and all the users in the population who were impressed with the price they saw during promo (prices were already reduced due to the high income pricing test that were further reduced by the promo) continued to see lesser prices even after the high income pricing test ended. This is because EPIC is "sticky".

In future, similar or other tests will also run but we have to trigger this SKILL whenever we want to understand what kind of impact a test can have on a promo. As much of the nuance as is known is being baked into the SKILL, but new problems and tests will have newer nuances, and that should be taken care of by asking the user beforehand whenever this SKILL is triggered.

## 2. Methodology, step by step

Answering important questions first:

- The test mechanics like splitting between control and test, designing the experiment, identifying the primary, secondary and guardrail metrics and all the experiment related nuances are designed and defined by the Product Managers and Product Data Scientists. Test performance also belongs to the foray of product DS.
- Lifecycle Marketing team orchestrates the promotions and runs them.
- Consumer Strategy DS team which will be the core user of this SKILL. They have performed the analysis on "Effects/Impact of the High Income Pricing Test on the C+ Annual Tentpole Promotion in Q2'26". This is our main problem statement to solve. The final answer we would like to provide is the total impact in terms of cash.

Methodology:

- We limited our analysis to the users who were part of the experiment. We got their categorizations of Control & Test.
- We looked at these users' transactions between their impression start date and end date.
- We based our analysis on 3 metrics: Total User count, Total Cash Count and Cash per user.
- We performed some aggregations to get the sense check on numbers. The aggregation format looks like the table below (template — cells filled in per run):

| arm | period | Cash: promo | Cash: non_promo | Cash: total | Users: promo | Users: non_promo | Users: total | Cash/user: promo | Cash/user: non_promo | Cash/user: total |
|---|---|---|---|---|---|---|---|---|---|---|
| Control | Pre-promo (41 days) | | | | | | | | | |
| Control | During early bird (10 days) | | | | | | | | | |
| Control | After early bird (25 days) | | | | | | | | | |
| Test | Pre-promo (41 days) | | | | | | | | | |
| Test | During early bird (10 days) | | | | | | | | | |
| Test | After early bird (25 days) | | | | | | | | | |

Here, for each control and test group, we looked at 3 different time periods because user behavior would be different across these:

- **Pre-promo:** This was the intended price the Product team wanted the users to see during the experiment.
- **During Early Bird:** Listed price of both Test & Control groups got slashed by 50% during this period. Promotion discount is increased by 10% during early bird period.
- **After Early Bird:** Listed price of both Test & Control groups got slashed by 40% during this period. This was the original promotion discount value.

We also looked at averages during the 3 time periods to assess daily impact, as the time window of each of these 3 periods are different and trailing 3-4 days of promotion period (both during and after Early Bird) come with Urgency messaging and can skew the metrics.

Along with all of these things, we also look at trendlines and graphs:

- **Graph 1:** For both Test & Control groups:
  - Cash and Users graph over the entire time period from when the pricing test started to when the promotion ended — here we can visually see how the impact has changed through these time periods, and this information aids our analysis directionally.
  - This is a dual axis graph with Cash (depicted by Lines) & Users (depicted by bars) and dates on the X axis.
  - Highlight the Early bird time period with a little grey background to make the distinction between the time periods evident.
  - One example graph is attached below: _(see original doc for image)_
- For separate cash & users graph, we plot the line chart for total cash for both test & control users to compare their performance.

Apart from the above, we looked at some more nuances:

- Restricting the data only until 06/24, i.e. the test end period.
- Calculating the averages for each of the metrics in the 3 time periods to assess day level impact.
- Looked at the country level breakdown at the traffic split and transactions split — focussed on top 5 countries.
- As a sense check — check if the traffic split between test and control was 50:50.

To calculate the final impact, we came up with 2 methodologies:

- **Extrapolated:** without the test, we'd expect combined performance to roughly equal control performance × 2, since test and control are equal-sized halves. So the opportunity is calculated as: (Control performance × 2) − (Actual Test + Control performance). This gives us the gap between expected baseline (no test) and actual observed performance — essentially the uplift or shortfall attributable to the test.
- **Actual:** Total Cash Control (EB + Post EB) − Total Cash Test (EB + Post EB).

## 3. Data sources and query patterns

_(pending — queries to be shared and embedded one by one with context, in a follow-up pass)_

## 4. Output contract

A table with data like this:

| arm | period | Cash: promo | Cash: non_promo | Cash: total | Users: promo | Users: non_promo | Users: total | Cash/user: promo | Cash/user: non_promo | Cash/user: total | Total Promo Cash (EB+Post EB) |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Control | Pre-promo | $0.00 | $303,957.64 | $303,957.64 | 0 | 845 | 845 | null | $359.71 | $359.71 | Total Promo Cash Control |
| Control | During early bird | $538,904.28 | $22,753.09 | $561,657.36 | 2,811 | 61 | 2,872 | $191.71 | $373.00 | $195.56 | $838,278.76 |
| Control | After early bird | $299,374.48 | $20,451.48 | $319,825.97 | 1,363 | 58 | 1,421 | $219.64 | $352.61 | $225.07 | |
| Test | Pre-promo | $0.00 | $289,832.50 | $289,832.50 | 0 | 991 | 991 | null | $292.46 | $292.46 | Total Promo Cash Test |
| Test | During early bird | $479,889.51 | $18,772.64 | $498,662.15 | 3,146 | 61 | 3,207 | $152.54 | $307.75 | $155.49 | $794,675.90 |
| Test | After early bird | $314,786.39 | $21,579.88 | $336,366.27 | 1,770 | 72 | 1,842 | $177.85 | $299.72 | $182.61 | |
| **Overall Impact** (Control − Test, "Actual" method) | | | | | | | | | | | **$43,602.86*** |

\* footnote marker in the original doc — exact annotation wasn't captured in the plain-text export; flag if it matters.

## 5. Known pitfalls

- Got to know about the EPIC stickiness that experiment users will continue to see reduced prices even if the pricing test has ended, so consideration of the right time period window for analysis is important.
- Checking the traffic split to rule out any variant split issues beforehand.
- Using the right methodology to calculate impact. This is very important. Rely on Actuals.

## 6. Generalization boundary

This particular SKILL is specific to that, but it can be used for getting started on other such problem statements.
