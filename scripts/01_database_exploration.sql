/* 
============================================================================
SECTION 1: DATABASE EXPLORATION
============================================================================
Goal: Understand the structure of the Gold layer — what objects exist,
      what columns they contain, and what data types are in use.
============================================================================ 
*/

-- ----------------------------------------------------------------------------
-- 1.1  Lists all business-ready tables and views available in the Gold layer.
-- ----------------------------------------------------------------------------
SELECT
    TABLE_SCHEMA AS schema_name,
    TABLE_NAME   AS table_name,
    TABLE_TYPE   AS object_type   -- 'BASE TABLE' or 'VIEW'
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'gold'
ORDER BY TABLE_TYPE, TABLE_NAME;

-- ----------------------------------------------------------------------------
-- 1.2  Column inventory for all Gold objects
--      Useful for understanding field names, data types, and nullability
--      before writing any aggregation queries
-- ----------------------------------------------------------------------------
SELECT
    TABLE_NAME                            AS table_name,
    COLUMN_NAME                           AS column_name,
    ORDINAL_POSITION                      AS col_position,
    DATA_TYPE                             AS data_type,
    CHARACTER_MAXIMUM_LENGTH              AS max_length,
    IS_NULLABLE                           AS is_nullable
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'gold'
ORDER BY TABLE_NAME, ORDINAL_POSITION;

-- ----------------------------------------------------------------------------
-- 1.3  Row counts for every Gold object
--      Quick sanity check to confirm data was loaded and views resolve correctly
-- ----------------------------------------------------------------------------
SELECT 
	'gold.dim_customers' AS table_name, 
	COUNT(*) AS row_count 
FROM gold.dim_customers

UNION ALL

SELECT 
	'gold.dim_products', 
	COUNT(*) 
FROM gold.dim_products

UNION ALL

SELECT 
	'gold.fact_sales', 
	COUNT(*) 
FROM gold.fact_sales;
