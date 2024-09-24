import json
import time
import logging
from kafka import KafkaConsumer
from kafka.errors import NoBrokersAvailable
from dotenv import load_dotenv
import os

load_dotenv()

KAFKA_TOPIC = "currency_rates"


class KafkaConsumerManager:
    def __init__(self):
        self.topic = os.getenv("KAFKA_TOPIC")
        self.bootstrap_servers = os.getenv("KAFKA_BROKER")
        self.max_retries = 10
        self.consumer = None

    def create_kafka_consumer(self):
        retry_delay = 2
        retries = 0

        while retries < self.max_retries:
            try:
                self.consumer = KafkaConsumer(
                    self.topic,
                    bootstrap_servers=self.bootstrap_servers,
                    value_deserializer=lambda x: json.loads(x.decode("utf-8")),
                    auto_offset_reset="latest",
                    enable_auto_commit=True,
                )
                logging.info("Kafka consumer created successfully.")
                return self.consumer
            except NoBrokersAvailable:
                retries += 1
                logging.info(
                    f"Broker unavailable. Retry {retries}/{self.max_retries} "
                    f"after {retry_delay} seconds..."
                )
                time.sleep(retry_delay)
                retry_delay *= 2
            except Exception as e:
                logging.info(f"Error creating Kafka consumer: {e}")
                time.sleep(retry_delay)
                retries += 1
                retry_delay *= 2

        raise Exception(
            f"Failed to connect to Kafka broker after {self.max_retries} retries."
        )

    def consume_data(self):
        if self.consumer is None:
            raise Exception(
                "Consumer is not initialized. Call create_kafka_consumer() first."
            )

        for message in self.consumer:
            yield message.value
