import mysql.connector
from mysql.connector import Error
import time


def create_connection(max_retries=10):
    connection = None
    retry_count = 0

    while retry_count < max_retries:
        try:
            if connection is None:
                connection = mysql.connector.connect(
                    host="db",
                    user="user",
                    password="user_password",
                    database="currency_db",
                )
                print("Connection to MySQL DB successful")
                return connection

        except Error as e:
            print(f"Failed to create a database connection: '{e}'")

        retry_count += 1
        print(f"Retrying in 5 seconds... ({retry_count}/{max_retries})")
        time.sleep(5)

    print("Max retries reached. Failed to connect to the database.")
    return None
