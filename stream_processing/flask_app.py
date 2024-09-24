import logging
import threading
from flask import Flask, jsonify
from etc.kafka_consumer import KafkaConsumerManager
from etc.kafka_producer import KafkaProducerManager


class DataProcessor:
    def __init__(self):
        self.processed_data = []

    def pre_process_kafka_data(self):
        self.processed_data.clear()
        kafka_consumer = KafkaConsumerManager()
        kafka_consumer.create_kafka_consumer()
        for data in kafka_consumer.consume_data():
            existing_entry = next(
                (
                    entry
                    for entry in self.processed_data
                    if entry["ccy_couple"] == data["ccy_couple"]
                ),
                None,
            )

            if existing_entry:
                if existing_entry["change"] != data["change"]:
                    self.processed_data.remove(existing_entry)
                    self.processed_data.append(data)
            else:
                self.processed_data.append(data)


class FlaskApp:
    def __init__(self, data_processor):
        self.app = Flask(__name__)
        self.data_processor = data_processor

        @self.app.route("/", methods=["GET"])
        def get_data():
            return jsonify(self.data_processor.processed_data)

    def run(self, host="0.0.0.0", port=5001):
        logging.info("Starting the Flask app now...")
        self.app.run(host=host, port=port)


if __name__ == "__main__":
    data_processor = DataProcessor()
    kafka_producer = KafkaProducerManager()
    kafka_producer.create_kafka_producer()
    produce_thread = threading.Thread(target=kafka_producer.produce_data)
    produce_thread.start()

    consume_thread = threading.Thread(target=data_processor.pre_process_kafka_data)
    consume_thread.start()

    flask_app = FlaskApp(data_processor)
    flask_app.run()
