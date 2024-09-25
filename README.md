## Assignment Project: Batch and Stream Processing with Docker
### Overview
This project is designed to run both batch processing and stream processing using Docker containers. The containers handle SQL jobs for currency rate updates and stream processing via Kafka.

### Requirements
- Make sure you have installed `Docker` and `Docker Compose`
- Make sure you have `pyenv` installed:

### Setup
```bash
pyenv install 3.9.13
```
- Create and activate the new virtual environment using pyenv:

```bash
pyenv virtualenv 3.9.13 fx_task
pyenv activate fx_task
```
```bash
make setup-dev
```

## Batch Processing
The batch-processing container handles the execution of SQL files for various tasks. Here is a breakdown of each SQL file:

### SQL Files
- 01_init.sql:
    - Creates a table to store data from rates_sample.csv.
    - Loads the sample data into the table.

- 02_currency_rate_update_hourly.sql:

    - Sets up a job that runs hourly to update currency rates.
    - Saves the result as a CSV file in batch-processing/output/currency_rates.csv.

- 03_currency_update_job_300_currencies.sql:

  - Sets up a job that runs every minute to update 300 currency pairs.
  - Saves the data to batch-processing/output/300_currency_couples.csv.

- 04_currency_rate_update_hourly_to_table.sql:

    - Creates a job that updates currency rates hourly and stores them in the currency_rate_changes table as per the `requirement 1`.
    - If a currency pair already exists, the value is updated.

- 05_currency_rate_optimised.sql:
    - Runs a job every minute to update currency rates and store them in the currency_rate_changes_opt table as per the `requirement 2`.
    - This table is later used by the Kafka producer for streaming.

### Notes for Batch Processing:
  - Data will not be visible until the container is up and running.
  - You can check the status of the running containers with `docker ps`. If currency_db is running, the database setup is complete.

### Run Batch Processing

- To run the batch processing
```bash
make run-batch-process
```
- To stop batch processing
```bash
make batch-shutdown
```
### Note: This must be run on another terminal because on first terminal the batch processing is running continuously
- To view requirement `result 1`
```bash
make show-batch-processing-table-hourly
```
- To view requirement `result 2`
```bash
make show-batch-processing-table-minute
```
- To show job events
```bash
make show-job-events
```

## Stream Processing
#### The stream-processing container runs a Kafka Producer and Consumer:

`Kafka Producer`: Pulls data from the MySQL database using mysql.connector and pushes it to Kafka on the current_rates topic.
`Kafka Consumer`: Listens to the current_rates topic and processes the data.

`Output` : Once both the producer and consumer are working, you can view the consumer's output at http://localhost:5001.

### Note: I used port 5001 because port 5000 was already in use by Docker Desktop.

### Additional Notes for Stream Processing:
Even after the container is created, it may take 1-3 minutes for the Kafka consumer to start, due to connection setup between MySQL and Kafka brokers.

### Run Stream Processing

- To run the stream processing
```bash
make run-stream
```
- To stop the stream processing
```bash
make stream-shutdown
```
- To view the flask logs
```bash
make flask-logs
```
