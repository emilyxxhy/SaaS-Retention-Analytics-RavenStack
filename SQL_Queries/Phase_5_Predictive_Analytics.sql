-- Pillar A: 
WITH FirstUserAction AS (
    SELECT 
        a.account_id,
        a.signup_date,
        f.feature_name,
        f.usage_date,
        -- Ranks the usage dates to find the very first one per account
        ROW_NUMBER() OVER (PARTITION BY a.account_id ORDER BY f.usage_date ASC) as action_rank
    FROM 
        `ravenstack-analytics.saas_data.usage` f
    JOIN 
        `ravenstack-analytics.saas_data.subscriptions` s 
        ON f.subscription_id = s.subscription_id
    JOIN 
        `ravenstack-analytics.saas_data.accounts` a 
        ON s.account_id = a.account_id
    WHERE 
        f.feature_name = 'feature_12' -- Replace with whatever feature you consider your "Magic Moment"
)

SELECT 
    account_id,
    signup_date,
    usage_date AS first_value_date,
    -- BigQuery specific date math
    DATE_DIFF(usage_date, signup_date, DAY) AS time_to_value_days 
FROM 
    FirstUserAction
WHERE 
    action_rank = 1;

-- Pillar B:
SELECT 
    e1.feature_name AS feature_a,
    e2.feature_name AS feature_b,
    COUNT(DISTINCT e1.subscription_id) AS co_occurrence_count
FROM 
    `ravenstack-analytics.saas_data.usage` e1
JOIN 
    `ravenstack-analytics.saas_data.usage` e2 
    ON e1.subscription_id = e2.subscription_id 
    -- THE FIX: Look for usage within 7 days of each other instead of the exact same day
    AND ABS(DATE_DIFF(e1.usage_date, e2.usage_date, DAY)) <= 7
WHERE 
    e1.feature_name < e2.feature_name -- Prevents joining a feature to itself or duplicating pairs (A+B vs B+A)
GROUP BY 
    feature_a, 
    feature_b
ORDER BY 
    co_occurrence_count DESC
LIMIT 50;

--Pillar C:
WITH DailyUsage AS (
    SELECT 
        subscription_id,
        usage_date,
        SUM(usage_count) AS daily_events
    FROM 
        `ravenstack-analytics.saas_data.usage`
    GROUP BY 
        subscription_id, usage_date
),

RollingAverages AS (
    SELECT 
        subscription_id,
        usage_date,
        daily_events,
        -- BigQuery: 7-day moving average using exact calendar ranges
        AVG(daily_events) OVER (
            PARTITION BY subscription_id 
            ORDER BY UNIX_DATE(usage_date) 
            RANGE BETWEEN 6 PRECEDING AND CURRENT ROW
        ) AS avg_last_7_days,
        
        -- BigQuery: 28-day moving average using exact calendar ranges
        AVG(daily_events) OVER (
            PARTITION BY subscription_id 
            ORDER BY UNIX_DATE(usage_date) 
            RANGE BETWEEN 27 PRECEDING AND CURRENT ROW
        ) AS avg_last_28_days
    FROM 
        DailyUsage
)

SELECT 
    subscription_id,
    usage_date,
    avg_last_7_days,
    avg_last_28_days,
    -- Flag accounts where recent 7-day activity is less than half of their normal 28-day activity
    CASE 
        WHEN avg_last_7_days < (0.5 * avg_last_28_days) THEN 'High Churn Risk'
        ELSE 'Healthy' 
    END AS risk_status
FROM 
    RollingAverages
WHERE 
    -- Normally you would filter this to CURRENT_DATE() to see who is at risk *today*
    -- For historical analysis, we will just look at users who had enough history to calculate
    avg_last_28_days > 0 
ORDER BY 
    usage_date DESC;
