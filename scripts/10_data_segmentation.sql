/*
===============================================================================
SECTION 10: DATA SEGMENTATION
===============================================================================
Goal:
    Segment customers and products into meaningful business groups to better
    understand purchasing behavior, product positioning, and customer value.

Business Questions:
    • How are products distributed across different cost ranges?
    • Which customer segment generates the highest revenue?
    • Which products belong to high, medium, and low revenue tiers?
    • How frequently do customers purchase?

SQL Concepts:
    • CASE Expressions
    • Common Table Expressions (CTEs)
    • GROUP BY
    • Aggregate Functions
===============================================================================
*/

-- ============================================================================
-- 10.1 Product Segmentation by Cost Range
-- Classify products based on manufacturing cost
-- ============================================================================
WITH product_segments AS
(
  SELECT
  	product_key,
  	product_name,
  	category,
  	cost,
  	CASE
  		WHEN cost < 100 THEN 'Below $100'
          WHEN cost BETWEEN 100 AND 500 THEN '$100 - $500'
          WHEN cost BETWEEN 501 AND 1000 THEN '$501 - $1,000'
          ELSE 'Above $1,000'
      END AS cost_segment
  FROM gold.dim_products
)

SELECT
	cost_segment,
	COUNT(product_key) AS total_products
FROM product_segments
GROUP BY cost_segment
ORDER BY total_products DESC;

-- ============================================================================
-- 10.2 Customer Segmentation by Spending
-- Segment customers based on lifetime spending and customer lifespan
-- ============================================================================
WITH customer_summary AS
(
  SELECT 
  	  c.customer_key,
      CONCAT(c.first_name,' ',c.last_name) AS customer_name,
      SUM(f.sales_amount) AS total_spending,
      MIN(f.order_date) AS first_order,
      MAX(f.order_date) AS last_order,
  	DATEDIFF(MONTH, MIN(f.order_date), MAX(f.order_date)) AS customer_lifespan 
  FROM gold.fact_sales f
  LEFT JOIN gold.dim_customers c
  	ON f.customer_key = c.customer_key
  GROUP BY 
  	c.customer_key,
  	c.first_name,
  	c.last_name
)
SELECT
	customer_segment,
	COUNT(*) AS total_customers,
	SUM(total_spending) AS segment_revenue
FROM
(
  SELECT
  *,
  CASE
  	WHEN customer_lifespan >= 12 AND total_spending > 5000 THEN 'VIP'
  	WHEN customer_lifespan >= 12 AND total_spending <= 5000 THEN 'Regular'
  	ELSE 'New'
  END AS customer_segment
  FROM customer_summary
) segmented
GROUP BY customer_segment
ORDER BY segment_revenue DESC;

-- ============================================================================
-- 10.3 Product Revenue Segmentation
-- Classify products into revenue tiers based on lifetime sales
-- ============================================================================
WITH product_revenue AS
(
    SELECT
        p.product_name,
        p.category,
        SUM(f.sales_amount) AS total_revenue
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_products p
        ON f.product_key = p.product_key
    GROUP BY
        p.product_name,
        p.category
)
SELECT
	revenue_segment,
	COUNT(*) AS total_products,
	SUM(total_revenue) AS segment_revenue,
    AVG(total_revenue) AS avg_product_revenue
FROM
(
	SELECT
		*,
		CASE
			WHEN total_revenue >= 50000 THEN 'High Revenue'
			WHEN total_revenue >= 10000 THEN 'Medium Revenue'
			ELSE 'Low Revenue'
		END AS revenue_segment
	FROM product_revenue
) segment
GROUP BY revenue_segment
ORDER BY segment_revenue DESC;

-- ============================================================================
-- 10.4 Customer Purchase Frequency Segmentation
-- Segment customers based on purchase frequency
-- ============================================================================

WITH customer_orders AS
(
    SELECT
        c.customer_key,
        CONCAT(c.first_name,' ',c.last_name) AS customer_name,
        COUNT(DISTINCT f.order_number) AS total_orders,
        SUM(f.sales_amount) AS total_revenue
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_customers c
        ON f.customer_key = c.customer_key
    GROUP BY
        c.customer_key,
        c.first_name,
        c.last_name
)
SELECT
    purchase_segment,
    COUNT(*) AS total_customers,
    ROUND(AVG(CAST(total_revenue AS FLOAT)),2) AS avg_customer_revenue
FROM
(
    SELECT
        *,
        CASE
            WHEN total_orders >= 20 THEN 'Frequent Buyers'
            WHEN total_orders >= 10 THEN 'Occasional Buyers'
            ELSE 'One-Time / Low Activity'
        END AS purchase_segment
    FROM customer_orders
) segmented
GROUP BY purchase_segment
ORDER BY avg_customer_revenue DESC;
