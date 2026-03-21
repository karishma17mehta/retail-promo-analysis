DROP TABLE IF EXISTS master_orders;

CREATE TABLE master_orders AS
SELECT
    o.order_id,
    o.customer_id,
    o.order_purchase_timestamp AS order_date,
    o.order_status,
    c.customer_city,
    c.customer_state,
    p.product_category_name AS category_raw,
    ct.product_category_name_english AS category,
    oi.price,
    oi.freight_value,
    r.review_score,
    CASE 
        WHEN oi.price < cat_avg.avg_price THEN 1 
        ELSE 0 
    END AS discount_flag
FROM orders o
JOIN order_items oi       ON o.order_id = oi.order_id
JOIN products p           ON oi.product_id = p.product_id
JOIN customers c          ON o.customer_id = c.customer_id
LEFT JOIN order_reviews r ON o.order_id = r.order_id
LEFT JOIN category_translation ct 
    ON p.product_category_name = ct.product_category_name
JOIN (
    SELECT p2.product_category_name, AVG(oi2.price) AS avg_price
    FROM order_items oi2
    JOIN products p2 ON oi2.product_id = p2.product_id
    GROUP BY p2.product_category_name
) cat_avg ON p.product_category_name = cat_avg.product_category_name
WHERE o.order_status = 'delivered';