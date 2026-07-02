/*
============================================================================
SECTION 7: CHANGE OVER TIME ANALYSIS
============================================================================
Goal:
    Analyze business performance across time to identify long-term growth,
    short-term changes, customer acquisition trends, and seasonality.

Business Questions:
    • Is revenue increasing over time?
    • How does monthly revenue compare to the previous month?
    • How much does revenue grow each year?
    • How many new customers are acquired over time?
    • Which months consistently perform better?
    • What is the underlying trend after smoothing fluctuations?

SQL Concepts:
    • DATETRUNC()
    • YEAR(), MONTH(), DATENAME()
    • LAG()
    • AVG() OVER()
    • Common Table Expressions (CTEs)
============================================================================
*/

-- ============================================================================
-- 7.1 Monthly Business Performance Trend
-- ============================================================================
SELECT
	DATETRUNC(MONTH, order_date) AS order_month,
	COUNT(DISTINCT order_number) AS total_orders,
	COUNT(DISTINCT customer_key) AS unique_customers,
	SUM(quantity) AS total_units_sold,
	SUM(sales_amount) AS total_revenue,
	ROUND(AVG(price), 2) AS avg_unit_price
FROM gold.fact_sales 
WHERE order_date IS NOT NULL
GROUP BY DATETRUNC(MONTH, order_date)
ORDER BY order_month;

-- ============================================================================
-- 7.2 Year-over-Year Revenue Growth
-- ============================================================================
WITH yearly_sales AS
(
	SELECT
		YEAR(order_date) AS order_year,
		COUNT(DISTINCT order_number) AS total_orders,
		COUNT(DISTINCT customer_key) AS unique_customers,
		SUM(sales_amount) AS total_revenue,
		LAG(SUM(sales_amount)) OVER(ORDER BY YEAR(order_date)) AS previous_revenue
	FROM gold.fact_sales 
	WHERE order_date IS NOT NULL
	GROUP BY YEAR(order_date)
)
SELECT
	order_year,
	total_orders,
	unique_customers,
	total_revenue,
	previous_revenue,
	total_revenue - previous_revenue AS revenue_change,
	ROUND((total_revenue - previous_revenue)*100.0 / NULLIF(previous_revenue, 0), 2) AS revenue_growth_pct
FROM yearly_sales
ORDER BY order_year;
	
-- ============================================================================
-- 7.3 Month-over-Month Revenue Growth
-- ============================================================================
WITH monthly_sales AS
(
	SELECT
		DATETRUNC(MONTH, order_date) AS order_month,
		SUM(sales_amount) AS total_revenue,
		LAG(SUM(sales_amount)) OVER(ORDER BY DATETRUNC(MONTH, order_date)) AS previous_month_revenue
	FROM gold.fact_sales
	WHERE order_date IS NOT NULL
	GROUP BY DATETRUNC(MONTH, order_date)
)
SELECT 
	order_month,
	total_revenue,
	previous_month_revenue,
	total_revenue - previous_month_revenue AS revenue_change,
	ROUND((total_revenue - previous_month_revenue) * 100.0 / NULLIF(previous_month_revenue, 0), 2) AS revenue_growth_pct
FROM monthly_sales
ORDER BY order_month;

-- ============================================================================
-- 7.4 Monthly Customer Acquisition Trend
-- ============================================================================
SELECT
	DATETRUNC(MONTH, create_date) AS customer_month,
	COUNT(*) AS new_customer
FROM gold.dim_customers
WHERE create_date IS NOT NULL
GROUP BY DATETRUNC(MONTH, create_date)
ORDER BY customer_month;

-- ============================================================================
-- 7.5 Seasonal Revenue Analysis
-- Average Monthly Revenue Across All Years
-- ============================================================================
WITH monthly_revenue AS
(
	SELECT
		YEAR(order_date) AS order_year,
		MONTH(order_date) AS month_number,
		DATENAME(MONTH, order_date) AS month_name,
		SUM(sales_amount) AS monthly_revenue
	FROM gold.fact_sales
	WHERE order_date IS NOT NULL
	GROUP BY
		YEAR(order_date),
		MONTH(order_date),
		DATENAME(MONTH, order_date)
)
SELECT
	month_number,
	month_name,
	AVG(monthly_revenue) AS avg_monthly_revenue
FROM monthly_revenue
GROUP BY
	month_number,
	month_name
ORDER BY month_number;

-- ============================================================================
-- 7.6 Three-Month Moving Average Revenue
-- Smooths short-term fluctuations to reveal long-term trends
-- ============================================================================
SELECT
	DATETRUNC(MONTH, order_date) AS order_month,
	SUM(sales_amount) AS total_revenue,
	ROUND(AVG(SUM(sales_amount)) OVER(ORDER BY DATETRUNC(MONTH, order_date) ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2) AS moving_avg_3_month
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY DATETRUNC(MONTH, order_date)
ORDER BY order_month;
