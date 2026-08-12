DROP TABLE IF EXISTS customer_ltv;

CREATE TABLE customer_ltv AS
SELECT
    f.customer_unique_id,
    f.acquired_via_discount,
    f.first_order_date,
    ROUND(SUM(m.price), 2) AS ltv_90d
FROM customer_first_order f
JOIN master_orders m ON f.customer_unique_id = m.customer_unique_id
WHERE m.order_date <= DATE_ADD(f.first_order_date, INTERVAL 90 DAY)
GROUP BY f.customer_unique_id, f.acquired_via_discount, f.first_order_date;

SELECT COUNT(*) AS rows_ FROM customer_ltv;

SELECT acquired_via_discount,
       COUNT(*)                AS customers,
       ROUND(AVG(ltv_90d), 2)  AS avg_90d_ltv,
       ROUND(MIN(ltv_90d), 2)  AS min_ltv,
       ROUND(MAX(ltv_90d), 2)  AS max_ltv
FROM customer_ltv GROUP BY acquired_via_discount;