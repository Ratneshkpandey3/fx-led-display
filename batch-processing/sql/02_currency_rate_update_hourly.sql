CREATE INDEX idx_event_time ON currency_rates(event_time);
DELIMITER //
CREATE EVENT update_currency_rates_hourly
ON SCHEDULE EVERY 1 HOUR
STARTS CURRENT_TIMESTAMP
DO
BEGIN
    DECLARE active_time_limit INT DEFAULT 30000;
    DECLARE yesterday_start_time DATETIME;
    DECLARE yesterday_end_time DATETIME;
    DECLARE today_max_time BIGINT;


    -- Uncomment only when testing with realtime data
    -- SET yesterday_start_time = DATE_SUB(CONVERT_TZ(NOW(), 'UTC', 'America/New_York'), INTERVAL 1 DAY) + INTERVAL '16:59:30' HOUR_SECOND;
    -- SET yesterday_end_time = yesterday_start_time + INTERVAL 30 SECOND;

    -- because given sample csv file is from 20.02.2024 and I'm testing both recent rates and newyork time rates with the same file. If you want to run with real data comment below two lines and uncomment above two lines.
    SET yesterday_start_time =  '2024-02-20 16:59:30';
    SET yesterday_end_time = '2024-02-20 17:00:00';
    -- Get the maximum event_time in milliseconds
    SELECT MAX(event_time) INTO today_max_time FROM currency_rates;

    WITH recent_rates AS (
        SELECT
            currency_pair,
            rate AS current_rate,
            event_time,
            ROW_NUMBER() OVER (PARTITION BY currency_pair ORDER BY event_time DESC) AS rn
        FROM currency_rates
        WHERE rate <> 0
        AND event_time >= today_max_time - active_time_limit
        -- uncomment below line if you're running on real time data
        -- AND event_time >= (UNIX_TIMESTAMP() * 1000) - 30000
    ),
    yesterday_rates AS (
        SELECT
            currency_pair,
            rate AS yesterday_rate,
            event_time,
            ROW_NUMBER() OVER (PARTITION BY currency_pair ORDER BY event_time DESC) AS rn
        FROM currency_rates
        WHERE rate <> 0
        AND CONVERT_TZ(FROM_UNIXTIME(event_time / 1000), '+00:00', 'America/New_York')
            BETWEEN yesterday_start_time AND yesterday_end_time
    )
    SELECT
        'ccy_couple' AS ccy_couple,
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
    INTO OUTFILE '/var/lib/mysql-files/output/currency_rates.csv'
    FIELDS TERMINATED BY ','
    LINES TERMINATED BY '\n';
END //
DELIMITER ;
