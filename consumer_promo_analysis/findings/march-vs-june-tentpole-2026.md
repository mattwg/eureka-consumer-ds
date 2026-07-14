# March vs. June Tentpole 2026 — Findings

Generated using `promo-campaign-recap` (this skill), pulling from the saved queries in
[../queries/](../queries/). Numbers as of 2026-07-14.

## 1. Objective

Compare the performance of the most recent tentpole promotion, **June Tentpole 2026** (Jun 5 –
Jul 13), against the previous one, **March Tentpole 2026** (Mar 24 – Apr 29), across the standard
recap cuts — base metrics, region, page-level attribution, and traffic source/channel — to
identify what changed and flag anything that warrants follow-up.

## 2. Executive Summary

- June Tentpole drove **~25% more redemptions** than March, but **almost no more cash** — cash per
  redemption is down **~19%**.
- The **India region nearly tripled** in both redemptions (+162%) and cash (+135%), the single
  largest mover of any region — while **NAMER cash actually declined 11.7%** even as the tentpole
  grew overall. This region-mix shift is the most plausible driver of the flat-cash-despite-more-
  redemptions pattern above.
- That India surge may overlap with a **WIP analysis owned by someone else** on the team (the
  India/geo-pricing product-test diagnosis referenced in the DS intake sheet) — coordinate before
  treating it as an independent new finding.
- The **C+ plan page's share of attributed redemptions grew** (50% → 56%), while the **logged-out
  homepage's share shrank** (15% → 11%) — a shift toward more direct-to-plan-page traffic.
- **Channel mix (Organic vs. Paid) held steady**, with only a slight tilt toward Paid in June.
- **June Tentpole numbers are provisional** — still inside the 2-day late-arrival reconciliation
  window as of this writing; re-pull after ~2026-07-16 before this goes external.

## 3. Detailed Analysis

### 3.1 Base metrics

| Metric | March Tentpole | June Tentpole* | Change |
|---|---:|---:|---:|
| Total redemptions | 38,353 | 47,895 | +24.9% |
| NPL redemptions | 26,358 (68.7%) | 33,267 (69.5%) | +26.2% |
| Non-NPL redemptions | 11,995 (31.3%) | 14,628 (30.5%) | +22.0% |
| Total cash | $7,514,619 | $7,597,975 | +1.1% |
| NPL cash | $5,131,409 | $5,201,518 | +1.4% |
| Non-NPL cash | $2,383,210 | $2,396,457 | +0.6% |
| **Cash per redemption** | **$195.94** | **$158.65** | **-19.0%** |

Redemptions grew substantially more than cash did — the gap between "+25% redemptions" and "+1%
cash" is the headline number this analysis is built around explaining. NPL and Non-NPL grew at
similar rates to each other, so the mix between new and returning payers isn't the driver; section
3.2 (region) points to what is.

### 3.2 Regional split

| Region | March Redemptions | March Cash | June Redemptions | June Cash | Redemption Δ | Cash Δ |
|---|---:|---:|---:|---:|---:|---:|
| NAMER | 15,977 | $3,765,163 | 15,632 | $3,323,670 | -2.2% | **-11.7%** |
| EMEA | 10,024 | $2,050,416 | 11,328 | $1,992,142 | +13.0% | -2.8% |
| **India** | **4,329** | **$381,264** | **11,329** | **$894,089** | **+161.7%** | **+134.5%** |
| Non-India APAC | 3,931 | $681,337 | 5,320 | $781,605 | +35.3% | +14.7% |
| LatAm | 4,083 | $634,479 | 4,279 | $605,136 | +4.8% | -4.6% |

India redemptions grew +162% and India cash grew +135% — by far the largest mover of any region.
India has materially lower per-user revenue than other regions (high price sensitivity, per the
promo skill docs), so a region-mix shift this large plausibly explains most of the cash-per-
redemption decline in 3.1. Meanwhile NAMER cash declined 11.7% even as the tentpole's total cash
grew — nearly all of June's growth came from lower-revenue-per-user markets, not the highest-value
region. See Appendix note A1 on a possible overlap with another team member's WIP analysis.

### 3.3 Page-level attribution

| Page Type | March Redemptions | March % | June Redemptions | June % |
|---|---:|---:|---:|---:|
| cplus_description | 19,182 | 50.0% | 26,680 | **55.7%** |
| lohp (logged-out homepage) | 5,756 | 15.0% | 5,136 | **10.7%** |
| xdp_course | 3,755 | 9.8% | 4,398 | 9.2% |
| xdp_professional_cert | 3,280 | 8.6% | 4,161 | 8.7% |
| xdp_s12n | 2,379 | 6.2% | 3,298 | 6.9% |
| xdp_paid_media | 1,758 | 4.6% | 1,424 | 3.0% |
| Direct / No Attribution | 1,443 | 3.8% | 1,992 | 4.2% |
| lihp (logged-in homepage) | 389 | 1.0% | 474 | 1.0% |
| Other (browse, xdp_project, C+ Page, etc.) | ~245 | 0.6% | ~328 | 0.7% |

`cplus_description` (the C+ plan page) share rose from 50% to 56% of attributed redemptions, while
`lohp` fell from 15% to 11%. Reads as a shift toward more direct-to-plan-page traffic and less
homepage-driven discovery — a correlational read from attribution data, not a causal one (could
reflect a merchandising placement change, a CRM/email push straight to the plan page, or something
else). See Appendix note A2.

### 3.4 Traffic source / channel

| Channel × Payer Type | March Redemptions | March % | June Redemptions | June % |
|---|---:|---:|---:|---:|
| NPL Organic | 13,201 | 34.4% | 16,076 | 33.6% |
| NPL Paid | 13,157 | 34.3% | 17,194 | 35.9% |
| Non-NPL Organic | 8,778 | 22.9% | 10,336 | 21.6% |
| Non-NPL Paid | 3,217 | 8.4% | 4,293 | 9.0% |

Channel mix is broadly stable — roughly 55/45 Organic/Paid for both tentpoles — with a slight tilt
toward Paid in June for both NPL and Non-NPL. Not a dramatic shift either direction.

## 4. Appendix

**A1 — India finding may overlap with existing WIP.** The DS intake sheet lists a WIP item (owned
by someone else, not part of this skill's scope) specifically diagnosing "Q2 June Tentpole impact
from the High-LTV geo pricing test + India subscriptions product test" (intake row 2.7, presented
to a stakeholder 2026-07-07). The India surge in section 3.2 may be exactly what that analysis
already covers — check with that owner before this becomes a second, possibly conflicting read on
the same underlying driver.

**A2 — Page-level attribution is correlational, not causal.** Section 3.3's shift toward
`cplus_description` and away from `lohp` describes what changed in attributed traffic, not why. Do
not present this as a proven cause without further investigation (e.g. checking for a merchandising
placement or CRM campaign change between the two tentpoles).

**A3 — Data provisionality.** June Tentpole 2026 ended 2026-07-13; as of this writing (2026-07-14)
it is still inside the standard 2-day late-arrival reconciliation window (see
[../references/known-corrections.md](../references/known-corrections.md)). All June Tentpole
numbers above should be treated as provisional and re-pulled after ~2026-07-16 before external use.
March Tentpole (ended 2026-04-29) is fully reconciled and stable.

**A4 — Sources.** All numbers pulled from
[../queries/q2_tentpole_base_metrics.sql](../queries/q2_tentpole_base_metrics.sql),
[../queries/q2_region_split_2_2.sql](../queries/q2_region_split_2_2.sql),
[../queries/q2_page_level_split_2_3.sql](../queries/q2_page_level_split_2_3.sql), and
[../queries/q2_traffic_source_2_4.sql](../queries/q2_traffic_source_2_4.sql), filtered to March
Tentpole 2026 and June Tentpole 2026. Campaign definitions (promotion_ids, date windows) per
[../references/campaign-registry.md](../references/campaign-registry.md).
