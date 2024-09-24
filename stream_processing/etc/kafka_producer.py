import json
import time
from decimal import Decimal

from kafka import KafkaProducer
from kafka.errors import NoBrokersAvailable

from .get_current_sql_data import create_connection

kafka_broker = "kafka:9093"


def create_kafka_producer():
    max_retries = 10
    retry_delay = 2
    retries = 0

    while retries < max_retries:
        try:
            producer = KafkaProducer(
                bootstrap_servers=[kafka_broker],
                value_serializer=lambda x: json.dumps(x).encode("utf-8"),
            )
            print("Kafka producer created successfully.")
            return producer
        except NoBrokersAvailable:
            retries += 1
            print(
                f"Broker unavailable. Retry {retries}/{max_retries} "
                f"after {retry_delay} seconds..."
            )
            time.sleep(retry_delay)
            retry_delay *= 2

    raise Exception(f"Failed to connect to Kafka broker after {max_retries} retries.")


KAFKA_TOPIC = "currency_rates"
producer = create_kafka_producer()


def produce_data():
    while True:
        connection = None
        cursor = None
        try:
            connection = create_connection()
            if connection is None:
                raise Exception("Failed to connect to the database after retries.")

            cursor = connection.cursor()

            cursor.execute("SELECT * FROM currency_rate_changes_opt;")
            rows = cursor.fetchall()

            for row in rows:
                serialized_row = {
                    key: (float(value) if isinstance(value, Decimal) else value)
                    for key, value in zip(cursor.column_names, row)
                }
                producer.send(KAFKA_TOPIC, serialized_row)

            print("Data produced to Kafka.")
            time.sleep(5)

        except Exception as e:
            print(f"Error during data production: {e}")
            time.sleep(10)

        finally:
            if cursor is not None:
                cursor.close()
            if connection is not None:
                connection.close()
            print("Connection closed. Attempting to reconnect...")
