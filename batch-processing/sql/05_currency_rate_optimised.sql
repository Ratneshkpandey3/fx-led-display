CREATE INDEX idx_event_time_minute_table ON currency_rates(event_time);

-- Create the currency_rate_changes_opt table to store results
CREATE TABLE currency_rate_changes_opt (
    id INT AUTO_INCREMENT PRIMARY KEY,
    ccy_couple VARCHAR(10) NOT NULL,
    rate DECIMAL(10, 5) NOT NULL,
    `change` VARCHAR(10) NOT NULL,
    UNIQUE (ccy_couple) -- Add a unique constraint on ccy_couple
);

-- Create the event to update currency rates every minute
DELIMITER //
CREATE EVENT update_currency_rates_per_minute_table
ON SCHEDULE EVERY 1 MINUTE
STARTS CURRENT_TIMESTAMP
DO
BEGIN
    DECLARE active_time_limit INT DEFAULT 30000;
    DECLARE yesterday_start_time DATETIME;
    DECLARE yesterday_end_time DATETIME;
    DECLARE today_max_time BIGINT;

    -- Set the time ranges for yesterday
    SET yesterday_start_time = '2024-02-20 16:59:30';
    SET yesterday_end_time = '2024-02-20 17:00:00';

    -- Get the maximum event_time in milliseconds
    SELECT MAX(event_time) INTO today_max_time FROM currency_rates;

    -- Drop temporary tables if they exist
    DROP TEMPORARY TABLE IF EXISTS recent_rates;
    DROP TEMPORARY TABLE IF EXISTS yesterday_rates;

    -- Create a temporary table for recent rates
    CREATE TEMPORARY TABLE recent_rates AS
    SELECT
        currency_pair,
        rate AS current_rate,
        ROW_NUMBER() OVER (PARTITION BY currency_pair ORDER BY event_time DESC) AS rn
    FROM currency_rates
    WHERE rate <> 0
    AND event_time >= today_max_time - active_time_limit;

    -- Create a temporary table for yesterday's rates
    CREATE TEMPORARY TABLE yesterday_rates AS
    SELECT
        currency_pair,
        rate AS yesterday_rate,
        ROW_NUMBER() OVER (PARTITION BY currency_pair ORDER BY event_time DESC) AS rn
    FROM currency_rates
    WHERE rate <> 0
    AND CONVERT_TZ(FROM_UNIXTIME(event_time / 1000), '+00:00', 'America/New_York')
        BETWEEN yesterday_start_time AND yesterday_end_time;

    -- Insert or update the results in the currency_rate_changes_opt table
    INSERT INTO currency_rate_changes_opt (ccy_couple, rate, `change`)
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
    ON DUPLICATE KEY UPDATE
        rate = VALUES(rate),
        `change` = VALUES(`change`);

    -- Drop temporary tables
    DROP TEMPORARY TABLE IF EXISTS recent_rates;
    DROP TEMPORARY TABLE IF EXISTS yesterday_rates;
END //
DELIMITER ;
