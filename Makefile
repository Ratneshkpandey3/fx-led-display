.PHONY: setup-dev format lint

LINT_DIRS = .

setup-dev:
	pip install poetry
	poetry install
	pre-commit install
format:
	poetry run isort $(LINT_DIRS)
	poetry run black $(LINT_DIRS)
lint:
	poetry run isort -c $(LINT_DIRS)
	poetry run flake8 $(LINT_DIRS)
run-stream:
	docker-compose -f batch-processing/docker-compose.yml -f stream-processing/docker-compose.yml up --build -d
stream-shutdown:
	docker-compose -f batch-processing/docker-compose.yml -f stream-processing/docker-compose.yml down
batch-shutdown:
	docker compose -f batch-processing/docker-compose.yml down
run-batch-process:
	docker compose -f batch-processing/docker-compose.yml up --build
flask-logs:
	docker logs currency_flask_app
