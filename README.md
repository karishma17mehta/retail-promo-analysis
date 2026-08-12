# Retail Promotion Effectiveness Analysis

> Do promotional discounts drive long-term customer value — or train customers to wait for sales?

## 📊 Live Dashboard
[View on Tableau Public](https://public.tableau.com/app/profile/karishma.mehta8733/viz/RetailPromotionEffectivenessOlistAnalysis/Dashboard1) — two tabs: promotion effectiveness, and delivery performance.

## Key Findings
- Discount-acquired customers generate **$73 vs $287** in 90-day revenue — a 74% gap (person-level, n=92,098 customers)
- OLS regression: discount acquisition is associated with **–159 BRL** in 90-day revenue after controlling for category, seasonality, and freight (95% CI [–160.7, –157.8], p<0.001, n=91,184)
- Finding is **robust** — holds under a strict discount definition (bottom 25th percentile of category price: –92 BRL, p<0.001)
- Repeat purchasing is structurally rare at Olist (**~3% of customers**, nearly identical across acquisition types) — so discounting doesn't cause churn; it **attracts low-spend, one-time customers** in the first place
- **Delivery timing matters ~100× more than price to satisfaction.** Review scores span 2.6 stars from early to very late delivery, against 0.02 stars between discounted and full-price orders. Each day past the promised date costs 0.37 stars — but only for six days, after which the score has bottomed out
- Observational data with a price-based discount proxy — read effects as *associations*, not causal estimates; a pricing A/B test is the right next step

## Data Correction (Jul 2026)
An earlier version keyed customer analysis on `customer_id`, which in Olist is unique **per order** — the person-level key is `customer_unique_id`. After correcting the join key:
- The core LTV finding **strengthened** (gap widened from 70% to 74%; regression coefficient essentially unchanged at –159 BRL)
- The RFM/churn claims were **retracted**: apparent "repeat purchases" were multi-item orders, and true repeat rates are ~3% for both acquisition groups

## Tools & Methods
MySQL · Python (Pandas, Statsmodels) · Tableau

## Methods Used
- SQL ETL pipeline from raw CSVs to recommendation, verified stage by stage
- Promotion proxy engineering (no discount field exists in the source)
- OLS regression with category, seasonality, and freight controls
- Robustness check under a stricter discount definition (bottom 25th percentile)
- Delivery-performance analysis: piecewise fit isolating the six-day window where satisfaction moves

*(v1 also included RFM segmentation; those claims did not survive the person-level correction and were retracted — see `v1_original_analysis/README.md`.)*

## Dataset
Olist Brazilian E-Commerce — [Kaggle](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)
100k+ orders, 42 product categories, 2016–2018
*Raw data not included in repo — download from Kaggle link above*

## Structure

The project exists in two versions. **Run v2.**

| Folder | What it is |
|---|---|
| [**`v1_original_analysis/`**](v1_original_analysis) | the first pass — SQLite pipeline, Python notebooks, charts. Kept for history; carries known defects, documented in its README |
| [**`v2_mysql_rebuild/`**](v2_mysql_rebuild) | **current.** Rebuilt in MySQL from the raw CSVs, verified stage by stage, plus Tableau exports |
| `data/` | raw Kaggle CSVs (shared input) |
| [`PROJECT_BRIEF.md`](PROJECT_BRIEF.md) | 2-page write-up: objective, method, findings, limitations |

Each version folder has its own README. v1's lists what it got wrong; v2's
lists the expected row count at every stage so the build can be verified
rather than trusted.

## Why there are two versions

v1 was published, then audited. Two rounds of defects surfaced — a person-level
key that made repeat detection impossible, and three join errors that inflated
revenue and silently dropped rows. v2 rebuilds the whole pipeline in a
different database engine, reconciling every stage against an independent
implementation. The revenue finding survived and strengthened; the retention
claims did not and were retracted.

## Business Question
Do promotional discounts drive long-term customer value at Olist — or do they attract one-time buyers and erode margins?

## Recommendation
Olist's discounting strategy generates transaction volume without generating customer value. Electronics and food_drink are priority targets for promotional restructuring based on high discount rates (75–76%) and among the lowest 90-day customer revenue of any major category ($72–83 vs $141 average).