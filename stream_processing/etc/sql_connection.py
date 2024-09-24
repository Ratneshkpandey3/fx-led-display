import time
import mysql.connector
import logging
from mysql.connector import Error
from dotenv import load_dotenv
import os

load_dotenv()

logging.basicConfig(level=logging.INFO)


class DatabaseConnection:
    def __init__(self):
        self.host = os.getenv("DB_HOST")
        self.user = os.getenv("DB_USER")
        self.password = os.getenv("DB_PASSWORD")
        self.database = os.getenv("DB_DATABASE")
        self.max_retries = 10
        self.connection = None

    def create_connection(self):
        retry_count = 0

        while retry_count < self.max_retries:
            try:
                if self.connection is None:
                    self.connection = mysql.connector.connect(
                        host=self.host,
                        user=self.user,
                        password=self.password,
                        database=self.database,
                    )
                    print("Connection to MySQL DB successful")
                    return self.connection

            except Error as e:
                print(f"Failed to create a database connection: '{e}'")

            retry_count += 1
            print(f"Retrying in 5 seconds... ({retry_count}/{self.max_retries})")
            time.sleep(5)

        print("Max retries reached. Failed to connect to the database.")
        return None
