-- NOTE: keys on customer_unique_id (the person), not customer_id (which is
-- unique per order in Olist). Keying on customer_id makes repeat detection
-- structurally impossible — an earlier version of this analysis did exactly
-- that, and its "repeat customers" were actually multi-item orders.

-- Step 1: get first order per person
CREATE TABLE customer_first_order AS
SELECT
    m.customer_unique_id,
    MAX(m.discount_flag) AS acquired_via_discount,  -- any item in first order below category avg
    first.first_date     AS first_order_date
FROM master_orders m
INNER JOIN (
    SELECT customer_unique_id, MIN(order_date) AS first_date
    FROM master_orders
    GROUP BY customer_unique_id
) first ON m.customer_unique_id = first.customer_unique_id
       AND m.order_date = first.first_date
GROUP BY m.customer_unique_id, first.first_date;

-- Step 2: count distinct orders per person (not rows — rows are items)
CREATE TABLE customer_order_counts AS
SELECT customer_unique_id, COUNT(DISTINCT order_id) AS total_orders
FROM master_orders
GROUP BY customer_unique_id;

-- Step 3: THE HERO QUERY — repeat rate by acquisition type
SELECT
    acquired_via_discount,
    COUNT(*) AS total_customers,
    SUM(CASE WHEN total_orders > 1 THEN 1 ELSE 0 END) AS repeat_customers,
    ROUND(100.0 * SUM(CASE WHEN total_orders > 1 THEN 1 ELSE 0 END)
          / COUNT(*), 2) AS repeat_rate_pct
FROM customer_first_order f
JOIN customer_order_counts c ON f.customer_unique_id = c.customer_unique_id
GROUP BY acquired_via_discount;
