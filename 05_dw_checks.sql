\echo '--- Source row count (public.mock_data) ---'
SELECT count(*) AS mock_data_rows FROM public.mock_data;

\echo '--- Dimension counts (dw.*) ---'
SELECT 'dim_date' AS table_name, count(*) AS rows FROM dw.dim_date
UNION ALL SELECT 'dim_customer', count(*) FROM dw.dim_customer
UNION ALL SELECT 'dim_seller', count(*) FROM dw.dim_seller
UNION ALL SELECT 'dim_pet', count(*) FROM dw.dim_pet
UNION ALL SELECT 'dim_pet_category', count(*) FROM dw.dim_pet_category
UNION ALL SELECT 'dim_supplier', count(*) FROM dw.dim_supplier
UNION ALL SELECT 'dim_store', count(*) FROM dw.dim_store
UNION ALL SELECT 'dim_product', count(*) FROM dw.dim_product
UNION ALL SELECT 'fact_sales', count(*) FROM dw.fact_sales
ORDER BY table_name;

\echo '--- Basic quality checks ---'
SELECT
  sum(CASE WHEN sale_date_key IS NULL THEN 1 ELSE 0 END) AS missing_sale_date,
  sum(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS missing_customer,
  sum(CASE WHEN seller_id IS NULL THEN 1 ELSE 0 END) AS missing_seller,
  sum(CASE WHEN product_id IS NULL THEN 1 ELSE 0 END) AS missing_product,
  sum(CASE WHEN store_id IS NULL THEN 1 ELSE 0 END) AS missing_store
FROM dw.fact_sales;

\echo '--- Top 10 product categories by revenue ---'
SELECT
  p.category,
  sum(f.total_price) AS revenue
FROM dw.fact_sales f
JOIN dw.dim_product p ON p.product_id = f.product_id
GROUP BY p.category
ORDER BY revenue DESC NULLS LAST
LIMIT 10;
