/* 
============================================================================
SECTION 4: MEASURES EXPLORATION
============================================================================
Goal: Explore the numerical measures in the Sales fact table by computing
      summary statistics, distribution metrics, and data quality indicators.
      This analysis provides a high-level understanding of business KPIs
      before performing advanced analytical reporting.
============================================================================
*/

-- ----------------------------------------------------------------------------
-- 4.1 Overall Measure Statistics
--      Summary statistics for the core business measures.
-- ----------------------------------------------------------------------------
SELECT
	COUNT(*)            AS total_order_line,
	-- Sales Amount
	SUM(sales_amount)   AS total_revenue,
	AVG(sales_amount)   AS avg_sales_amount,
	MIN(sales_amount)   AS min_sales_amount,
	MAX(sales_amount)   AS max_sales_amount,
	STDEV(sales_amount) AS sales_std_dev,
	-- Quantity
	SUM(quantity)       AS total_units_sold,
	AVG(quantity)       AS avg_quantity,
	MIN(quantity)       AS min_quantity,
	MAX(quantity)       AS max_quantity,
	STDEV(quantity)     AS quantity_std_dev,
	-- Price
	AVG(price)          AS avg_unit_price,
	MIN(price)          AS min_unit_price,
	MAX(price)          AS max_unit_price,
	STDEV(price)        AS price_std_dev
FROM gold.fact_sales;

-- ----------------------------------------------------------------------------
-- 4.2 Missing Value Assessment
--      Check for NULL values in important numerical measures.
-- ----------------------------------------------------------------------------
SELECT 
	SUM(CASE WHEN sales_amount IS NULL THEN 1 ELSE 0 END) AS null_sales_amount,
	SUM(CASE WHEN quantity IS NULL THEN 1 ELSE 0 END)     AS null_quantity,
	SUM(CASE WHEN price IS NULL THEN 1 ELSE 0 END)        AS null_price
FROM gold.fact_sales;

-- ----------------------------------------------------------------------------
-- 4.3 Business Volume Overview
--      High-level business metrics.
-- ----------------------------------------------------------------------------
SELECT
	COUNT(DISTINCT order_number) AS total_orders,
	COUNT(DISTINCT customer_key) AS customers_with_orders,
	COUNT(DISTINCT product_key) AS products_sold
FROM gold.fact_sales;

-- ----------------------------------------------------------------------------
-- 4.4 Order-Level Statistics
--      Analyze customer purchasing behavior at the order level.
-- ----------------------------------------------------------------------------
With order_summary AS 
(
	SELECT
	order_number,
	SUM(sales_amount) AS order_value,
	COUNT(*) AS order_lines
	FROM gold.fact_sales
	GROUP BY order_number
)
SELECT
	AVG(order_value) AS avg_order_value,
	MIN(order_value) AS min_order_value,
	MAX(order_value) AS max_order_value,
	AVG(order_lines) AS avg_lines_per_order,
	MIN(order_lines) AS min_lines_per_order,
	MAX(order_lines) AS max_lines_per_order
FROM order_summary;

-- ----------------------------------------------------------------------------
-- 4.5 Median Sales Amount
--      Median is less sensitive to extreme values than the average.
-- ----------------------------------------------------------------------------
SELECT DISTINCT
	PERCENTILE_CONT(0.5) 
	WITHIN GROUP (ORDER BY sales_amount)
	OVER() AS median_sales_amount
FROM gold.fact_sales;
