WITH customer_metrics AS (SELECT
c.customer_id,
c.country,
c.age_range,
COUNT(DISTINCT s.sale_id) as total_sales,
SUM(s.total_amount) as total_spent,
round(AVG(s.total_amount),2) as avg_spent,
MIN(s.sale_date) as first_purchase,
MAX(s.sale_date) as most_recent_purchase,
c.signup_date
FROM customers c
JOIN sales s ON c.customer_id = s.customer_id
GROUP BY c.customer_id
ORDER BY total_sales DESC
)

SELECT * FROM customer_metrics;

WITH weekly_regional_performance AS (
    SELECT
    DATE_FORMAT(s.sale_date, '%Y-%U') as sale_week,
    c.country,
    COUNT(DISTINCT c.customer_id) as total_customers,
    SUM(s.total_amount) as total_revenue,
    round(AVG(s.total_amount),2) as avg_revenue_per_sale
    FROM customers c
    JOIN sales s ON c.customer_id = s.customer_id
    GROUP BY sale_week, c.country
    ORDER BY sale_week ASC
);

WITH age_group AS (
    SELECT
    c.age_range,
    s.channel,
    COUNT(DISTINCT s.sale_id) as total_customers,
    SUM(s.total_amount) as total_revenue,
    round(AVG(s.total_amount),2) as avg_revenue
    FROM customers c
    JOIN sales s ON c.customer_id = s.customer_id
    GROUP BY c.age_range, s.channel
);

SELECT
count(*)
WITH campaign_signups AS (
    SELECT 
    CASE
        WHEN c.signup_date BETWEEN '2025-04-01' AND '2025-04-07' THEN 'Spring Flash Sale'
        WHEN c.signup_date BETWEEN '2025-04-08' AND '2025-04-15' THEN 'Easter Promotion'
        WHEN c.signup_date BETWEEN '2025-05-01' AND '2025-05-09' THEN "Mother's Day Campaign"
        WHEN c.signup_date BETWEEN '2025-05-10' AND '2025-05-19' THEN 'Mid-Season Clearance'
        WHEN c.signup_date BETWEEN '2025-05-20' AND '2025-05-31' THEN 'TIVA Week'
        WHEN c.signup_date BETWEEN '2025-06-01' AND '2025-06-09' THEN 'June Price Drop'
        WHEN c.signup_date BETWEEN '2025-06-10' AND '2025-06-17' THEN 'Early Summer Deals'
        ELSE 'Other'
    END AS campaign_name,
    COUNT(DISTINCT c.customer_id) as signups,
    SUM(s.total_amount) as total_revenues,
    COUNT(DISTINCT s.sale_id) as total_sales
    FROM customers c
    JOIN sales s ON c.customer_id = s.customer_id
    WHERE
    c.signup_date BETWEEN '2025-04-01' AND '2025-4-15' OR
    c.signup_date BETWEEN '2025-05-01' AND '2025-06-17'
    GROUP BY 
    campaign_name
);

WITH weekly_trends AS (
    SELECT
     DATE_FORMAT(s.sale_date, '%Y-%U') as sale_week,
    COUNT(DISTINCT c.customer_id) as total_customers,
    SUM(s.total_amount) as total_revenue,
    round(AVG(s.total_amount),2) as avg_revenue
    FROM customers c
    JOIN sales s ON c.customer_id = s.customer_id
    GROUP BY sale_week
    ORDER BY sale_week
);

With daily_sales AS (
    SELECT 
    s.sale_date,
    COUNT(DISTINCT s.sale_id) AS total_sales,
    SUM(s.total_amount) AS total_revenue
    FROM sales s
    GROUP BY s.sale_date
    ORDER BY s.sale_date
);

WITH moving_avg_sales AS (
 SELECT
    sale_date,
    daily_revenue,
    ROUND(
        AVG(daily_revenue) OVER (
            ORDER BY sale_date
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ), 2
    ) AS moving_avg_3days_revenue
FROM (
    SELECT 
        sale_date,
        SUM(total_amount) AS daily_revenue
    FROM sales
    GROUP BY sale_date
) AS t
ORDER BY sale_date
);

WITH product_sales AS (
    SELECT
    p.category,
    COUNT(s.sale_id) AS times_sold,
    SUM(si.quantity) AS quantity,
    SUM(si.unit_price * si.quantity) AS total_revenue,
    SUM(p.cost_price * si.quantity) AS total_cost,
    SUM(si.unit_price * si.quantity)-SUM(p.cost_price * si.quantity) AS profit,
    (SUM(si.unit_price * si.quantity) - SUM(p.cost_price * si.quantity)) / SUM(si.unit_price * si.quantity) AS gross_profit_margin
    FROM sales s
    JOIN sales_items si
    ON  si.sale_id = s.sale_id
    JOIN products p
    ON p.product_id = si.product_id
    GROUP BY p.category
    ORDER BY profit DESC
);


WITH top_5_weekly_products AS (
    SELECT
    DATE_FORMAT(s.sale_date, '%Y-%U') as sale_week,
    p.product_name,
    SUM(si.quantity) AS total_quantity,
    SUM(si.unit_price * si.quantity) AS total_revenue,
    ROW_NUMBER() OVER (PARTITION BY  DATE_FORMAT(s.sale_date, '%Y-%U') ORDER BY SUM(si.quantity) DESC) AS weekly_rank
    FROM sales s
    JOIN sales_items si
    ON  si.sale_id = s.sale_id
    JOIN products p
    ON p.product_id = si.product_id
    GROUP BY sale_week, p.product_name
    ORDER BY sale_week
)

SELECT 
    sale_week,
    product_name,
    total_quantity,
    weekly_rank
FROM top_5_weekly_products
WHERE weekly_rank <= 5
ORDER BY sale_week, weekly_rank;



WITH channel_performance AS (
    SELECT 
    s.channel,
    COUNT (DISTINCT s.customer_id) AS total_customers,
    COUNT( DISTINCT sale_id) AS total_sales,
    round(AVG(s.total_amount),2) AS avg_revenue,
    round(SUM(s.total_amount),2) AS total_revenue,
    SUM(CASE WHEN s.discounted = 1 THEN s.total_amount ELSE 0 END) AS discounted_revenue
    FROM sales s 
    GROUP BY s.channel
);

WITH profit_vs_rev AS (
    SELECT
    DATE_FORMAT(s.sale_date,'%Y-%U') AS sale_week,
    SUM(si.unit_price * si.quantity) AS total_revenue,
    SUM(p.cost_price * si.quantity) AS total_cost,
    SUM(si.unit_price * si.quantity)-SUM(p.cost_price * si.quantity) AS profit,
    LAG(SUM(si.unit_price * si.quantity)-SUM(p.cost_price * si.quantity), 1, 0) OVER (ORDER BY DATE_FORMAT(s.sale_date,'%Y-%U')) AS prev_profit
    FROM sales s
    JOIN sales_items si
    ON  si.sale_id = s.sale_id
    JOIN products p
    ON p.product_id = si.product_id
    GROUP BY sale_week
    ORDER BY sale_week
)

WITH inventory_analysis AS (
    SELECT 
    p.category,
    st.country,
    SUM(st.stock_quantity) as total_stock
    FROM stock st
    JOIN products p ON p.product_id = st.product_id
    GROUP BY p.category,st.country
)

    SELECT
    ia.category,
    ia.country,
    ia.total_stock,
    SUM(si.quantity) AS total_sold
    FROM products p 
    JOIN sales_items si
    ON p.product_id = si.product_id
    JOIN sales s
    ON si.sale_id = s.sale_id
    JOIN inventory_analysis ia
    ON ia.category = p.category AND ia.country = s.country
    GROUP BY ia.category, ia.country, ia.total_stock;






























