/*
===============================================================================
SECTION 8: CUMULATIVE ANALYSIS
===============================================================================
Goal:
    Analyze business growth using cumulative (running) metrics.
    Running totals reveal how business performance accumulates over time,
    making it easier to evaluate long-term progress.

Business Questions:
    • How much revenue has accumulated over time?
    • How many orders have been processed so far?
    • How many units have been sold cumulatively?
    • How has the customer base grown?
    • How does the average order value evolve over time?

SQL Concepts:
    • SUM() OVER()
    • AVG() OVER()
    • Window Frames
    • Common Table Expressions (CTEs)
===============================================================================
*/

-- ============================================================================
-- 8.1 Cumulative Revenue and Orders
-- Running totals by month
-- ============================================================================
WITH monthly_sales AS
(
	SELECT
		DATETRUNC(MONTH, order_date) AS order_month,
		SUM(sales_amount) AS monthly_revenue,
		COUNT(DISTINCT order_number) AS monthly_orders
	FROM gold.fact_sales
	WHERE order_date IS NOT NULL
	GROUP BY DATETRUNC(MONTH, order_date)
)
SELECT
	order_month,
	monthly_revenue,
	SUM(monthly_revenue) OVER(ORDER BY order_month ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_revenue,
	monthly_orders,
	SUM(monthly_orders) OVER(ORDER BY order_month ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_orders
FROM monthly_sales
ORDER BY order_month;
	

-- ============================================================================
-- 8.2 Cumulative Units Sold
-- -- Running total of units sold by month
-- ============================================================================
WITH monthly_units AS
(
	SELECT
		DATETRUNC(MONTH, order_date) AS order_month,
		SUM(quantity) AS monthly_units_sold
	FROM gold.fact_sales
	WHERE order_date IS NOT NULL
	GROUP BY DATETRUNC(MONTH, order_date)
)
SELECT
	order_month,
	monthly_units_sold,
	SUM(monthly_units_sold) OVER(ORDER BY order_month ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_units_sold
FROM monthly_units
ORDER BY order_month;

-- ============================================================================
-- 8.3 Customer Growth
-- Running total of customers acquired
-- ============================================================================

WITH monthly_customers AS
(
	SELECT
		DATETRUNC(MONTH, create_date) AS customer_month,
		COUNT(*) AS new_customers
	FROM gold.dim_customers
	WHERE create_date IS NOT NULL
	GROUP BY DATETRUNC(MONTH, create_date)
)
SELECT
	customer_month,
	new_customers,
	SUM(new_customers) OVER(ORDER BY customer_month ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_customers
FROM monthly_customers
ORDER BY customer_month;

-- ============================================================================
-- 8.4 Cumulative Revenue by Product Category
-- -- Running revenue for each product category over time
-- ============================================================================
WITH category_monthly_sales AS
(
SELECT
	DATETRUNC(MONTH, f.order_date) AS order_month,
	p.category,
	SUM(f.sales_amount) AS monthly_revenue
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
	ON f.product_key = p.product_key
WHERE f.order_date IS NOT NULL
GROUP BY 
	DATETRUNC(MONTH, f.order_date),
	p.category
)
SELECT
	order_month,
	category,
	monthly_revenue,
	SUM(monthly_revenue) OVER(PARTITION BY category ORDER BY order_month ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_category_revenue
FROM category_monthly_sales
ORDER BY 
	category,
	order_month;

-- ============================================================================
-- 8.5 Running Average Order Value
-- Shows how average order value evolves over time
-- ============================================================================
WITH monthly_order_values AS
(
SELECT
	DATETRUNC(MONTH, order_date) AS order_month,
	order_number,
	SUM(sales_amount) AS order_value
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY 
	DATETRUNC(MONTH, order_date),
	order_number
),
monthly_aov AS 
(
SELECT
     order_month,
     AVG(order_value) AS average_order_value
FROM monthly_order_values
GROUP BY order_month
)

SELECT
    order_month,
    ROUND(average_order_value,2) AS average_order_value,
	ROUND(AVG(average_order_value) OVER(ORDER BY order_month ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) ,2) AS running_average_order_value
FROM monthly_aov
ORDER BY order_month;
