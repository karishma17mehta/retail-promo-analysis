-- 90-day LTV per customer
CREATE TABLE customer_ltv AS
SELECT 
    f.customer_id,
    f.acquired_via_discount,
    f.first_order_date,
    ROUND(SUM(m.price), 2) AS ltv_90d
FROM customer_first_order f
JOIN master_orders m ON f.customer_id = m.customer_id
WHERE m.order_date <= DATE(f.first_order_date, '+90 days')
GROUP BY f.customer_id, f.acquired_via_discount, f.first_order_date;

-- Compare 90-day LTV by acquisition type
SELECT
    acquired_via_discount,
    COUNT(*) AS customers,
    ROUND(AVG(ltv_90d), 2) AS avg_90d_ltv,
    ROUND(MIN(ltv_90d), 2) AS min_ltv,
    ROUND(MAX(ltv_90d), 2) AS max_ltv
FROM customer_ltv
GROUP BY acquired_via_discount;