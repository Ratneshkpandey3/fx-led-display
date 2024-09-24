CREATE TABLE IF NOT EXISTS currency_rates (
    event_id BIGINT PRIMARY KEY,
    event_time BIGINT,
    currency_pair VARCHAR(10),
    rate DECIMAL(20,10)
);

LOAD DATA INFILE '/var/lib/mysql-files/rates_sample.csv'
INTO TABLE currency_rates
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(event_id, event_time, currency_pair, rate);
