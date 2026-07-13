# SQL Server Data Analytics Project

## Overview

This project demonstrates how SQL Server can be used to analyze business data and generate meaningful insights for decision-making.

Using the **Gold Layer** from my **SQL Server Data Warehouse Project**, I performed customer, product, sales, and time-based analysis with T-SQL. I also created reusable reporting views that can be connected directly to Power BI for interactive dashboards.

---

## Project Objectives

The project focuses on answering common business questions such as:

- Which products generate the highest revenue?
- Who are the most valuable customers?
- How is revenue changing over time?
- Which product categories contribute the most sales?
- How do customers and products perform compared to historical averages?

---

## Skills Demonstrated

- SQL Server
- T-SQL
- Common Table Expressions (CTEs)
- Window Functions
- Aggregate Functions
- Ranking Functions
- Views
- Business Performance Analysis
- Customer & Product Analytics

---

## Project Structure

```text
scripts/
│── 01_database_exploration.sql
│── 02_measures.sql
│── 03_dimensions.sql
│── 04_magnitude_analysis.sql
│── 05_ranking_analysis.sql
│── 06_change_over_time.sql
│── 07_cumulative_analysis.sql
│── 08_performance_benchmark.sql
│── 09_data_segmentation.sql
│── 10_part_to_whole_analysis.sql
│── 11_customer_report.sql
│── 12_product_report.sql

powerbi/
screenshots/
README.md
```

---

## Data Source

This project uses the **Gold Layer** created in my **SQL Server Data Warehouse Project**.

### Required Tables

- `gold.fact_sales`
- `gold.dim_customers`
- `gold.dim_products`

---

## Reports

### Customer Report

A customer-level reporting view that includes:

- Customer demographics
- Lifetime revenue
- Total orders
- Average order value
- Monthly spending
- Customer lifespan
- Recency
- Customer segmentation

### Product Report

A product-level reporting view that includes:

- Revenue
- Profit
- Profit Margin
- Average Selling Price
- Average Order Revenue
- Monthly Revenue
- Product Lifespan
- Revenue & Profit Segments

---

## Next Step

The next phase of this project is to build an interactive **Power BI dashboard** using the reporting views created in SQL Server.


