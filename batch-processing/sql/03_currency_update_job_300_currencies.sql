CREATE INDEX idx_event_time_minute ON currency_rates(event_time);
DELIMITER //

CREATE EVENT update_currency_rates_per_minute
ON SCHEDULE EVERY 1 MINUTE
STARTS CURRENT_TIMESTAMP
DO
BEGIN
    DECLARE active_time_limit INT DEFAULT 30000;
    DECLARE yesterday_start_time DATETIME;
    DECLARE yesterday_end_time DATETIME;
    DECLARE today_max_time BIGINT;
    DECLARE output_file VARCHAR(255);

    SET yesterday_start_time =  '2024-02-20 16:59:30';
    SET yesterday_end_time = '2024-02-20 17:00:00';

    SELECT MAX(event_time) INTO today_max_time FROM currency_rates;

    DROP TEMPORARY TABLE IF EXISTS recent_rates;
    DROP TEMPORARY TABLE IF EXISTS yesterday_rates;

    CREATE TEMPORARY TABLE recent_rates AS
    SELECT
        currency_pair,
        rate AS current_rate,
        event_time,
        ROW_NUMBER() OVER (PARTITION BY currency_pair ORDER BY event_time DESC) AS rn
    FROM currency_rates
    WHERE rate <> 0
    AND event_time >= today_max_time - active_time_limit;

    CREATE TEMPORARY TABLE yesterday_rates AS
    SELECT
        currency_pair,
        rate AS yesterday_rate,
        event_time,
        ROW_NUMBER() OVER (PARTITION BY currency_pair ORDER BY event_time DESC) AS rn
    FROM currency_rates
    WHERE rate <> 0
    AND CONVERT_TZ(FROM_UNIXTIME(event_time / 1000), '+00:00', 'America/New_York')
        BETWEEN yesterday_start_time AND yesterday_end_time;


    SELECT
        'currency_pair' AS currency_pair,
        'rate' AS rate,
        'change' AS `change`
    UNION ALL
    SELECT
        r.currency_pair,
        ROUND(r.current_rate, 5) AS rate,
        COALESCE(
            CONCAT(
                ROUND(100 * (r.current_rate - y.yesterday_rate) / y.yesterday_rate, 3), '%'
            ),
            'N/A'
        ) AS `change`
    FROM recent_rates r
    JOIN yesterday_rates y ON r.currency_pair = y.currency_pair
    WHERE r.rn = 1 AND y.rn = 1
    INTO OUTFILE "/var/lib/mysql-files/output/300_currency_couples.csv"
    FIELDS TERMINATED BY ','
    LINES TERMINATED BY '\n';

    DROP TEMPORARY TABLE recent_rates;
    DROP TEMPORARY TABLE yesterday_rates;
END //
DELIMITER ;
