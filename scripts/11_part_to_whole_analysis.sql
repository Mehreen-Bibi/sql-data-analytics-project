/*
===============================================================================
SECTION 11: PART-TO-WHOLE ANALYSIS
===============================================================================
Goal:
    Analyze how different business segments contribute to overall performance.
    Part-to-whole analysis helps identify the relative importance of products,
    categories, customer groups, and geographic regions by measuring their
    contribution to total revenue.

Business Questions:
    • Which product categories contribute the most revenue?
    • Which countries generate the largest share of sales?
    • Which subcategories dominate within each category?
    • How much revenue comes from different customer demographics?
    • Which products generate the first 80% of total revenue?

SQL Concepts:
    • SUM() OVER()
    • Window Functions
    • PARTITION BY
    • CASE Expressions
    • Common Table Expressions (CTEs)
===============================================================================
*/

-- ============================================================================
-- 11.1 Revenue Share by Product Category
-- Calculate each category's contribution to total revenue
-- ============================================================================
WITH category_sales AS
(
	SELECT
		p.category,
		CAST(SUM(f.sales_amount) AS FLOAT) AS total_revenue
	FROM gold.fact_sales f
	LEFT JOIN gold.dim_products p
		ON f.product_key = p.product_key
	GROUP BY p.category
)
SELECT
	category,
	ROUND((total_revenue * 100.0) /SUM(total_revenue) OVER(), 2) AS revenue_share_pct,
	ROUND((SUM(total_revenue) OVER(ORDER BY total_revenue DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) * 100.0) /
	(SUM(total_revenue) OVER()), 2) AS cumulative_share_pct
FROM category_sales
ORDER BY total_revenue DESC;

-- ============================================================================
-- 11.2 Revenue Share by Country
-- Measure each country's contribution to total revenue
-- ============================================================================
WITH country_sales AS
(
    SELECT
        c.country,
        COUNT(DISTINCT f.customer_key) AS total_customers,
        COUNT(DISTINCT f.order_number) AS total_orders,
        CAST(SUM(f.sales_amount) AS FLOAT) AS total_revenue
    FROM gold.fact_sales AS f
    LEFT JOIN gold.dim_customers AS c
        ON f.customer_key = c.customer_key
    GROUP BY c.country
)

SELECT
    country,
    total_customers,
    total_orders,
	ROUND(total_revenue * 100/ SUM(total_revenue) OVER(),2) AS revenue_share_pct,
	ROUND(SUM(total_revenue) OVER(ORDER BY total_revenue DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) * 100.0/ 
	SUM(total_revenue) OVER(), 2) AS cumulative_share_pct
FROM country_sales
ORDER BY total_revenue DESC;

-- ============================================================================
-- 11.3 Revenue Share by Product Subcategory
-- Calculate each subcategory's contribution within its parent category
-- ============================================================================
WITH subcategory_sales AS
(
    SELECT
        p.category,
        p.subcategory,
        CAST(SUM(f.sales_amount) AS FLOAT) AS total_revenue
    FROM gold.fact_sales AS f
    LEFT JOIN gold.dim_products AS p
        ON f.product_key = p.product_key
    GROUP BY
        p.category,
        p.subcategory
)
SELECT
	category,
	subcategory,
	ROUND(total_revenue * 100 / SUM(total_revenue) OVER(PARTITION BY category), 2) AS category_share_pct,
	ROUND((SUM(total_revenue) OVER(PARTITION BY category ORDER BY total_revenue DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) * 100)/
	SUM(total_revenue) OVER(PARTITION BY category), 2) AS cumulative_category_share_pct
FROM subcategory_sales
ORDER BY 
	category,
	total_revenue DESC;

-- ============================================================================
-- 11.4 Revenue Contribution by Customer Demographics
-- Compare revenue contribution across customer demographic groups
-- ============================================================================
SELECT
    c.gender,
    c.marital_status,
	COUNT(DISTINCT c.customer_key) AS total_customers,
	SUM(f.sales_amount) AS total_revenue,
	ROUND(CAST(SUM(f.sales_amount) AS FLOAT) * 100/ SUM(SUM(f.sales_amount)) OVER(), 2) AS revenue_share_pct
FROM gold.fact_sales AS f
LEFT JOIN gold.dim_customers AS c
    ON f.customer_key = c.customer_key
GROUP BY
    c.gender,
    c.marital_status
ORDER BY total_revenue DESC;

-- ============================================================================
-- 11.5 Pareto Analysis (80/20 Rule)
-- Identify products contributing to the first 80% of total revenue
-- ============================================================================
WITH product_sales AS
(
    SELECT
        p.product_name,
        p.category,
        CAST(SUM(f.sales_amount) AS FLOAT) AS total_revenue
    FROM gold.fact_sales AS f
    LEFT JOIN gold.dim_products AS p
        ON f.product_key = p.product_key
    GROUP BY
        p.product_name,
        p.category
),
pareto_analysis AS
(
    SELECT
        product_name,
        category,
        total_revenue,
		ROUND(SUM(total_revenue) OVER(ORDER BY total_revenue DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) * 100/ 
		SUM(total_revenue) OVER(), 2) AS cumulative_share_pct
	FROM product_sales
)
SELECT
    product_name,
    category,
    ROUND(total_revenue,2) AS total_revenue,
    cumulative_share_pct,
	CASE
        WHEN cumulative_share_pct <= 80 THEN 'Top Revenue Drivers'
        ELSE 'Long Tail Products'
    END AS pareto_segment
FROM pareto_analysis
ORDER BY total_revenue DESC;
