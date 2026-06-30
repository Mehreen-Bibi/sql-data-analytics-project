/* 
============================================================================
SECTION 3: DATE EXPLORATION
============================================================================
Goal: Explore the temporal characteristics of the sales, customer, and
      product data. Analyze date ranges, business trends, customer
      acquisition, and operational timelines to assess data completeness
      and prepare for time-series analytics.
============================================================================
*/

-- ----------------------------------------------------------------------------
-- 3.1  fact_sales – Overall date range
-- ----------------------------------------------------------------------------
SELECT 
	MIN(order_date) AS earliest_order,
	MAX(order_date) AS latest_order,
	DATEDIFF(year, MIN(order_date), MAX(order_date)) AS order_range_years,
	DATEDIFF(month, MIN(order_date), MAX(order_date)) AS order_range_months
FROM gold.fact_sales;

-- ----------------------------------------------------------------------------
-- 3.2  Annual order volume and revenue trend
--      Identifies yearly business growth and customer activity.
-- ----------------------------------------------------------------------------
SELECT 
	YEAR(order_date) AS order_year,
	COUNT(DISTINCT order_number) AS total_orders,
	SUM(sales_amount) AS total_revenue,
	SUM(quantity) AS total_units_sold,
	COUNT(DISTINCT customer_key) AS unique_customers
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY YEAR(order_date)
ORDER BY order_year;

-- ----------------------------------------------------------------------------
-- 3.3  Monthly order volume and revenue trend
--      Reveals monthly sales patterns and seasonality.
-- ----------------------------------------------------------------------------
SELECT 
	YEAR(order_date) AS order_year,
	MONTH(order_date) AS order_month,
	DATENAME(MONTH, order_date) AS month_name,
	COUNT(DISTINCT order_number) AS total_orders,
	SUM(sales_amount) AS total_revenue	
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY 
	YEAR(order_date),
	MONTH(order_date),
	DATENAME(MONTH, order_date)
ORDER BY 
	order_year,
	order_month;

-- ----------------------------------------------------------------------------
-- 3.4  Shipping performance
--      Measures the number of days between order placement and shipment.
-- ----------------------------------------------------------------------------
SELECT
	COUNT(*) AS shipped_orders,
	AVG(DATEDIFF(DAY, order_date, shipping_date)) AS avg_ship_days,
	MIN(DATEDIFF(DAY, order_date, shipping_date)) AS min_ship_days,
	MAX(DATEDIFF(DAY, order_date, shipping_date)) AS max_ship_days
FROM gold.fact_sales
WHERE order_date IS NOT NULL 
	AND shipping_date IS NOT NULL;

-- ----------------------------------------------------------------------------
-- 3.5  Customer lifecycle overview
-- ----------------------------------------------------------------------------
SELECT
	MIN(create_date) AS earliest_customer,
	MAX(create_date) AS latest_customer,
	DATEDIFF(YEAR, MIN(create_date), MAX(create_date)) AS years_of_customer_history
FROM gold.dim_customers;

-- New customers acquired per year
SELECT
	YEAR(create_date) AS cohort_year,
	COUNT(*) AS new_customers
FROM gold.dim_customers
GROUP BY YEAR(create_date)
ORDER BY cohort_year;

-- ----------------------------------------------------------------------------
-- 3.6  Products introduced each year
--      Shows how the product catalogue has grown over time.
-- ----------------------------------------------------------------------------
SELECT
	YEAR(start_date) AS introduction_year,
	COUNT(*) AS new_products
FROM gold.dim_products
GROUP BY YEAR(start_date)
ORDER BY introduction_year;

-- ----------------------------------------------------------------------------
-- 3.7  dim_products – Product catalogue start date range
-- ----------------------------------------------------------------------------

SELECT
	MIN(start_date) AS earliest_product,
	MAX(start_date) AS latest_product,
	DATEDIFF(YEAR, MIN(start_date), MAX(start_date)) AS years_of_catalogue_history
FROM gold.dim_products;
