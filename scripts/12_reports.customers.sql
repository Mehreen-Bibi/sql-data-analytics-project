/*
===============================================================================
SECTION 12: CUSTOMER REPORT
===============================================================================
Goal:
    Build a consolidated customer analytics view that combines customer
    demographics, purchasing behavior, and key business KPIs into a single
    reusable report for business intelligence and dashboard reporting.

Business Questions:
    • Who are our customers?
    • How valuable is each customer?
    • How recently has each customer purchased?
    • How long has each customer been active?
    • What is the average order value?
    • What is the average monthly spending?
    • Which customers belong to VIP, Standard, and New segments?

SQL Concepts:
    • Common Table Expressions (CTEs)
    • Aggregate Functions
    • CASE Expressions
    • DATEDIFF()
    • NULLIF()
    • CREATE VIEW
===============================================================================
*/

-- ============================================================================
-- Create Customer Report View
-- One row represents one customer
-- ============================================================================
IF OBJECT_ID('gold.report_customers', 'V') IS NOT NULL
	DROP VIEW gold.report_customers;
GO

CREATE VIEW gold.report_customers AS

-- ============================================================================
-- Step 1: Retrieve customer transaction details
-- ============================================================================
WITH customer_transactions AS
(
  SELECT
  	f.order_number,
  	f.order_date,
  	f.product_key,
  	f.sales_amount,
  	f.quantity,
  	c.customer_key,
  	c.customer_number,
  	CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
  	c.country,
  	c.marital_status,
  	c.gender,
  	c.birthdate,
  	c.create_date
  FROM gold.fact_sales f
  LEFT JOIN gold.dim_customers c
  	ON f.customer_key = c.customer_key
  WHERE f.order_date iS NOT NULL
),


-- ============================================================================
-- Step 2: Aggregate customer metrics
-- ============================================================================
customer_summary AS
(
  SELECT
  	customer_key,
  	customer_number,
  	customer_name,
  	country,
  	marital_status,
  	gender,
  	birthdate,
  	create_date,
  	-- Accurate customer age
  	DATEDIFF(YEAR, birthdate, GETDATE()) -
  	CASE
  		WHEN DATEADD(YEAR, DATEDIFF(YEAR, birthdate, GETDATE()), birthdate) > GETDATE() THEN 1 
  		ELSE 0
  	END AS age,
  	COUNT(DISTINCT order_number) AS total_orders,
  	COUNT(DISTINCT product_key) AS total_products,
  	SUM(quantity) AS total_quantity,
  	SUM(sales_amount) AS lifetime_revenue,
  	MIN(order_date) AS first_order_date,
  	MAX(order_date) AS last_order_date,
  	DATEDIFF(MONTH, MIN(order_date), MAX(order_date)) AS customer_lifespan_months
  FROM customer_transactions
  GROUP BY
  	customer_key,
  	customer_number,
  	customer_name,
  	country,
  	marital_status,
  	gender,
  	birthdate,
  	create_date
)
-- ============================================================================
-- Final Customer Report
-- ============================================================================
SELECT
	customer_key,
	customer_number,
	customer_name,
	gender,
	marital_status,
	country,
	birthdate,
	age,
	CASE
		WHEN age IS NULL THEN 'n/a'
		WHEN age < 50 THEN 'Under 50'
		WHEN age BETWEEN 50 AND 59 THEN '50-59'
		WHEN age BETWEEN 60 AND 69 THEN '60-69'
		WHEN age BETWEEN 70 AND 79 THEN '70-79'
		WHEN age BETWEEN 80 AND 89 THEN '80-89'
		ELSE '90+'
	END AS age_group,
	create_date AS customer_since,
	first_order_date,
	last_order_date,
	DATEDIFF(MONTH, last_order_date, GETDATE()) AS recency_months,
	customer_lifespan_months,
	total_orders,
	total_products,
	total_quantity,
	lifetime_revenue,
	-- Compute average order value (AVO)
	CASE
		WHEN total_orders = 0 THEN 0
		ELSE lifetime_revenue / total_orders
	END AS avg_order_value,
	-- Compute average monthly spendg
	CASE	
		WHEN customer_lifespan_months = 0 THEN lifetime_revenue
		ELSE ROUND(lifetime_revenue / customer_lifespan_months, 2) 
	END AS average_monthly_spend,
	CASE	
		WHEN customer_lifespan_months >= 12 AND lifetime_revenue > 5000 THEN 'VIP'
		WHEN customer_lifespan_months >= 12 AND lifetime_revenue <= 5000 THEN 'Regular'
		ELSE 'New'
	END AS customer_segment
FROM customer_summary;
