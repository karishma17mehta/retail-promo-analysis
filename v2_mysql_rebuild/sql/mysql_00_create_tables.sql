-- ============================================================
-- Olist raw table definitions (MySQL)
-- Run against the Olist_dataset schema.
-- ============================================================
USE Olist_dataset;

DROP TABLE IF EXISTS order_items, order_payments, order_reviews,
                     orders, customers, products, sellers, category_translation;

-- ---------- customers ----------
-- customer_id is one row PER ORDER. customer_unique_id is the person.
CREATE TABLE customers (
    customer_id              CHAR(32)    NOT NULL,
    customer_unique_id       CHAR(32)    NOT NULL,
    customer_zip_code_prefix CHAR(5),          -- identifier, not a number: keeps leading zeros
    customer_city            VARCHAR(64),
    customer_state           CHAR(2),
    PRIMARY KEY (customer_id),
    KEY idx_cust_unique (customer_unique_id)   -- we join/group on this constantly
);

-- ---------- orders ----------
CREATE TABLE orders (
    order_id                      CHAR(32)    NOT NULL,
    customer_id                   CHAR(32)    NOT NULL,
    order_status                  VARCHAR(16),
    order_purchase_timestamp      DATETIME,
    order_approved_at             DATETIME NULL,   -- 160 missing
    order_delivered_carrier_date  DATETIME NULL,
    order_delivered_customer_date DATETIME NULL,   -- 2,965 missing
    order_estimated_delivery_date DATETIME NULL,
    PRIMARY KEY (order_id),
    KEY idx_orders_customer (customer_id),
    KEY idx_orders_status   (order_status)
);

-- ---------- order_items ----------
-- GRAIN: one row per item line on an order. The composite PK states that.
CREATE TABLE order_items (
    order_id            CHAR(32)      NOT NULL,
    order_item_id       TINYINT       NOT NULL,   -- sequence within order, max 21
    product_id          CHAR(32)      NOT NULL,
    seller_id           CHAR(32)      NOT NULL,
    shipping_limit_date DATETIME,
    price               DECIMAL(10,2),            -- money: never FLOAT
    freight_value       DECIMAL(10,2),
    PRIMARY KEY (order_id, order_item_id),
    KEY idx_items_product (product_id)
);

-- ---------- order_reviews ----------
-- NOTE: review_id is NOT unique (99,224 rows / 98,410 distinct ids) and an
-- order can have up to 3 reviews. There is no natural primary key here, which
-- is exactly why joining this table directly to items duplicates rows.
CREATE TABLE order_reviews (
    review_id               CHAR(32),
    order_id                CHAR(32) NOT NULL,
    review_score            TINYINT,
    review_comment_title    VARCHAR(255),
    review_comment_message  TEXT,
    review_creation_date    DATETIME,
    review_answer_timestamp DATETIME,
    KEY idx_rev_order (order_id)
);

-- ---------- products ----------
CREATE TABLE products (
    product_id                 CHAR(32) NOT NULL,
    product_category_name      VARCHAR(64),   -- 610 rows are NULL
    product_name_lenght        INT NULL,      -- misspelling is in the source data
    product_description_lenght INT NULL,
    product_photos_qty         INT NULL,
    product_weight_g           INT NULL,
    product_length_cm          INT NULL,
    product_height_cm          INT NULL,
    product_width_cm           INT NULL,
    PRIMARY KEY (product_id),
    KEY idx_prod_cat (product_category_name)
);

-- ---------- sellers ----------
CREATE TABLE sellers (
    seller_id              CHAR(32) NOT NULL,
    seller_zip_code_prefix CHAR(5),
    seller_city            VARCHAR(64),
    seller_state           CHAR(2),
    PRIMARY KEY (seller_id)
);

-- ---------- order_payments ----------
CREATE TABLE order_payments (
    order_id             CHAR(32) NOT NULL,
    payment_sequential   TINYINT  NOT NULL,
    payment_type         VARCHAR(20),
    payment_installments TINYINT,
    payment_value        DECIMAL(10,2),
    PRIMARY KEY (order_id, payment_sequential)
);

-- ---------- category_translation ----------
CREATE TABLE category_translation (
    product_category_name         VARCHAR(64) NOT NULL,
    product_category_name_english VARCHAR(64),
    PRIMARY KEY (product_category_name)
);
