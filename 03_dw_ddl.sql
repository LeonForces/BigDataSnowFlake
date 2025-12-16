CREATE SCHEMA IF NOT EXISTS dw;

CREATE TABLE IF NOT EXISTS dw.dim_date (
  date_key integer PRIMARY KEY,
  date date NOT NULL UNIQUE,
  year smallint NOT NULL,
  month smallint NOT NULL,
  day smallint NOT NULL,
  quarter smallint NOT NULL
);

CREATE TABLE IF NOT EXISTS dw.dim_pet (
  pet_id bigserial PRIMARY KEY,
  pet_type text,
  pet_name text,
  pet_breed text,
  CONSTRAINT dim_pet_unique UNIQUE (pet_type, pet_name, pet_breed)
);

CREATE TABLE IF NOT EXISTS dw.dim_customer (
  customer_id bigserial PRIMARY KEY,
  customer_src_id integer NOT NULL UNIQUE,
  first_name text,
  last_name text,
  age integer,
  email text,
  country text,
  postal_code text,
  pet_id bigint REFERENCES dw.dim_pet(pet_id)
);

CREATE TABLE IF NOT EXISTS dw.dim_seller (
  seller_id bigserial PRIMARY KEY,
  seller_src_id integer NOT NULL UNIQUE,
  first_name text,
  last_name text,
  email text,
  country text,
  postal_code text
);

CREATE TABLE IF NOT EXISTS dw.dim_pet_category (
  pet_category_id bigserial PRIMARY KEY,
  name text NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS dw.dim_supplier (
  supplier_id bigserial PRIMARY KEY,
  supplier_key text NOT NULL UNIQUE,
  name text,
  contact text,
  email text,
  phone text,
  address text,
  city text,
  country text
);

CREATE TABLE IF NOT EXISTS dw.dim_store (
  store_id bigserial PRIMARY KEY,
  store_key text NOT NULL UNIQUE,
  name text,
  location text,
  city text,
  state text,
  country text,
  phone text,
  email text
);

CREATE TABLE IF NOT EXISTS dw.dim_product (
  product_id bigserial PRIMARY KEY,
  product_src_id integer NOT NULL UNIQUE,
  name text,
  category text,
  price numeric(12,2),
  quantity integer,
  weight numeric(12,3),
  color text,
  size text,
  brand text,
  material text,
  description text,
  rating numeric(3,1),
  reviews integer,
  release_date date,
  expiry_date date,
  pet_category_id bigint REFERENCES dw.dim_pet_category(pet_category_id),
  supplier_id bigint REFERENCES dw.dim_supplier(supplier_id)
);

CREATE TABLE IF NOT EXISTS dw.fact_sales (
  sale_id bigserial PRIMARY KEY,
  sale_date_key integer REFERENCES dw.dim_date(date_key),
  customer_id bigint REFERENCES dw.dim_customer(customer_id),
  seller_id bigint REFERENCES dw.dim_seller(seller_id),
  product_id bigint REFERENCES dw.dim_product(product_id),
  store_id bigint REFERENCES dw.dim_store(store_id),
  quantity integer,
  unit_price numeric(12,2),
  total_price numeric(12,2),
  source_row_id integer,
  loaded_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS fact_sales_sale_date_key_idx ON dw.fact_sales(sale_date_key);
CREATE INDEX IF NOT EXISTS fact_sales_customer_id_idx ON dw.fact_sales(customer_id);
CREATE INDEX IF NOT EXISTS fact_sales_seller_id_idx ON dw.fact_sales(seller_id);
CREATE INDEX IF NOT EXISTS fact_sales_product_id_idx ON dw.fact_sales(product_id);
CREATE INDEX IF NOT EXISTS fact_sales_store_id_idx ON dw.fact_sales(store_id);

CREATE OR REPLACE VIEW dw.v_mock_data_norm AS
SELECT
  NULLIF(id, '')::integer AS source_row_id,
  NULLIF(customer_first_name, '') AS customer_first_name,
  NULLIF(customer_last_name, '') AS customer_last_name,
  NULLIF(customer_age, '')::integer AS customer_age,
  NULLIF(customer_email, '') AS customer_email,
  NULLIF(customer_country, '') AS customer_country,
  NULLIF(customer_postal_code, '') AS customer_postal_code,
  NULLIF(customer_pet_type, '') AS customer_pet_type,
  NULLIF(customer_pet_name, '') AS customer_pet_name,
  NULLIF(customer_pet_breed, '') AS customer_pet_breed,

  NULLIF(seller_first_name, '') AS seller_first_name,
  NULLIF(seller_last_name, '') AS seller_last_name,
  NULLIF(seller_email, '') AS seller_email,
  NULLIF(seller_country, '') AS seller_country,
  NULLIF(seller_postal_code, '') AS seller_postal_code,

  NULLIF(product_name, '') AS product_name,
  NULLIF(product_category, '') AS product_category,
  NULLIF(product_price, '')::numeric AS product_price,
  NULLIF(product_quantity, '')::integer AS product_quantity,
  to_date(NULLIF(product_release_date, ''), 'MM/DD/YYYY') AS product_release_date,
  to_date(NULLIF(product_expiry_date, ''), 'MM/DD/YYYY') AS product_expiry_date,
  NULLIF(pet_category, '') AS pet_category,
  NULLIF(product_weight, '')::numeric AS product_weight,
  NULLIF(product_color, '') AS product_color,
  NULLIF(product_size, '') AS product_size,
  NULLIF(product_brand, '') AS product_brand,
  NULLIF(product_material, '') AS product_material,
  NULLIF(product_description, '') AS product_description,
  NULLIF(product_rating, '')::numeric AS product_rating,
  NULLIF(product_reviews, '')::integer AS product_reviews,

  to_date(NULLIF(sale_date, ''), 'MM/DD/YYYY') AS sale_date,
  NULLIF(sale_customer_id, '')::integer AS sale_customer_id,
  NULLIF(sale_seller_id, '')::integer AS sale_seller_id,
  NULLIF(sale_product_id, '')::integer AS sale_product_id,
  NULLIF(sale_quantity, '')::integer AS sale_quantity,
  NULLIF(sale_total_price, '')::numeric AS sale_total_price,

  NULLIF(store_name, '') AS store_name,
  NULLIF(store_location, '') AS store_location,
  NULLIF(store_city, '') AS store_city,
  NULLIF(store_state, '') AS store_state,
  NULLIF(store_country, '') AS store_country,
  NULLIF(store_phone, '') AS store_phone,
  NULLIF(store_email, '') AS store_email,

  NULLIF(supplier_name, '') AS supplier_name,
  NULLIF(supplier_contact, '') AS supplier_contact,
  NULLIF(supplier_email, '') AS supplier_email,
  NULLIF(supplier_phone, '') AS supplier_phone,
  NULLIF(supplier_address, '') AS supplier_address,
  NULLIF(supplier_city, '') AS supplier_city,
  NULLIF(supplier_country, '') AS supplier_country
FROM public.mock_data;
