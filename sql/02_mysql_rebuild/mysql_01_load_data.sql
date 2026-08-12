-- ============================================================
-- Load the Olist CSVs into MySQL.
--
-- Requires local_infile enabled on BOTH sides:
--   server:  SET GLOBAL local_infile = 1;
--   client:  Workbench connection -> Advanced -> Others -> OPT_LOCAL_INFILE=1
--            (then reconnect)
--
-- Why ENCLOSED BY '"' matters: review comments contain line breaks inside
-- quoted fields. Without it MySQL splits those into extra rows and you get
-- ~104,719 review rows instead of the correct 99,224.
--
-- Why the @variables: an empty CSV field is the string '', not NULL. Loading
-- '' into a DATETIME gives 0000-00-00, and into an INT gives 0. NULLIF turns
-- genuine blanks back into NULL.
-- ============================================================
USE Olist_dataset;

-- ---------- customers (99,441) ----------
LOAD DATA LOCAL INFILE '/Users/karishmamehta/Documents/Olist_dataset/data/olist_customers_dataset.csv'
INTO TABLE customers
FIELDS TERMINATED BY ',' ENCLOSED BY '"' ESCAPED BY ''
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(customer_id, customer_unique_id, customer_zip_code_prefix, customer_city, customer_state);

-- ---------- orders (99,441) ----------
LOAD DATA LOCAL INFILE '/Users/karishmamehta/Documents/Olist_dataset/data/olist_orders_dataset.csv'
INTO TABLE orders
FIELDS TERMINATED BY ',' ENCLOSED BY '"' ESCAPED BY ''
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(order_id, customer_id, order_status, @purchase, @approved, @carrier, @delivered, @estimated)
SET order_purchase_timestamp      = NULLIF(@purchase,  ''),
    order_approved_at             = NULLIF(@approved,  ''),
    order_delivered_carrier_date  = NULLIF(@carrier,   ''),
    order_delivered_customer_date = NULLIF(@delivered, ''),
    order_estimated_delivery_date = NULLIF(@estimated, '');

-- ---------- order_items (112,650) ----------
LOAD DATA LOCAL INFILE '/Users/karishmamehta/Documents/Olist_dataset/data/olist_order_items_dataset.csv'
INTO TABLE order_items
FIELDS TERMINATED BY ',' ENCLOSED BY '"' ESCAPED BY ''
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(order_id, order_item_id, product_id, seller_id, @shiplimit, price, freight_value)
SET shipping_limit_date = NULLIF(@shiplimit, '');

-- ---------- order_reviews (99,224 -- NOT 104,719) ----------
LOAD DATA LOCAL INFILE '/Users/karishmamehta/Documents/Olist_dataset/data/olist_order_reviews_dataset.csv'
INTO TABLE order_reviews
FIELDS TERMINATED BY ',' ENCLOSED BY '"' ESCAPED BY ''
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(review_id, order_id, @score, review_comment_title, review_comment_message, @created, @answered)
SET review_score            = NULLIF(@score,    ''),
    review_creation_date    = NULLIF(@created,  ''),
    review_answer_timestamp = NULLIF(@answered, '');

-- ---------- products (32,951) ----------
LOAD DATA LOCAL INFILE '/Users/karishmamehta/Documents/Olist_dataset/data/olist_products_dataset.csv'
INTO TABLE products
FIELDS TERMINATED BY ',' ENCLOSED BY '"' ESCAPED BY ''
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(product_id, @cat, @namelen, @desclen, @photos, @weight, @length, @height, @width)
SET product_category_name      = NULLIF(@cat,     ''),
    product_name_lenght        = NULLIF(@namelen, ''),
    product_description_lenght = NULLIF(@desclen, ''),
    product_photos_qty         = NULLIF(@photos,  ''),
    product_weight_g           = NULLIF(@weight,  ''),
    product_length_cm          = NULLIF(@length,  ''),
    product_height_cm          = NULLIF(@height,  ''),
    product_width_cm           = NULLIF(@width,   '');

-- ---------- sellers (3,095) ----------
LOAD DATA LOCAL INFILE '/Users/karishmamehta/Documents/Olist_dataset/data/olist_sellers_dataset.csv'
INTO TABLE sellers
FIELDS TERMINATED BY ',' ENCLOSED BY '"' ESCAPED BY ''
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(seller_id, seller_zip_code_prefix, seller_city, seller_state);

-- ---------- order_payments (103,886) ----------
LOAD DATA LOCAL INFILE '/Users/karishmamehta/Documents/Olist_dataset/data/olist_order_payments_dataset.csv'
INTO TABLE order_payments
FIELDS TERMINATED BY ',' ENCLOSED BY '"' ESCAPED BY ''
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(order_id, payment_sequential, payment_type, payment_installments, payment_value);

-- ---------- category_translation (71) ----------
LOAD DATA LOCAL INFILE '/Users/karishmamehta/Documents/Olist_dataset/data/product_category_name_translation.csv'
INTO TABLE category_translation
FIELDS TERMINATED BY ',' ENCLOSED BY '"' ESCAPED BY ''
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(product_category_name, product_category_name_english);
