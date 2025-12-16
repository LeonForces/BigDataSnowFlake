.PHONY: up down reset ps logs wait psql count dwinit dwcount check

DC ?= docker compose
SERVICE ?= postgres
DB_NAME ?= bigdata
DB_USER ?= bigdata

up:
	$(DC) up -d

down:
	$(DC) down

reset:
	$(DC) down -v
	$(DC) up -d

ps:
	$(DC) ps

logs:
	$(DC) logs -f --tail=200 $(SERVICE)

wait:
	$(DC) exec -T $(SERVICE) sh -c 'until pg_isready -U "$(DB_USER)" -d "$(DB_NAME)" >/dev/null 2>&1; do sleep 1; done'

psql:
	$(DC) exec $(SERVICE) psql -U $(DB_USER) -d $(DB_NAME)

count:
	$(DC) exec -T $(SERVICE) psql -U $(DB_USER) -d $(DB_NAME) -c 'SELECT count(*) FROM public.mock_data;'

dwcount:
	$(DC) exec -T $(SERVICE) psql -U $(DB_USER) -d $(DB_NAME) -c 'SELECT count(*) AS fact_sales_rows FROM dw.fact_sales;'

dwinit: wait
	$(DC) exec -T $(SERVICE) psql -U $(DB_USER) -d $(DB_NAME) < 03_dw_ddl.sql
	$(DC) exec -T $(SERVICE) psql -U $(DB_USER) -d $(DB_NAME) < 04_dw_dml.sql

check:
	$(DC) exec -T $(SERVICE) psql -U $(DB_USER) -d $(DB_NAME) < 05_dw_checks.sql
