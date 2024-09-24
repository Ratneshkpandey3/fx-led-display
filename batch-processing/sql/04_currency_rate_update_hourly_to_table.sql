CREATE INDEX idx_event_time_table ON currency_rates(currency_pair, event_time);

CREATE TABLE currency_rate_changes (
    ccy_couple VARCHAR(10) NOT NULL PRIMARY KEY,
    rate DECIMAL(10, 5) NOT NULL,
    `change` VARCHAR(10) NOT NULL,
    UNIQUE (ccy_couple)
);

DELIMITER //
CREATE EVENT update_currency_rates_hourly_table
ON SCHEDULE EVERY 1 HOUR
STARTS CURRENT_TIMESTAMP
DO
BEGIN
    DECLARE active_time_limit INT DEFAULT 30000;
    DECLARE yesterday_start_time DATETIME;
    DECLARE yesterday_end_time DATETIME;
    DECLARE today_max_time BIGINT;

    SET yesterday_start_time = '2024-02-20 16:59:30';
    SET yesterday_end_time = '2024-02-20 17:00:00';

    SELECT MAX(event_time) INTO today_max_time FROM currency_rates;

    INSERT INTO currency_rate_changes (ccy_couple, rate, `change`)
    SELECT
        r.currency_pair,
        ROUND(r.current_rate, 5) AS rate,
        COALESCE(
            CONCAT(
                ROUND(100 * (r.current_rate - y.yesterday_rate) / y.yesterday_rate, 3), '%'
            ),
            'N/A'
        ) AS `change`
    FROM (
        SELECT
            currency_pair,
            rate AS current_rate,
            ROW_NUMBER() OVER (PARTITION BY currency_pair ORDER BY event_time DESC) AS rn
        FROM currency_rates
        WHERE rate <> 0
        AND event_time >= today_max_time - active_time_limit
    ) r
    JOIN (
        SELECT
            currency_pair,
            rate AS yesterday_rate,
            ROW_NUMBER() OVER (PARTITION BY currency_pair ORDER BY event_time DESC) AS rn
        FROM currency_rates
        WHERE rate <> 0
        AND CONVERT_TZ(FROM_UNIXTIME(event_time / 1000), '+00:00', 'America/New_York')
            BETWEEN yesterday_start_time AND yesterday_end_time
    ) y ON r.currency_pair = y.currency_pair
    WHERE r.rn = 1 AND y.rn = 1
    ON DUPLICATE KEY UPDATE
        rate = r.current_rate,
        `change` = COALESCE(
            CONCAT(
                ROUND(100 * (r.current_rate - y.yesterday_rate) / y.yesterday_rate, 3), '%'
            ),
            'N/A'
        );
END //
DELIMITER ;
