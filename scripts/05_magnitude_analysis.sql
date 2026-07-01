/* 
============================================================================
SECTION 5: BUSINESS MAGNITUDE ANALYSIS
============================================================================
Goal:
    Quantify business performance across key dimensions by aggregating
    revenue, orders, customers, and products.

Business Questions:
    • Which countries generate the most revenue?
    • Which customer segments contribute the most sales?
    • Which product categories drive business performance?
    • How is revenue distributed across dimensions?
============================================================================
*/

-- ============================================================================
-- 5.1 Revenue Performance by Country
-- ============================================================================
SELECT
	c.country,
	COUNT(DISTINCT f.customer_key) AS customers,
	COUNT(DISTINCT f.order_number) AS orders,
	SUM(f.quantity) AS units_sold,
	SUM(f.sales_amount) AS total_revenue,
	ROUND(SUM(f.sales_amount)*100.0/SUM(SUM(f.sales_amount)) OVER(), 2) AS revenue_pct,
	ROUND(SUM(f.sales_amount)/COUNT(DISTINCT f.customer_key), 2) AS revenue_per_customer
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
	ON f.customer_key = c.customer_key
GROUP BY c.country
ORDER BY total_revenue DESC;

-- ============================================================================
-- 5.2 Revenue by Gender
-- ============================================================================
SELECT
	c.gender,
	COUNT(DISTINCT f.customer_key) AS customers,
	COUNT(DISTINCT f.order_number) AS orders,
	SUM(f.quantity) AS units_sold,
	SUM(f.sales_amount) AS total_revenue,
	ROUND(SUM(f.sales_amount)*100.0/SUM(SUM(f.sales_amount)) OVER(), 2) AS revenue_pct
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
	ON f.customer_key = c.customer_key
GROUP BY c.gender
ORDER BY total_revenue DESC;


-- ============================================================================
-- 5.3 Revenue by Marital Status
-- ============================================================================
SELECT
	c.marital_status,
	COUNT(DISTINCT f.customer_key) AS customers,
	COUNT(DISTINCT f.order_number) AS orders,
	SUM(f.quantity) AS units_sold,
	SUM(f.sales_amount) AS total_revenue,
	ROUND(SUM(f.sales_amount)*100.0/SUM(SUM(f.sales_amount)) OVER(), 2) AS revenue_pct
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
	ON f.customer_key = c.customer_key
GROUP BY c.marital_status
ORDER BY total_revenue DESC;

-- ============================================================================
-- 5.4 Product Category Performance
-- ============================================================================
SELECT
	p.category,
	COUNT(DISTINCT f.product_key) AS products,
	COUNT(DISTINCT f.order_number) AS orders,
	SUM(f.quantity) AS units_sold,
	SUM(f.sales_amount) AS total_revenue,
	ROUND(AVG(f.price), 2) AS avg_selling_price,
	ROUND(SUM(f.sales_amount)*100.0/SUM(SUM(f.sales_amount)) OVER(), 2) AS revenue_pct
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
	ON f.product_key = p.product_key
GROUP BY category
ORDER BY total_revenue DESC;

-- ============================================================================
-- 5.5 Product Subcategory Performance
-- ============================================================================
SELECT
	p.category,
	p.subcategory,
	COUNT(DISTINCT f.product_key) AS products,
	SUM(f.quantity) AS units_sold,
	SUM(f.sales_amount) AS total_revenue
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
	ON f.product_key = p.product_key
GROUP BY 
	p.category,
	p.subcategory
ORDER BY 
	category,
	total_revenue DESC;

-- ============================================================================
-- 5.6 Product Line Performance
-- ============================================================================
SELECT
	p.product_line,
	COUNT(DISTINCT f.product_key) AS products,
	SUM(f.quantity) AS units_sold,
	SUM(f.sales_amount) AS total_revenue,
	ROUND(AVG(f.price), 2) AS avg_selling_price
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
	ON f.product_key = p.product_key
GROUP BY p.product_line
ORDER BY total_revenue DESC;

-- ============================================================================
-- 5.7 Annual Revenue by Product Category
-- ============================================================================
SELECT
	YEAR(f.order_date) AS order_year,
	p.category,
	COUNT(DISTINCT f.customer_key) AS customers,
	SUM(f.quantity) AS units_sold,
	SUM(f.sales_amount) AS total_revenue
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
	ON f.product_key = p.product_key
WHERE f.order_date IS NOT NULL
GROUP BY 
	YEAR(f.order_date),
	p.category
ORDER BY 
	order_year,
	total_revenue DESC;

-- ============================================================================
-- 5.8 Annual Revenue by Country
-- ============================================================================
SELECT
	YEAR(f.order_date) AS order_year,
	c.country,
	COUNT(DISTINCT f.customer_key) AS customers,
	SUM(f.sales_amount) AS total_revenue
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
	ON f.customer_key = c.customer_key
WHERE f.order_date IS NOT NULL
GROUP BY 
	YEAR(f.order_date),
	c.country
ORDER BY 
	order_year, 
	total_revenue DESC;


-- ============================================================================
-- 5.9 Customer Segment Analysis
--      Revenue by Age Group and Gender
-- ============================================================================
WITH customer_age AS 
(
	SELECT
		customer_key,
		gender,
		CASE
			WHEN birthdate IS NULL THEN 'n/a'
			WHEN DATEDIFF(YEAR, birthdate, GETDATE()) < 50 THEN '<50'
			WHEN DATEDIFF(YEAR, birthdate, GETDATE()) BETWEEN 50 AND 59 THEN '50-59'
			WHEN DATEDIFF(YEAR, birthdate, GETDATE()) BETWEEN 60 AND 69 THEN '60-69'
			WHEN DATEDIFF(YEAR, birthdate, GETDATE()) BETWEEN 70 AND 79 THEN '70-79'
			WHEN DATEDIFF(YEAR, birthdate, GETDATE()) BETWEEN 80 AND 89 THEN '80-89'
			ELSE '90+'
		END age_group
	FROM gold.dim_customers
)
SELECT
	age_group,
	gender,
	COUNT(DISTINCT ca.customer_key) AS customers,
    SUM(f.sales_amount) AS total_revenue,
	ROUND(AVG(f.sales_amount),2) AS avg_order_line_revenue
FROM customer_age ca
JOIN gold.fact_sales f
	ON ca.customer_key = f.customer_key
GROUP BY
	age_group,
	gender
ORDER BY total_revenue DESC;
