-- Примеры запросов для анализа исходной таблицы public.mock_data

-- 1) Общее количество строк
SELECT count(*) AS mock_data_rows FROM public.mock_data;

-- 2) Кардинальности потенциальных измерений (источниковые идентификаторы)
SELECT
  count(DISTINCT sale_customer_id) AS customers,
  count(DISTINCT sale_seller_id) AS sellers,
  count(DISTINCT sale_product_id) AS products,
  count(DISTINCT store_name) AS stores
FROM public.mock_data;

-- 3) Проверка распределения по датам продаж
SELECT sale_date, count(*) AS sales_cnt
FROM public.mock_data
GROUP BY sale_date
ORDER BY sales_cnt DESC
LIMIT 20;

-- 4) Топ категорий товаров по сумме продаж
SELECT product_category, sum(NULLIF(sale_total_price, '')::numeric) AS revenue
FROM public.mock_data
GROUP BY product_category
ORDER BY revenue DESC NULLS LAST
LIMIT 10;
