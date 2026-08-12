-- ============================================================
-- Supplementary analyses for the dashboard.
-- These open a SECOND storyline (delivery/operations) alongside the
-- promotion storyline, and use tables the original analysis never touched.
-- ============================================================
USE Olist_dataset;

-- ------------------------------------------------------------
-- A. DELIVERY PERFORMANCE vs SATISFACTION   ** strongest finding **
-- Dose-response: review score collapses the moment an order is late,
-- then plateaus. Being 15 days late is barely worse than being 6.
-- Tableau: bar chart, bucket on X, avg review on Y, order count as label.
-- ------------------------------------------------------------
SELECT
    CASE WHEN d <= -5 THEN '1. early 5d+'
         WHEN d <=  0 THEN '2. on time'
         WHEN d <=  5 THEN '3. late 1-5d'
         WHEN d <= 15 THEN '4. late 6-15d'
         ELSE              '5. late 15d+' END          AS delivery_bucket,
    COUNT(*)                                           AS orders_,
    ROUND(AVG(review_score), 2)                        AS avg_review_score
FROM (
    SELECT DATEDIFF(o.order_delivered_customer_date,
                    o.order_estimated_delivery_date)   AS d,
           r.review_score
    FROM orders o
    JOIN (SELECT order_id, AVG(review_score) AS review_score
          FROM order_reviews GROUP BY order_id) r ON o.order_id = r.order_id
    WHERE o.order_status = 'delivered'
      AND o.order_delivered_customer_date IS NOT NULL
) t
GROUP BY delivery_bucket
ORDER BY delivery_bucket;

-- ------------------------------------------------------------
-- B. LATE DELIVERY RATE BY STATE
-- Tableau: filled map of Brazil, colour = late_pct.
-- ------------------------------------------------------------
SELECT
    c.customer_state,
    COUNT(*)                                            AS orders_,
    -- "Late" is defined the SAME way as in query A: whole days, via DATEDIFF.
    -- Comparing raw timestamps instead counts an order delivered at 23:00 on
    -- the estimated date as late, and shifts MA from 17.4% to 19.7%.
    -- One definition, used everywhere -- or two charts will disagree.
    ROUND(100.0 * SUM(DATEDIFF(o.order_delivered_customer_date,
                               o.order_estimated_delivery_date) > 0)
          / COUNT(*), 1)                                AS late_pct
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
GROUP BY c.customer_state
HAVING COUNT(*) > 500
ORDER BY late_pct DESC;

-- ------------------------------------------------------------
-- C. STATE ECONOMICS: revenue, discounting, freight burden
-- Remote states show HIGHER 90-day revenue AND higher freight --
-- customers there appear to consolidate purchases to justify shipping.
-- Tableau: map coloured by avg_90d, or scatter freight vs revenue.
-- ------------------------------------------------------------
SELECT
    m.customer_state,
    COUNT(DISTINCT m.customer_unique_id)      AS customers,
    ROUND(AVG(l.ltv_90d), 2)                  AS avg_90d_revenue,
    ROUND(100.0 * AVG(m.discount_flag), 1)    AS discount_pct,
    ROUND(AVG(m.freight_value), 2)            AS avg_freight,
    ROUND(100.0 * AVG(m.freight_value)
          / AVG(m.price), 1)                  AS freight_pct_of_price
FROM master_orders m
JOIN customer_ltv l ON m.customer_unique_id = l.customer_unique_id
GROUP BY m.customer_state
HAVING COUNT(DISTINCT m.customer_unique_id) > 500
ORDER BY avg_90d_revenue DESC;

-- ------------------------------------------------------------
-- D. MONTHLY TREND (context / title-slide chart)
-- Discount rate is remarkably STABLE (68-72%) while volume grows --
-- i.e. discounting is a permanent posture here, not a campaign lever.
-- Tableau: dual-axis line -- revenue bars, discount % line.
-- ------------------------------------------------------------
SELECT
    DATE_FORMAT(order_date, '%Y-%m')          AS yearmonth,
    COUNT(DISTINCT order_id)                  AS orders_,
    ROUND(SUM(price), 0)                      AS revenue,
    ROUND(100.0 * AVG(discount_flag), 1)      AS discount_pct
FROM master_orders
WHERE order_date >= '2017-01-01'
  AND order_date <  '2018-08-01'   -- last month is partial; excluded
GROUP BY yearmonth
ORDER BY yearmonth;

-- ------------------------------------------------------------
-- E. PAYMENT BEHAVIOUR by acquisition type  (uses order_payments)
-- Full-price buyers use ~4 installments and 65% finance; discount
-- buyers 2.5 and 44%. Read with care: installment use rises with
-- order value, so this partly restates the price difference.
-- ------------------------------------------------------------
SELECT
    f.acquired_via_discount,
    ROUND(AVG(p.payment_installments), 2)                        AS avg_installments,
    ROUND(100.0 * SUM(p.payment_installments > 1)/COUNT(*), 1)   AS pct_using_installments,
    ROUND(AVG(p.payment_value), 2)                               AS avg_payment
FROM customer_first_order f
JOIN master_orders m  ON f.customer_unique_id = m.customer_unique_id
                     AND m.order_date = f.first_order_date
JOIN order_payments p ON m.order_id = p.order_id
GROUP BY f.acquired_via_discount;
