.PHONY: help env up down nuke ps logs smoke trino-cli

help:
	@echo "make up        start the stack (SeaweedFS S3, Postgres, Trino, Prefect) and wait until healthy"
	@echo "make smoke     end-to-end check: create an Iceberg table via Trino, write, read, drop"
	@echo "make trino-cli interactive Trino shell"
	@echo "make ps|logs   status / follow logs"
	@echo "make down      stop the stack (keeps data)"
	@echo "make nuke      stop the stack and DELETE all volumes"

env:
	@test -f .env || (cp .env.example .env && echo "created .env from .env.example")

up: env
	docker compose up -d --wait

down:
	docker compose down

nuke:
	docker compose down -v

ps:
	docker compose ps

logs:
	docker compose logs -f --tail=100

smoke:
	./scripts/smoke.sh

trino-cli:
	docker compose exec trino trino --catalog iceberg
