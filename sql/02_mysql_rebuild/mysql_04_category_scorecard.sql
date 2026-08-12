-- ============================================================
-- category_scorecard — the recommendation table.
-- One row per category, ranked worst-first by 90-day customer revenue.
-- Target: 42 categories (those with >200 customers)
-- ============================================================
USE Olist_dataset;

DROP TABLE IF EXISTS category_scorecard;

CREATE TABLE category_scorecard AS
SELECT
    m.category,
    COUNT(DISTINCT m.customer_unique_id)               AS total_customers,
    ROUND(100.0 * SUM(m.discount_flag) / COUNT(*), 1)  AS discount_rate_pct,
    ROUND(AVG(m.price), 2)                             AS avg_order_value,
    ROUND(AVG(m.review_score), 2)                      AS avg_review_score,
    ROUND(AVG(l.ltv_90d), 2)                           AS avg_90d_ltv,
    -- COUNT(DISTINCT CASE ...) counts PEOPLE who repeated, not item rows.
    -- SUM(CASE ...) here would count rows and inflate the rate.
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN c.total_orders > 1
                                      THEN m.customer_unique_id END)
          / COUNT(DISTINCT m.customer_unique_id), 1)   AS repeat_rate_pct
FROM master_orders m
JOIN customer_ltv          l ON m.customer_unique_id = l.customer_unique_id
JOIN customer_order_counts c ON m.customer_unique_id = c.customer_unique_id
WHERE m.category IS NOT NULL
GROUP BY m.category
-- exclude thin categories: a 40-customer average is too noisy to act on
HAVING COUNT(DISTINCT m.customer_unique_id) > 200
ORDER BY avg_90d_ltv ASC;

-- ---------- verification ----------
SELECT COUNT(*) AS categories_in_scorecard FROM category_scorecard;

SELECT category, total_customers, discount_rate_pct, avg_90d_ltv, repeat_rate_pct
FROM category_scorecard
LIMIT 6;
