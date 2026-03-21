-- 1. Revenue by category (top 15)
SELECT 
    category,
    COUNT(*) as order_count,
    ROUND(SUM(price), 2) as total_revenue,
    ROUND(AVG(price), 2) as avg_price
FROM master_orders
WHERE category IS NOT NULL
GROUP BY category
ORDER BY total_revenue DESC
LIMIT 15;

-- 2. Discount rate by category
SELECT 
    category,
    COUNT(*) as total_orders,
    ROUND(100.0 * SUM(discount_flag) / COUNT(*), 1) as discount_rate_pct
FROM master_orders
WHERE category IS NOT NULL
GROUP BY category
ORDER BY discount_rate_pct DESC
LIMIT 15;

-- 3. Review score by discount flag
SELECT 
    discount_flag,
    ROUND(AVG(review_score), 2) as avg_review_score,
    COUNT(*) as order_count
FROM master_orders
WHERE review_score IS NOT NULL
GROUP BY discount_flag;

-- 4. Average order value by discount flag
SELECT
    discount_flag,
    ROUND(AVG(price), 2) as avg_order_value,
    ROUND(AVG(freight_value), 2) as avg_freight
FROM master_orders
GROUP BY discount_flag;

-- 5. Repeat customer rate overall
SELECT
    ROUND(100.0 * SUM(CASE WHEN order_count > 1 THEN 1 END) 
    / COUNT(*), 2) AS repeat_rate_pct,
    COUNT(*) as total_customers,
    SUM(CASE WHEN order_count > 1 THEN 1 END) as repeat_customers
FROM (
    SELECT customer_id, COUNT(*) as order_count
    FROM master_orders
    GROUP BY customer_id
) sub;