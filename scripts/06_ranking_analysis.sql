/*
==============================================================================
SECTION 6: BUSINESS PERFORMANCE RANKING
==============================================================================
Goal:
    Identify the best and worst performing products and customers using
    ranking techniques. Window functions are used to produce category-level,
    country-level, and year-over-year rankings.

SQL Concepts:
    • TOP
    • DENSE_RANK()
    • PARTITION BY
    • Common Table Expressions (CTEs)
==============================================================================
*/

-- ============================================================================
-- 6.1 Top 10 Products by Revenue
-- ============================================================================
SELECT TOP 10
	p.product_number,
	p.product_name,
	p.category,
	p.subcategory,
	COUNT(DISTINCT f.order_number) AS total_orders,
	SUM(f.quantity) AS total_units_sold,
	ROUND(AVG(f.price), 2) AS avg_selling_price,
	SUM(f.sales_amount) AS total_revenue,
	ROUND(SUM(f.sales_amount) * 100.0 / SUM(SUM(f.sales_amount)) OVER(), 2) AS revenue_percentage
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
	ON f.product_key = p.product_key
GROUP BY 
	p.product_number,
	p.product_name,
	p.category,
	p.subcategory
ORDER BY total_revenue DESC;

-- ============================================================================
-- 6.2 Bottom 10 Products by Revenue
-- ============================================================================
SELECT TOP 10
	p.product_number,
	p.product_name,
	p.category,
	p.subcategory,
	COUNT(DISTINCT f.order_number) AS total_orders,
	SUM(f.quantity) AS total_units_sold,
	ROUND(AVG(f.price), 2) AS avg_selling_price,
	SUM(f.sales_amount) AS total_revenue,
	ROUND(SUM(f.sales_amount) * 100.0 / SUM(SUM(f.sales_amount)) OVER(), 2) AS revenue_percentage
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
	ON f.product_key = p.product_key
GROUP BY
	p.product_number,
	p.product_name,
	p.category,
	p.subcategory
ORDER BY total_revenue;

-- ============================================================================
-- 6.3 Top 10 Customers by Lifetime Revenue
-- ============================================================================
SELECT TOP 10
	c.customer_number,
	CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
	c.country,
	SUM(f.sales_amount) AS lifetime_revenue,
	COUNT(DISTINCT f.order_number) AS total_orders,
	MIN(f.order_date) AS first_order,
	MAX(f.order_date) AS last_order,
	ROUND(SUM(f.sales_amount) / COUNT(DISTINCT f.order_number), 2) AS avg_order_value,
	DATEDIFF(DAY, MIN(f.order_date), MAX(f.order_date)) AS customer_lifetime_days
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
ON f.customer_key = c.customer_key
GROUP BY 
	c.customer_number,
	c.first_name, 
	c.last_name,
	c.country
ORDER BY lifetime_revenue DESC;

-- ============================================================================
-- 6.4 Most Active Customers
-- Customers placing the highest number of orders
-- ============================================================================
SELECT TOP 10
	c.customer_number,
	CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
	COUNT(DISTINCT f.order_number) AS total_orders,
	SUM(f.sales_amount) AS lifetime_revenue
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
	ON f.customer_key = c.customer_key
GROUP BY
	c.customer_number,
	c.first_name,
	c.last_name
ORDER BY total_orders DESC;

-- ============================================================================
-- 6.5 Top 5 Products Within Each Category
-- ============================================================================
SELECT
	category,
	subcategory,
	product_name, 
	total_revenue,
	revenue_rank
FROM
(
	SELECT
		p.category,
		p.subcategory,
		p.product_name,
		SUM(f.sales_amount) AS total_revenue,
		DENSE_RANK() OVER(PARTITION BY p.category ORDER BY SUM(f.sales_amount) DESC) AS revenue_rank
	FROM gold.fact_sales f
	LEFT JOIN gold.dim_products p
		ON f.product_key = p.product_key
	GROUP BY
		p.category,
		p.subcategory,
		p.product_name
) ranked
WHERE revenue_rank <= 5
ORDER BY 
	category,
	revenue_rank;

-- ============================================================================
-- 6.6 Top 5 Customers Within Each Country
-- ============================================================================
SELECT
	country,
	customer_name, 
	lifetime_revenue,
	country_rank
FROM
(
	SELECT
		c.country,
		CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
		SUM(f.sales_amount) AS lifetime_revenue,
		DENSE_RANK() OVER(PARTITION BY c.country ORDER BY SUM(f.sales_amount) DESC) AS country_rank
	FROM gold.fact_sales f
	LEFT JOIN gold.dim_customers c
		ON f.customer_key = c.customer_key
	GROUP BY	
		c.country,
		c.first_name,
		c.last_name
) ranked
WHERE country_rank <= 5
ORDER BY
	country,
	country_rank;

-- ============================================================================
-- 6.7 Year-over-Year Product Ranking
-- ============================================================================
WITH yearly_sales AS
(
	SELECT
		p.product_name,
		YEAR(f.order_date) AS order_year,
		SUM(f.sales_amount) AS total_revenue,
		DENSE_RANK() OVER(PARTITION BY YEAR(f.order_date) ORDER BY SUM(f.sales_amount) DESC) product_rank
	FROM gold.fact_sales f
	LEFT JOIN gold.dim_products p
		ON f.product_key = p.product_key
	WHERE f.order_date IS NOT NULL
	GROUP BY 
		p.product_name,
		YEAR(f.order_date)
)
SELECT
	curr.product_name,
	curr.order_year,
	curr.total_revenue AS current_revenue,
    prev.total_revenue AS previous_revenue,
	curr.product_rank AS current_rank,
	prev.product_rank AS previous_rank,
	CASE	
		WHEN prev.product_rank IS NULL THEN 'New'
		WHEN curr.product_rank < prev.product_rank THEN 'Improved'
		WHEN curr.product_rank > prev.product_rank THEN 'Declined'
		ELSE 'No Change'
	END AS ranking_status
FROM yearly_sales curr
LEFT JOIN yearly_sales prev
	ON curr.product_name = prev.product_name
	AND curr.order_year = prev.order_year + 1
ORDER BY 
	curr.order_year DESC,
	curr.product_rank;
