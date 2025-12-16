BEGIN;

TRUNCATE TABLE dw.fact_sales;
TRUNCATE TABLE dw.dim_product, dw.dim_store, dw.dim_supplier, dw.dim_seller, dw.dim_customer, dw.dim_pet, dw.dim_pet_category, dw.dim_date RESTART IDENTITY CASCADE;

INSERT INTO dw.dim_date (date_key, date, year, month, day, quarter)
SELECT
  (extract(year from sale_date)::int * 10000)
  + (extract(month from sale_date)::int * 100)
  + extract(day from sale_date)::int AS date_key,
  sale_date::date AS date,
  extract(year from sale_date)::int AS year,
  extract(month from sale_date)::int AS month,
  extract(day from sale_date)::int AS day,
  extract(quarter from sale_date)::int AS quarter
FROM (SELECT DISTINCT sale_date FROM dw.v_mock_data_norm WHERE sale_date IS NOT NULL) d;

INSERT INTO dw.dim_pet_category (name)
SELECT DISTINCT pet_category
FROM dw.v_mock_data_norm
WHERE pet_category IS NOT NULL
ON CONFLICT (name) DO NOTHING;

INSERT INTO dw.dim_supplier (supplier_key, name, contact, email, phone, address, city, country)
SELECT DISTINCT
  md5(
    coalesce(supplier_name, '') || '|' ||
    coalesce(supplier_email, '') || '|' ||
    coalesce(supplier_phone, '') || '|' ||
    coalesce(supplier_address, '') || '|' ||
    coalesce(supplier_city, '') || '|' ||
    coalesce(supplier_country, '')
  ) AS supplier_key,
  supplier_name,
  supplier_contact,
  supplier_email,
  supplier_phone,
  supplier_address,
  supplier_city,
  supplier_country
FROM dw.v_mock_data_norm
WHERE supplier_name IS NOT NULL
ON CONFLICT (supplier_key) DO NOTHING;

INSERT INTO dw.dim_store (store_key, name, location, city, state, country, phone, email)
SELECT DISTINCT
  md5(
    coalesce(store_name, '') || '|' ||
    coalesce(store_location, '') || '|' ||
    coalesce(store_city, '') || '|' ||
    coalesce(store_state, '') || '|' ||
    coalesce(store_country, '')
  ) AS store_key,
  store_name,
  store_location,
  store_city,
  store_state,
  store_country,
  store_phone,
  store_email
FROM dw.v_mock_data_norm
WHERE store_name IS NOT NULL
ON CONFLICT (store_key) DO NOTHING;

INSERT INTO dw.dim_pet (pet_type, pet_name, pet_breed)
SELECT DISTINCT customer_pet_type, customer_pet_name, customer_pet_breed
FROM dw.v_mock_data_norm
WHERE customer_pet_type IS NOT NULL
ON CONFLICT (pet_type, pet_name, pet_breed) DO NOTHING;

INSERT INTO dw.dim_customer (customer_src_id, first_name, last_name, age, email, country, postal_code, pet_id)
SELECT DISTINCT
  sale_customer_id AS customer_src_id,
  customer_first_name,
  customer_last_name,
  customer_age,
  customer_email,
  customer_country,
  customer_postal_code,
  p.pet_id
FROM dw.v_mock_data_norm v
LEFT JOIN dw.dim_pet p
  ON p.pet_type IS NOT DISTINCT FROM v.customer_pet_type
 AND p.pet_name IS NOT DISTINCT FROM v.customer_pet_name
 AND p.pet_breed IS NOT DISTINCT FROM v.customer_pet_breed
WHERE sale_customer_id IS NOT NULL
ON CONFLICT (customer_src_id) DO NOTHING;

INSERT INTO dw.dim_seller (seller_src_id, first_name, last_name, email, country, postal_code)
SELECT DISTINCT
  sale_seller_id AS seller_src_id,
  seller_first_name,
  seller_last_name,
  seller_email,
  seller_country,
  seller_postal_code
FROM dw.v_mock_data_norm
WHERE sale_seller_id IS NOT NULL
ON CONFLICT (seller_src_id) DO NOTHING;

INSERT INTO dw.dim_product (
  product_src_id,
  name,
  category,
  price,
  quantity,
  weight,
  color,
  size,
  brand,
  material,
  description,
  rating,
  reviews,
  release_date,
  expiry_date,
  pet_category_id,
  supplier_id
)
SELECT DISTINCT
  sale_product_id AS product_src_id,
  product_name,
  product_category,
  product_price::numeric(12,2) AS price,
  product_quantity,
  product_weight::numeric(12,3) AS weight,
  product_color,
  product_size,
  product_brand,
  product_material,
  product_description,
  product_rating::numeric(3,1) AS rating,
  product_reviews,
  product_release_date,
  product_expiry_date,
  pc.pet_category_id,
  s.supplier_id
FROM dw.v_mock_data_norm v
LEFT JOIN dw.dim_pet_category pc ON pc.name = v.pet_category
LEFT JOIN dw.dim_supplier s ON s.supplier_key = md5(
  coalesce(v.supplier_name, '') || '|' ||
  coalesce(v.supplier_email, '') || '|' ||
  coalesce(v.supplier_phone, '') || '|' ||
  coalesce(v.supplier_address, '') || '|' ||
  coalesce(v.supplier_city, '') || '|' ||
  coalesce(v.supplier_country, '')
)
WHERE sale_product_id IS NOT NULL
ON CONFLICT (product_src_id) DO NOTHING;

INSERT INTO dw.fact_sales (
  sale_date_key,
  customer_id,
  seller_id,
  product_id,
  store_id,
  quantity,
  unit_price,
  total_price,
  source_row_id
)
SELECT
  d.date_key,
  c.customer_id,
  se.seller_id,
  pr.product_id,
  st.store_id,
  v.sale_quantity,
  v.product_price::numeric(12,2) AS unit_price,
  v.sale_total_price::numeric(12,2) AS total_price,
  v.source_row_id
FROM dw.v_mock_data_norm v
LEFT JOIN dw.dim_date d ON d.date = v.sale_date
LEFT JOIN dw.dim_customer c ON c.customer_src_id = v.sale_customer_id
LEFT JOIN dw.dim_seller se ON se.seller_src_id = v.sale_seller_id
LEFT JOIN dw.dim_product pr ON pr.product_src_id = v.sale_product_id
LEFT JOIN dw.dim_store st ON st.store_key = md5(
  coalesce(v.store_name, '') || '|' ||
  coalesce(v.store_location, '') || '|' ||
  coalesce(v.store_city, '') || '|' ||
  coalesce(v.store_state, '') || '|' ||
  coalesce(v.store_country, '')
);

COMMIT;
