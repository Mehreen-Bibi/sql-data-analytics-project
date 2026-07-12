/*
===============================================================================
SECTION 13: PRODUCT REPORT
===============================================================================

Goal:
    Build a consolidated product analytics view that combines product
    master data and sales performance into a reusable reporting layer
    for dashboards and business intelligence.

Highlights:
    1. Retrieves product master data and transaction details.
    2. Aggregates product-level sales metrics.
    3. Calculates profitability and performance KPIs.
    4. Segments products by revenue and activity.
    5. Produces one row per product.

===============================================================================
*/

IF OBJECT_ID('gold.report_products','V') IS NOT NULL
    DROP VIEW gold.report_products;
GO

CREATE VIEW gold.report_products AS

/*==============================================================================
1) Base Query
==============================================================================*/
WITH product_transactions AS
(
    SELECT
		  f.order_number,
      f.customer_key,
      f.order_date,
      f.quantity,
      f.price,
      f.sales_amount,
      p.product_key,
      p.product_number,
      p.product_name,
      p.category,
      p.subcategory,
      p.product_line,
      p.maintenance,
      p.cost,
      p.start_date
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_products p
        ON p.product_key = f.product_key
),

/*==============================================================================
2) Product Aggregation
==============================================================================*/
product_summary AS
(
  SELECT
		product_key,
    product_number,
    product_name,
    category,
    subcategory,
    product_line,
    maintenance,
    cost,
    start_date,
		COUNT(DISTINCT order_number) AS total_orders,
		COUNT(DISTINCT customer_key) AS total_customers,
		SUM(quantity) AS total_quantity,
		AVG(price) AS average_selling_price,
		SUM(sales_amount) AS total_revenue,
		SUM(cost * quantity) AS total_cost,
		SUM(sales_amount) - SUM(cost * quantity) AS total_profit,
		MIN(order_date) AS first_sale_date,
		MAX(order_date) AS last_sale_date,
	  DATEDIFF(MONTH, MIN(order_date), MAX(order_date)) AS product_lifespan_months
	FROM product_transactions
	GROUP BY
		product_key,
    product_number,
    product_name,
    category,
    subcategory,
    product_line,
    maintenance,
    cost,
    start_date
)

/*==============================================================================
Final Product Report
==============================================================================*/

SELECT
	product_key,
  product_number,
  product_name,
  category,
  subcategory,
  product_line,
  maintenance,
  cost,
  start_date,
  total_orders,
  total_customers,
	total_quantity,
	total_revenue,
	total_cost,
  total_profit,
  average_selling_price,
  first_sale_date,
  last_sale_date,
  product_lifespan_months,
	ROUND(total_quantity / NULLIF(total_orders,0), 2) AS average_units_per_order,
  CASE
		WHEN last_sale_date IS NULL THEN NULL
        ELSE DATEDIFF(DAY,last_sale_date,GETDATE())
  END AS days_since_last_sale,
	-- Compute Average Order Revenue (AOR)
	ROUND(total_revenue * 1.0 / NULLIF(total_orders,0), 2) AS average_order_revenue,
	-- Compute Monthly Revenue
	CASE
		WHEN product_lifespan_months = 0 THEN total_revenue
		ELSE ROUND(total_revenue * 1.0 / product_lifespan_months, 2)
	END AS average_monthly_revenue,
  ROUND(CAST(total_profit AS FLOAT) * 100 / NULLIF(total_revenue,0),2) AS profit_margin_pct,
	ROUND(total_customers * 100.0/ (SELECT COUNT(*) FROM gold.dim_customers), 2) AS customer_reach_pct,
  CASE
		WHEN NTILE(3) OVER(ORDER BY total_revenue DESC) = 1 THEN 'High Revenue'
		WHEN NTILE(3) OVER(ORDER BY total_revenue DESC) = 2 THEN 'Medium Revenue'
	ELSE 'Low Revenue'
	END AS product_segment,
  CASE
      WHEN NTILE(3) OVER(ORDER BY total_profit DESC) = 1 THEN 'High Profit'
      WHEN NTILE(3) OVER(ORDER BY total_profit DESC) = 2 THEN 'Medium Profit'
      ELSE 'Low Profit'
  END AS profit_segment
FROM product_summary;
GO
