import json
import time

from kafka import KafkaConsumer
from kafka.errors import NoBrokersAvailable

KAFKA_TOPIC = "currency_rates"


def create_kafka_consumer():
    max_retries = 10
    retry_delay = 2
    retries = 0

    while retries < max_retries:
        try:
            consumer = KafkaConsumer(
                KAFKA_TOPIC,
                bootstrap_servers="kafka:9093",
                value_deserializer=lambda x: json.loads(x.decode("utf-8")),
                auto_offset_reset="latest",
                enable_auto_commit=True,
            )
            print("Kafka consumer created successfully.")
            return consumer
        except NoBrokersAvailable:
            retries += 1
            print(
                f"Broker unavailable. Retry {retries}/{max_retries} "
                f"after {retry_delay} seconds..."
            )
            time.sleep(retry_delay)
            retry_delay *= 2
        except Exception as e:
            print(f"Error creating Kafka consumer: {e}")
            time.sleep(retry_delay)
            retries += 1
            retry_delay *= 2

    raise Exception(f"Failed to connect to Kafka broker after {max_retries} retries.")


consumer = create_kafka_consumer()


def consume_data():
    for message in consumer:
        yield message.value
