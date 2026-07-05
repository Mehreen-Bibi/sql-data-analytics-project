/*
===============================================================================
SECTION 9: PERFORMANCE BENCHMARK ANALYSIS
===============================================================================
Goal:
    Evaluate business performance by comparing products, customers, and
    monthly sales against historical averages and previous periods.

Business Questions:
    • Which products outperform their category average?
    • Which products are growing or declining year over year?
    • Which months perform above their long-term trend?
    • Which customers outperform the average customer?
    • Which products generate the highest profit margins?

SQL Concepts:
    • Window Functions (LAG, AVG OVER)
    • PARTITION BY
    • CASE Expressions
    • Common Table Expressions (CTEs)
===============================================================================
*/


-- ============================================================================
-- 9.1 Product Performance vs Category Average
-- Compare each product with the average revenue of its category
-- ============================================================================
WITH product_sales AS
(
	SELECT 
		p.product_name,
		p.category,
		p.subcategory,
		SUM(f.sales_amount) AS total_revenue,
		SUM(f.quantity) AS total_units_sold
	FROM gold.fact_sales f
	LEFT JOIN gold.dim_products p
		ON f.product_key = p.product_key
	GROUP BY
		p.product_name,
		p.category,
		p.subcategory
),
benchmark AS
(
SELECT
*,
AVG(CAST(total_revenue AS FLOAT)) OVER(PARTITION BY category) AS category_average_revenue
FROM product_sales
)

SELECT
	product_name,
	category,
	subcategory,
	total_units_sold,
	total_revenue,
	ROUND((total_revenue - category_average_revenue), 2) AS revenue_difference,
	ROUND(((total_revenue - category_average_revenue) * 100.0) 
	/ NULLIF(category_average_revenue, 0), 2) AS performance_pct,
	CASE	
		WHEN total_revenue > category_average_revenue THEN 'High Performer'
		WHEN total_revenue < category_average_revenue THEN 'Low Performer'
		ELSE 'Average Performer'
	END AS performance_status
FROM benchmark
ORDER BY
	category,
	total_revenue DESC;

-- ============================================================================
-- 9.2 Product Year-over-Year Performance
-- Compare annual product revenue with the previous year
-- ============================================================================
WITH yearly_sales AS
(
	SELECT
		p.product_name,
		p.category,
		YEAR(f.order_date) AS order_year,
		SUM(f.sales_amount) AS annual_revenue
	FROM gold.fact_sales f
	INNER JOIN gold.dim_products p
		ON f.product_key = p.product_key
	WHERE f.order_date IS NOT NULL
	GROUP BY
		p.product_name,
		p.category,
		YEAR(f.order_date)
),
performance AS
(
	SELECT
		*,
		LAG(annual_revenue) OVER(PARTITION BY product_name ORDER BY order_year) AS previous_year_revenue
	FROM yearly_sales
)
SELECT
    product_name,
    category,
    order_year,
    annual_revenue,
    previous_year_revenue,
	annual_revenue - previous_year_revenue AS revenue_change,
	ROUND((annual_revenue - previous_year_revenue) * 100.0/ NULLIF(previous_year_revenue, 0), 2) AS revenue_growth_pct,
	CASE
		WHEN previous_year_revenue IS NULL THEN 'New Product'
		WHEN annual_revenue > previous_year_revenue THEN 'Growth'
		WHEN annual_revenue < previous_year_revenue THEN 'Decline'
		ELSE 'Stable'
	END AS performance_trend
FROM performance
ORDER BY 
	product_name,
	order_year;

-- ============================================================================
-- 9.3 Monthly Revenue vs Rolling 12-Month Average
-- Benchmark monthly sales against the long-term trend
-- ============================================================================
WITH monthly_sales AS
(
	SELECT
		DATETRUNC(MONTH, order_date) AS order_month,
		SUM(sales_amount) AS monthly_revenue
	FROM gold.fact_sales
	WHERE order_date IS NOT NULL
	GROUP BY DATETRUNC(MONTH, order_date)
),
trend AS
(
	SELECT
		*,
		AVG(CAST(monthly_revenue AS FLOAT)) OVER(ORDER BY order_month ROWS BETWEEN 11 PRECEDING AND CURRENT ROW) AS rolling_12m_average
	FROM monthly_sales
)

SELECT
	order_month,
	monthly_revenue,
	ROUND(rolling_12m_average, 2) AS rolling_12m_average,
	ROUND((monthly_revenue - rolling_12m_average), 2) AS revenue_difference,
	CASE
        WHEN monthly_revenue >= rolling_12m_average THEN 'Above Trend'
        ELSE 'Below Trend'
    END AS trend_status
FROM trend
ORDER BY order_month;

-- ============================================================================
-- 9.4 Customer Performance vs Average Customer Value
-- Compare each customer's lifetime revenue with the average customer
-- ============================================================================
WITH customer_sales AS
(
SELECT
	c.customer_number,
	CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
	c.country,
	COUNT(DISTINCT f.order_number) AS total_orders,
	SUM(sales_amount) AS lifetime_revenue
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
	ON f.customer_key = c.customer_key
GROUP BY
	c.customer_number,
	c.first_name,
	c.last_name,
	c.country
)

SELECT
	customer_number,
	customer_name,
	country,
	total_orders,
	lifetime_revenue,
	ROUND(AVG(CAST(lifetime_revenue AS FLOAT)) OVER(), 2) AS average_customer_revenue,
	ROUND(lifetime_revenue - AVG(CAST(lifetime_revenue AS FLOAT)) OVER(), 2) AS revenue_difference,
	CASE	
		WHEN (lifetime_revenue >= (AVG(CAST(lifetime_revenue AS FLOAT)) OVER() * 2)) THEN 'VIP'
		WHEN (lifetime_revenue >= AVG(CAST(lifetime_revenue AS FLOAT)) OVER()) THEN 'High Value'
		WHEN (lifetime_revenue >= (AVG(CAST(lifetime_revenue AS FLOAT)) OVER() * 0.5)) THEN 'Average Value'
		ELSE 'Low Value'
	END AS customer_segment
FROM customer_sales
ORDER BY lifetime_revenue DESC;

-- ============================================================================
-- 9.5 Product Profit & Margin Performance
-- Evaluate profitability using product cost
-- ============================================================================
SELECT
	p.product_name,
	p.category,
	SUM(f.quantity) AS total_units_sold,
	SUM(f.sales_amount) AS total_revenue,
	SUM(p.cost * f.quantity) AS total_cost,
	SUM(f.sales_amount) - SUM(p.cost * f.quantity) AS total_profit,
	ROUND(((SUM(f.sales_amount) - SUM(p.cost * f.quantity)) * 100.0) / NULLIF(SUM(f.sales_amount), 0), 2) AS profit_margin_pct
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
	ON f.product_key = p.product_key
GROUP BY
	p.product_name,
	p.category
ORDER BY
    total_profit DESC;
