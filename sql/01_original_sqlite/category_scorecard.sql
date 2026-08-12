-- Category scorecard: your recommendation table
-- Person-level metrics key on customer_unique_id.

CREATE TABLE category_scorecard AS
SELECT
    m.category,
    COUNT(DISTINCT m.customer_unique_id) AS total_customers,
    ROUND(100.0 * SUM(m.discount_flag) / COUNT(*), 1) AS discount_rate_pct,
    ROUND(AVG(m.price), 2) AS avg_order_value,
    ROUND(AVG(m.review_score), 2) AS avg_review_score,
    ROUND(AVG(l.ltv_90d), 2) AS avg_90d_ltv,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN c.total_orders > 1 THEN m.customer_unique_id END)
          / COUNT(DISTINCT m.customer_unique_id), 1) AS repeat_rate_pct
FROM master_orders m
JOIN customer_ltv l          ON m.customer_unique_id = l.customer_unique_id
JOIN customer_order_counts c ON m.customer_unique_id = c.customer_unique_id
WHERE m.category IS NOT NULL
GROUP BY m.category
HAVING COUNT(DISTINCT m.customer_unique_id) > 200
ORDER BY avg_90d_ltv ASC;
