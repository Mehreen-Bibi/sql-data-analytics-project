/* 
============================================================================
SECTION 2: DIMENSION EXPLORATION
============================================================================
Goal: Explore customer and product dimensions to understand data distribution,
      attribute coverage, and key categorical segments before performing
      advanced business analytics.
============================================================================ 
*/

-- ----------------------------------------------------------------------------
-- 2.1  dim_customers – Distinct values for every categorical attribute
-- ----------------------------------------------------------------------------

-- How many unique customers exist?
SELECT
	COUNT(DISTINCT customer_id) AS total_customers
FROM gold.dim_customers;

-- Country distribution — shows geographic spread of the customer base
SELECT
	country,
	COUNT(*) AS customer_count
FROM gold.dim_customers
GROUP BY country
ORDER BY customer_count DESC;

-- Gender distribution
SELECT
	gender,
	COUNT(*) AS customer_count
FROM gold.dim_customers
GROUP BY gender
ORDER BY customer_count DESC;

-- Marital status distribution
SELECT
	marital_status,
	COUNT(*) AS customer_count
FROM gold.dim_customers
GROUP BY marital_status
ORDER BY customer_count DESC;

-- Cross-tab: Gender × Marital Status
-- Reveals whether gender/marital combinations are evenly represented
SELECT
	gender,
	marital_status,
	COUNT(*) AS customer_count
FROM gold.dim_customers
GROUP BY 
	gender,
	marital_status
ORDER BY customer_count DESC;

-- ----------------------------------------------------------------------------
-- 2.2  dim_products – Distinct values for every categorical attribute
-- ----------------------------------------------------------------------------

-- How many unique products (current records only)
SELECT
	COUNT(DISTINCT product_id) AS total_products
FROM gold.dim_products;

-- Category distribution
SELECT
	category,
	COUNT(*) AS product_count
FROM gold.dim_products
GROUP BY category
ORDER BY product_count DESC;

-- Subcategory distribution — drills one level below category
SELECT
	category,
	subcategory,
	COUNT(*) AS product_count
FROM gold.dim_products
GROUP BY 
	category,
	subcategory
ORDER BY product_count DESC;

-- Product line distribution
SELECT
	product_line,
	COUNT(*) AS product_count
FROM gold.dim_products
GROUP BY product_line
ORDER BY product_count DESC;

-- Maintenance flag distribution
SELECT 
	maintenance,
	COUNT(*) AS product_count
FROM gold.dim_products
GROUP BY maintenance
ORDER BY product_count DESC;

-- Cost range buckets — understand the cost tier spread of the catalogue
WITH product_cost AS 
(
SELECT
	CASE
		WHEN cost = 0 THEN 'No Cost'
		WHEN cost BETWEEN 1 AND 100 THEN '1-Low (1$-100$)'
		WHEN cost BETWEEN 101 AND 500 THEN '2-Medium (101$-500$)'
		WHEN cost BETWEEN 501 AND 1500 THEN '3-High (501$-1500$)'
		ELSE '4-Premium (>1500$)'
	END AS cost_tier
FROM gold.dim_products
)
SELECT
	cost_tier,
	COUNT(*) AS product_count
FROM product_cost
GROUP BY cost_tier
ORDER BY product_count DESC;
