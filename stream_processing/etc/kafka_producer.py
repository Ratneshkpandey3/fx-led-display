import json
import time
from decimal import Decimal
from kafka import KafkaProducer
from kafka.errors import NoBrokersAvailable
from .sql_connection import DatabaseConnection


class KafkaProducerManager:
    def __init__(self, kafka_broker, topic, max_retries=10):
        self.kafka_broker = kafka_broker
        self.topic = topic
        self.max_retries = max_retries
        self.producer = None

    def create_kafka_producer(self):
        retry_delay = 2
        retries = 0

        while retries < self.max_retries:
            try:
                self.producer = KafkaProducer(
                    bootstrap_servers=[self.kafka_broker],
                    value_serializer=lambda x: json.dumps(x).encode("utf-8"),
                )
                print("Kafka producer created successfully.")
                return self.producer
            except NoBrokersAvailable:
                retries += 1
                print(
                    f"Broker unavailable. Retry {retries}/{self.max_retries} "
                    f"after {retry_delay} seconds..."
                )
                time.sleep(retry_delay)
                retry_delay *= 2

        raise Exception(
            f"Failed to connect to Kafka broker after {self.max_retries} retries."
        )

    def produce_data(self):
        while True:
            connection = None
            cursor = None
            try:
                connection = DatabaseConnection.create_connection()
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
                    self.producer.send(self.topic, serialized_row)

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
