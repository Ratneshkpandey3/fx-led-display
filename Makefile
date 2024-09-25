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
show-batch-processing-table-hourly:
	docker exec -it currency_db bash -c "mysql -uuser -puser_password -e 'use currency_db; select * from currency_rate_changes;'"
show-batch-processing-table-minute:
	docker exec -it currency_db bash -c "mysql -uuser -puser_password -e 'use currency_db; select * from currency_rate_changes_opt;'"
show-job-events:
	docker exec -it currency_db bash -c "mysql -uuser -puser_password -e 'SELECT EVENT_NAME, INTERVAL_VALUE, INTERVAL_FIELD, STATUS FROM information_schema.EVENTS WHERE EVENT_SCHEMA = \"currency_db\";'"
