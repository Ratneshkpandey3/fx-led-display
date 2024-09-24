import threading

from etc.kafka_consumer import consume_data
from etc.kafka_producer import produce_data
from flask import Flask, jsonify

app = Flask(__name__)
processed_data = []


def pre_process_kafka_data():
    processed_data.clear()
    for data in consume_data():
        existing_entry = next(
            (
                entry
                for entry in processed_data
                if entry["ccy_couple"] == data["ccy_couple"]
            ),
            None,
        )

        if existing_entry:
            if existing_entry["change"] != data["change"]:
                processed_data.remove(existing_entry)
                processed_data.append(data)
        else:
            processed_data.append(data)


@app.route("/", methods=["GET"])
def get_data():
    return jsonify(processed_data)


if __name__ == "__main__":
    print("Starting the flask-app now...")

    produce_thread = threading.Thread(target=produce_data)
    produce_thread.start()

    consume_thread = threading.Thread(target=pre_process_kafka_data)
    consume_thread.start()
    app.run(host="0.0.0.0", port=5001)
