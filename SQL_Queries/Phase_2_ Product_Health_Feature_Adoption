-- The "Feature Gap" Matrix: Finding missing features by tier
SELECT 
    f.feature_name,
    SUM(CASE WHEN s.plan_tier = 'Basic' THEN f.usage_count ELSE 0 END) AS basic_uses,
    SUM(CASE WHEN s.plan_tier = 'Pro' THEN f.usage_count ELSE 0 END) AS pro_uses,
    SUM(CASE WHEN s.plan_tier = 'Enterprise' THEN f.usage_count ELSE 0 END) AS enterprise_uses
FROM ravenstack-analytics.saas_data.usage f
JOIN ravenstack-analytics.saas_data.subscriptions s ON f.subscription_id = s.subscription_id
GROUP BY f.feature_name
ORDER BY CAST(REGEXP_EXTRACT(f.feature_name, r'\d+') AS INT64);

-- 1. Which feature_name has the highest and lowest usage_count?
SELECT 
    feature_name,
    SUM(usage_count) AS total_usage
FROM ravenstack-analytics.saas_data.usage
GROUP BY feature_name
ORDER BY total_usage DESC;

-- 2. Which features have the highest error_count? Are they beta features?
SELECT 
    feature_name,
    is_beta_feature,
    SUM(error_count) AS total_errors,
    SUM(usage_count) AS total_uses,
    ROUND(SUM(error_count) / SUM(usage_count) * 100, 2) AS error_rate_percentage
FROM ravenstack-analytics.saas_data.usage
GROUP BY feature_name, is_beta_feature
ORDER BY total_errors DESC
LIMIT 5;

-- 2b. The Beta vs. Non-Beta Error Rate Comparison
SELECT 
    is_beta_feature,
    SUM(error_count) AS total_errors,
    SUM(usage_count) AS total_uses,
    ROUND(SUM(error_count) / SUM(usage_count) * 100, 2) AS error_rate_percentage
FROM ravenstack-analytics.saas_data.usage
GROUP BY is_beta_feature;
-- 1. Sticky Features: Most frequently used features among the "Retained" cohort
SELECT 
    f.feature_name,
    SUM(f.usage_count) AS total_retained_usage
FROM ravenstack-analytics.saas_data.usage f
JOIN `ravenstack-analytics.saas_data.subscriptions` s ON f.subscription_id = s.subscription_id
JOIN `ravenstack-analytics.saas_data.accounts` a ON s.account_id = a.account_id
WHERE a.churn_flag = FALSE
GROUP BY f.feature_name
ORDER BY total_retained_usage DESC
LIMIT 5;

-- 2. Tier-Based Behavior: Enterprise Feature Utilization vs. Seat Count
SELECT 
    s.plan_tier,
    COUNT(DISTINCT f.feature_name) AS unique_features_used,
    SUM(f.usage_count) AS total_feature_usage,
    ROUND(AVG(s.seats), 1) AS average_seats_per_account
FROM ravenstack-analytics.saas_data.usage f
JOIN ravenstack-analytics.saas_data.subscriptions s ON f.subscription_id = s.subscription_id
GROUP BY s.plan_tier
ORDER BY total_feature_usage DESC;

-- 3. Time-to-Error Correlation (Do longer sessions = more errors?)
SELECT 
    CORR(usage_duration_secs, error_count) AS time_to_error_correlation
FROM ravenstack-analytics.saas_data.usage;
