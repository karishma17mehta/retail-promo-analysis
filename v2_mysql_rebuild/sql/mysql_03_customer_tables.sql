-- ============================================================
-- Person-level tables. Everything here keys on customer_unique_id.
-- ============================================================
USE Olist_dataset;

-- ---------- customer_first_order ----------
-- One row per PERSON, carrying how they were acquired.
-- The discount flag lives on ITEMS; MAX() collapses the items of the first
-- order into one value per person = "any item in the first order was flagged".
-- 575 people have a mixed first order, so this rule is a real decision:
--   MAX = any item discounted   (chosen)
--   MIN = all items discounted  (stricter, different split)
-- Target: 92,098 rows | 28,767 full-price | 63,331 discounted
DROP TABLE IF EXISTS customer_first_order;

CREATE TABLE customer_first_order AS
SELECT
    m.customer_unique_id,
    MAX(m.discount_flag) AS acquired_via_discount,
    f.first_date         AS first_order_date
FROM master_orders m
JOIN (
    SELECT customer_unique_id, MIN(order_date) AS first_date
    FROM master_orders
    GROUP BY customer_unique_id
) f ON m.customer_unique_id = f.customer_unique_id
   AND m.order_date         = f.first_date
GROUP BY m.customer_unique_id, f.first_date;

-- ---------- customer_order_counts ----------
-- COUNT(DISTINCT order_id), not COUNT(*): rows are ITEMS, and counting rows
-- would make a 3-item single order look like a repeat customer.
-- Target: 92,098 rows | 2,742 repeaters | 2.98% overall repeat rate
DROP TABLE IF EXISTS customer_order_counts;

CREATE TABLE customer_order_counts AS
SELECT customer_unique_id,
       COUNT(DISTINCT order_id) AS total_orders
FROM master_orders
GROUP BY customer_unique_id;

-- ---------- verification ----------
SELECT COUNT(*) AS people FROM customer_first_order;

SELECT acquired_via_discount, COUNT(*) AS n
FROM customer_first_order
GROUP BY acquired_via_discount;

-- the hero query: repeat rate by acquisition type
SELECT f.acquired_via_discount,
       COUNT(*)                                              AS customers,
       SUM(c.total_orders > 1)                               AS repeat_customers,
       ROUND(100.0 * SUM(c.total_orders > 1) / COUNT(*), 2)  AS repeat_rate_pct
FROM customer_first_order f
JOIN customer_order_counts c ON f.customer_unique_id = c.customer_unique_id
GROUP BY f.acquired_via_discount;
