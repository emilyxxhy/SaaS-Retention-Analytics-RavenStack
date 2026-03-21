EGIN SELECT * FROM ravenstack-analytics.saas_data.accounts;

-- 1. Total Customers & Trial vs. Paid Ratio
SELECT
  COUNT(DISTINCT account_id) AS total_customers,
  ROUND(COUNTIF(is_trial = TRUE) / COUNT(account_id) * 100, 1)
    AS trial_percentage,
  ROUND(COUNTIF(is_trial = FALSE) / COUNT(account_id) * 100, 1)
    AS paid_percentage
FROM ravenstack-analytics.saas_data.accounts;

-- 2. Industry Majority (Who uses our app the most?)
SELECT industry, COUNT(account_id) AS total_companies
FROM ravenstack-analytics.saas_data.accounts
GROUP BY industry
ORDER BY total_companies DESC;

-- 3. Top Referral Sources for Enterprise Customers
SELECT referral_source, COUNT(account_id) AS enterprise_customers
FROM ravenstack-analytics.saas_data.accounts
WHERE plan_tier = 'Enterprise'
GROUP BY referral_source
ORDER BY enterprise_customers DESC;

-- 1. MRR Contribution: Which industry actually pays us the most?
SELECT a.industry, SUM(s.mrr_amount) AS total_mrr
FROM ravenstack-analytics.saas_data.accounts a
LEFT JOIN ravenstack-analytics.saas_data.subscriptions s
  ON a.account_id = s.account_id
GROUP BY a.industry
ORDER BY total_mrr DESC;

-- 2. Sales Cycle: Average Time-to-Close (from Signup to First Paid Subscription)
WITH
  FirstPaidSub AS (
    SELECT account_id, MIN(start_date) AS first_paid_date
    FROM ravenstack-analytics.saas_data.subscriptions
    WHERE is_trial = FALSE
    GROUP BY account_id
  )
SELECT
  ROUND(
    AVG(
      DATE_DIFF(
        CAST(f.first_paid_date AS DATE), CAST(a.signup_date AS DATE), DAY)),
    1)
    AS avg_time_to_close_days
FROM ravenstack-analytics.saas_data.accounts a
JOIN FirstPaidSub f
  ON a.account_id = f.account_id;

-- 3. Billing Behavior: Auto-renew rates for Annual vs. Monthly
SELECT
  billing_frequency,
  COUNT(subscription_id) AS total_subscriptions,
  ROUND(COUNTIF(auto_renew_flag = TRUE) / COUNT(subscription_id) * 100, 1)
    AS auto_renew_percentage
FROM ravenstack-analytics.saas_data.subscriptions
GROUP BY billing_frequency;

END;

-- Exploration: Average Time-to-Close by Plan Tier
WITH FirstPaidSub AS (
    SELECT account_id, MIN(start_date) AS first_paid_date
    FROM `ravenstack-analytics.saas_data.subscriptions`
    WHERE is_trial = FALSE
    GROUP BY account_id
)
SELECT 
    a.plan_tier,
    COUNT(a.account_id) AS total_deals_closed,
    ROUND(AVG(DATE_DIFF(CAST(f.first_paid_date AS DATE), CAST(a.signup_date AS DATE), DAY)), 1) AS avg_time_to_close_days
FROM `ravenstack-analytics.saas_data.accounts` a
JOIN FirstPaidSub f ON a.account_id = f.account_id
GROUP BY a.plan_tier
ORDER BY avg_time_to_close_days DESC;

-- Exploration: Average Time-to-Close by Industry
WITH FirstPaidSub AS (
    SELECT account_id, MIN(start_date) AS first_paid_date
    FROM `ravenstack-analytics.saas_data.subscriptions`
    WHERE is_trial = FALSE
    GROUP BY account_id
)
SELECT 
    a.industry,
    COUNT(a.account_id) AS total_deals_closed,
    ROUND(AVG(DATE_DIFF(CAST(f.first_paid_date AS DATE), CAST(a.signup_date AS DATE), DAY)), 1) AS avg_time_to_close_days
FROM `ravenstack-analytics.saas_data.accounts` a
JOIN FirstPaidSub f ON a.account_id = f.account_id
GROUP BY a.industry
ORDER BY avg_time_to_close_days DESC;

-- The "Paywall" Hypothesis: What features are Pro users using that Basic users aren't?
SELECT 
    a.plan_tier,
    f.feature_name,
    COUNT(f.usage_id) AS total_times_used
FROM ravenstack-analytics.saas_data.accounts a
JOIN ravenstack-analytics.saas_data.subscriptions s ON a.account_id = s.account_id
JOIN ravenstack-analytics.saas_data.usage f ON s.subscription_id = f.subscription_id
WHERE a.plan_tier IN ('Basic', 'Pro', 'Enterprise')
GROUP BY a.plan_tier, f.feature_name
ORDER BY a.plan_tier, total_times_used DESC;

