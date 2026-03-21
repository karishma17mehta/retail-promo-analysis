-- Step 1: get first order date per customer
CREATE TABLE customer_first_order AS
SELECT 
    m.customer_id,
    m.discount_flag AS acquired_via_discount,
    m.order_date AS first_order_date
FROM master_orders m
INNER JOIN (
    SELECT customer_id, MIN(order_date) AS first_date
    FROM master_orders
    GROUP BY customer_id
) first ON m.customer_id = first.customer_id 
       AND m.order_date = first.first_date;

-- Step 2: count total orders per customer
CREATE TABLE customer_order_counts AS
SELECT customer_id, COUNT(*) AS total_orders
FROM master_orders
GROUP BY customer_id;

-- Step 3: THE HERO QUERY — repeat rate by acquisition type
SELECT
    acquired_via_discount,
    COUNT(*) AS total_customers,
    SUM(CASE WHEN total_orders > 1 THEN 1 ELSE 0 END) AS repeat_customers,
    ROUND(100.0 * SUM(CASE WHEN total_orders > 1 THEN 1 ELSE 0 END) 
          / COUNT(*), 2) AS repeat_rate_pct
FROM customer_first_order f
JOIN customer_order_counts c ON f.customer_id = c.customer_id
GROUP BY acquired_via_discount;