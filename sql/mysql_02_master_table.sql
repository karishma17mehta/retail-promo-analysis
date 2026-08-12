-- ============================================================
-- master_orders — one row per ITEM per ORDER (delivered only).
-- Target after build: 108,660 rows | revenue 13,050,771.48 | 95,146 orders
-- ============================================================
USE Olist_dataset;

DROP TABLE IF EXISTS master_orders;

CREATE TABLE master_orders AS
SELECT
    o.order_id,
    o.customer_id,                 -- per-ORDER id; kept for traceability only
    c.customer_unique_id,          -- the PERSON; all customer-level analysis keys on this
    o.order_purchase_timestamp AS order_date,
    o.order_status,
    c.customer_city,
    c.customer_state,
    p.product_id,                  -- needed later for a product-level markdown flag
    p.product_category_name AS category_raw,
    ct.product_category_name_english AS category,
    oi.price,
    oi.freight_value,
    rev.review_score,              -- recorded per ORDER: average over distinct orders only
    CASE WHEN oi.price < cat_avg.avg_price THEN 1 ELSE 0 END AS discount_flag

FROM orders o
JOIN order_items oi ON o.order_id    = oi.order_id
JOIN products p     ON oi.product_id = p.product_id
JOIN customers c    ON o.customer_id = c.customer_id

-- FIX 1: order_reviews has up to 3 rows per order. Collapse to one row per
-- order BEFORE joining, or every item in those orders gets duplicated (+635 rows).
LEFT JOIN (
    SELECT order_id, AVG(review_score) AS review_score
    FROM order_reviews
    GROUP BY order_id
) rev ON o.order_id = rev.order_id

LEFT JOIN category_translation ct
       ON p.product_category_name = ct.product_category_name

-- FIX 3: the benchmark must come from the same universe as the rows being
-- judged against it — delivered orders only, categories only.
JOIN (
    SELECT p2.product_category_name, AVG(oi2.price) AS avg_price
    FROM order_items oi2
    JOIN products p2 ON oi2.product_id = p2.product_id
    JOIN orders   o2 ON oi2.order_id   = o2.order_id
    WHERE o2.order_status = 'delivered'
      AND p2.product_category_name IS NOT NULL
    GROUP BY p2.product_category_name
) cat_avg ON p.product_category_name = cat_avg.product_category_name

WHERE o.order_status = 'delivered'
  -- FIX 2: state the exclusion explicitly. 610 products have no category and
  -- cannot appear in a category scorecard. Previously they vanished silently
  -- because NULL never matches in the cat_avg join.
  AND p.product_category_name IS NOT NULL;

-- ---------- verification ----------
SELECT COUNT(*)                          AS rows_,
       ROUND(SUM(price),2)               AS revenue,
       COUNT(DISTINCT order_id)          AS orders_,
       COUNT(DISTINCT customer_unique_id) AS people,
       ROUND(AVG(discount_flag)*100,1)   AS discount_rate_pct
FROM master_orders;
