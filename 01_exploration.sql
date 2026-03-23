-- ============================================================
-- PROJECT 6 — E-COMMERCE CAPSTONE
-- SQL Exploration: Brazilian Olist Dataset (SQLite)
-- ============================================================
-- How to run:
--   Option A (Python): Use the loader block at the bottom of
--                      this file to load master_table.csv into
--                      SQLite and execute these queries.
--   Option B (CLI):    sqlite3 ecommerce.db < 01_exploration.sql
-- ============================================================


-- ──────────────────────────────────────────────────────────────
-- SECTION 1: BUSINESS OVERVIEW
-- ──────────────────────────────────────────────────────────────

-- Q1: Total revenue, orders and unique customers
SELECT
    COUNT(DISTINCT order_id)          AS total_orders,
    COUNT(DISTINCT customer_unique_id) AS unique_customers,
    ROUND(SUM(total_payment), 2)      AS total_revenue_brl,
    ROUND(AVG(total_payment), 2)      AS avg_order_value_brl
FROM master_table;


-- Q2: Monthly revenue trend
SELECT
    STRFTIME('%Y-%m', order_purchase_timestamp) AS month,
    COUNT(DISTINCT order_id)                    AS orders,
    ROUND(SUM(total_payment), 2)                AS monthly_revenue,
    ROUND(AVG(total_payment), 2)                AS avg_order_value
FROM master_table
GROUP BY month
ORDER BY month;


-- Q3: Year-over-year revenue growth
SELECT
    STRFTIME('%Y', order_purchase_timestamp) AS year,
    COUNT(DISTINCT order_id)                 AS orders,
    ROUND(SUM(total_payment), 2)             AS annual_revenue
FROM master_table
GROUP BY year
ORDER BY year;


-- ──────────────────────────────────────────────────────────────
-- SECTION 2: CUSTOMER ANALYSIS
-- ──────────────────────────────────────────────────────────────

-- Q4: Top 10 customers by total spend
SELECT
    customer_unique_id,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(SUM(total_payment), 2) AS total_spent,
    ROUND(AVG(total_payment), 2) AS avg_order_value
FROM master_table
GROUP BY customer_unique_id
ORDER BY total_spent DESC
LIMIT 10;


-- Q5: Customer order frequency distribution
SELECT
    total_orders,
    COUNT(*) AS num_customers,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS pct_customers
FROM (
    SELECT customer_unique_id,
           COUNT(DISTINCT order_id) AS total_orders
    FROM master_table
    GROUP BY customer_unique_id
) t
GROUP BY total_orders
ORDER BY total_orders;


-- Q6: Repeat vs one-time customers
SELECT
    CASE
        WHEN order_count = 1 THEN 'One-Time'
        WHEN order_count BETWEEN 2 AND 3 THEN 'Occasional (2-3)'
        ELSE 'Loyal (4+)'
    END AS customer_type,
    COUNT(*) AS customers,
    ROUND(AVG(total_spent), 2) AS avg_lifetime_value
FROM (
    SELECT
        customer_unique_id,
        COUNT(DISTINCT order_id) AS order_count,
        SUM(total_payment) AS total_spent
    FROM master_table
    GROUP BY customer_unique_id
) t
GROUP BY customer_type
ORDER BY customers DESC;


-- ──────────────────────────────────────────────────────────────
-- SECTION 3: PRODUCT & CATEGORY ANALYSIS
-- ──────────────────────────────────────────────────────────────

-- Q7: Top 10 product categories by revenue
SELECT
    main_category,
    COUNT(DISTINCT order_id)     AS total_orders,
    ROUND(SUM(total_payment), 2) AS total_revenue,
    ROUND(AVG(total_payment), 2) AS avg_order_value,
    ROUND(AVG(review_score), 2)  AS avg_review_score
FROM master_table
WHERE main_category IS NOT NULL
GROUP BY main_category
ORDER BY total_revenue DESC
LIMIT 10;


-- Q8: Categories with highest average review score (min 100 orders)
SELECT
    main_category,
    COUNT(DISTINCT order_id)    AS total_orders,
    ROUND(AVG(review_score), 3) AS avg_review_score,
    ROUND(SUM(total_payment), 2) AS total_revenue
FROM master_table
WHERE main_category IS NOT NULL
GROUP BY main_category
HAVING total_orders >= 100
ORDER BY avg_review_score DESC
LIMIT 10;


-- Q9: Payment type breakdown
SELECT
    payment_type,
    COUNT(*)                      AS total_orders,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS pct_orders,
    ROUND(SUM(total_payment), 2)  AS total_revenue,
    ROUND(AVG(total_payment), 2)  AS avg_order_value,
    ROUND(AVG(payment_installments), 1) AS avg_installments
FROM master_table
GROUP BY payment_type
ORDER BY total_orders DESC;


-- ──────────────────────────────────────────────────────────────
-- SECTION 4: GEOGRAPHIC ANALYSIS
-- ──────────────────────────────────────────────────────────────

-- Q10: Top 10 states by total revenue
SELECT
    customer_state,
    COUNT(DISTINCT customer_unique_id) AS unique_customers,
    COUNT(DISTINCT order_id)           AS total_orders,
    ROUND(SUM(total_payment), 2)       AS total_revenue,
    ROUND(AVG(total_payment), 2)       AS avg_order_value
FROM master_table
GROUP BY customer_state
ORDER BY total_revenue DESC
LIMIT 10;


-- Q11: Average delivery days by state
SELECT
    customer_state,
    COUNT(*)                          AS total_orders,
    ROUND(AVG(delivery_days), 1)      AS avg_delivery_days,
    ROUND(AVG(delivery_delay_days), 1) AS avg_delay_days,
    ROUND(AVG(review_score), 2)       AS avg_review_score
FROM master_table
WHERE delivery_days IS NOT NULL
GROUP BY customer_state
ORDER BY avg_delivery_days ASC
LIMIT 15;


-- Q12: States with highest late delivery rate
SELECT
    customer_state,
    COUNT(*)  AS total_orders,
    SUM(CASE WHEN delivery_delay_days > 0 THEN 1 ELSE 0 END) AS late_orders,
    ROUND(SUM(CASE WHEN delivery_delay_days > 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS late_pct
FROM master_table
WHERE delivery_delay_days IS NOT NULL
GROUP BY customer_state
HAVING total_orders >= 100
ORDER BY late_pct DESC
LIMIT 10;


-- ──────────────────────────────────────────────────────────────
-- SECTION 5: ADVANCED WINDOW FUNCTIONS
-- ──────────────────────────────────────────────────────────────

-- Q13: Running total revenue by month
SELECT
    month,
    monthly_revenue,
    ROUND(SUM(monthly_revenue) OVER (ORDER BY month ROWS UNBOUNDED PRECEDING), 2) AS cumulative_revenue
FROM (
    SELECT
        STRFTIME('%Y-%m', order_purchase_timestamp) AS month,
        ROUND(SUM(total_payment), 2) AS monthly_revenue
    FROM master_table
    GROUP BY month
) t
ORDER BY month;


-- Q14: Month-over-month revenue growth %
SELECT
    month,
    monthly_revenue,
    LAG(monthly_revenue) OVER (ORDER BY month) AS prev_month_revenue,
    ROUND(
        (monthly_revenue - LAG(monthly_revenue) OVER (ORDER BY month))
        * 100.0 / LAG(monthly_revenue) OVER (ORDER BY month),
        2
    ) AS mom_growth_pct
FROM (
    SELECT
        STRFTIME('%Y-%m', order_purchase_timestamp) AS month,
        ROUND(SUM(total_payment), 2) AS monthly_revenue
    FROM master_table
    GROUP BY month
) t
ORDER BY month;


-- Q15: Customer rank by spend within each state
SELECT
    customer_state,
    customer_unique_id,
    ROUND(total_spent, 2) AS total_spent,
    RANK() OVER (PARTITION BY customer_state ORDER BY total_spent DESC) AS state_rank
FROM (
    SELECT
        customer_state,
        customer_unique_id,
        SUM(total_payment) AS total_spent
    FROM master_table
    GROUP BY customer_state, customer_unique_id
) t
QUALIFY state_rank <= 3   -- top 3 per state
ORDER BY customer_state, state_rank;


-- ──────────────────────────────────────────────────────────────
-- SECTION 6: REVIEW & SATISFACTION ANALYSIS
-- ──────────────────────────────────────────────────────────────

-- Q16: Review score distribution
SELECT
    review_score,
    COUNT(*) AS total_reviews,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS pct_reviews
FROM master_table
WHERE review_score IS NOT NULL
GROUP BY review_score
ORDER BY review_score;


-- Q17: Does delivery delay affect review scores?
SELECT
    CASE
        WHEN delivery_delay_days <= -7  THEN 'Early (7+ days)'
        WHEN delivery_delay_days < 0    THEN 'Slightly Early'
        WHEN delivery_delay_days = 0    THEN 'On Time'
        WHEN delivery_delay_days <= 7   THEN 'Slightly Late'
        ELSE 'Very Late (7+ days)'
    END AS delivery_bucket,
    COUNT(*)                     AS total_orders,
    ROUND(AVG(review_score), 3)  AS avg_review_score
FROM master_table
WHERE delivery_delay_days IS NOT NULL AND review_score IS NOT NULL
GROUP BY delivery_bucket
ORDER BY avg_review_score DESC;


-- ============================================================
-- PYTHON LOADER — run this block in a notebook cell to
-- load master_table.csv into SQLite and execute the above SQL
-- ============================================================
-- # import sqlite3, pandas as pd
-- # df = pd.read_csv('../data/master_table.csv')
-- # con = sqlite3.connect('../data/ecommerce.db')
-- # df.to_sql('master_table', con, if_exists='replace', index=False)
-- # result = pd.read_sql_query("""PASTE_QUERY_HERE""", con)
-- # print(result)
-- ============================================================
