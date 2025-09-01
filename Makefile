include .env

.PHONY: up
up:
	docker compose up --build --force-recreate

.PHONY: start
start:
	docker compose up --build --force-recreate -d

.PHONY: exec
exec:
	docker compose exec app sh

.PHONY: logs
logs:
	docker compose logs
