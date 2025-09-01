include .env

.PHONY: up
up:
	docker compose up --build --force-recreate

.PHONY: start
start:
	docker compose up --build --force-recreate

.PHONY: logs
logs:
	docker compose logs
