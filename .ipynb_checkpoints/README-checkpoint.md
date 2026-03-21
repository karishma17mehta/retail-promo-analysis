# Retail Promotion Effectiveness Analysis

> Do promotional discounts drive long-term customer value — or train customers to wait for sales?

## 📊 Live Dashboard
[View on Tableau Public](https://public.tableau.com/app/profile/karishma.mehta8733/viz/RetailPromotionEffectivenessOlistAnalysis/Dashboard1)

![Dashboard Preview](output/chart3_hero_repeat_ltv.png)

## Key Findings
- Discount-acquired customers generate **$100 vs $340** in 90-day LTV — a 70% gap
- OLS regression confirms **-$165 causal impact** on LTV after controlling for category and seasonality (p=0.0000, n=94,727)
- **100% of 'Lost' RFM customers** were discount-acquired — zero full-price customers ended up Lost
- Full-price customers are **3x more likely** to become Champions in RFM segmentation
- Finding is **robust** — holds under two independent discount definitions

## Tools & Methods
SQL · Python (Pandas, Statsmodels, Seaborn) · Tableau

## Methods Used
- SQL ETL pipeline joining 5 tables across 100k+ orders
- OLS regression with category, seasonality, and freight controls
- RFM customer segmentation
- Robustness check under strict discount definition (bottom 25th percentile)

## Dataset
Olist Brazilian E-Commerce — [Kaggle](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)
100k+ orders, 42 product categories, 2016–2018
*Raw data not included in repo — download from Kaggle link above*

## Structure
- `/sql` — master table build and business metric queries
- `/notebooks` — EDA, repeat purchase analysis, regression, RFM
- `/output` — charts and dashboard screenshots
- `/data/clean` — processed CSVs used in analysis

## Business Question
Do promotional discounts drive long-term customer value at Olist — or do they attract one-time buyers and erode margins?

## Recommendation
Olist's discounting strategy generates transaction volume without generating customer value. Electronics and food_drink are priority targets for promotional restructuring based on high discount rates and below-average 90-day LTV.