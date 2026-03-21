-- 1. Overall Churn Volume & Total Money Refunded
SELECT 
    COUNT(DISTINCT c.account_id) AS total_churned_accounts,
    ROUND(SUM(c.refund_amount_usd), 2) AS total_money_refunded_usd
FROM ravenstack-analytics.saas_data.churrn_events c;

-- 2. The #1 Reason for Leaving
SELECT 
    reason_code,
    COUNT(churn_event_id) AS total_cancellations,
    ROUND(COUNT(churn_event_id) / (SELECT COUNT(*) FROM ravenstack-analytics.saas_data.churrn_events) * 100, 1) AS percent_of_all_churn
FROM ravenstack-analytics.saas_data.churrn_events
GROUP BY reason_code
ORDER BY total_cancellations DESC;

-- 3. The Golden Question: Did bad support CAUSE the churn?
WITH BadSupportTickets AS (
    SELECT DISTINCT account_id
    FROM `ravenstack-analytics.saas_data.support_tickets`
    WHERE resolution_time_hours > 48.0
)
SELECT 
    COUNT(c.churn_event_id) AS churned_for_support_with_bad_ticket,
    (SELECT COUNT(*) FROM ravenstack-analytics.saas_data.churrn_events WHERE reason_code = 'support') AS total_support_churners,
    ROUND(COUNT(c.churn_event_id) / (SELECT COUNT(*) FROM ravenstack-analytics.saas_data.churrn_events WHERE reason_code = 'support') * 100, 1) AS proof_of_fault_percentage
FROM ravenstack-analytics.saas_data.churrn_events c
JOIN BadSupportTickets b ON c.account_id = b.account_id
WHERE c.reason_code = 'support';

-- Niche 1: Revenue Churn (Volume vs. Value Loss)
-- Are we losing poor customers or our wealthiest customers?
SELECT 
    s.plan_tier,
    COUNT(DISTINCT c.account_id) AS total_accounts_lost,
    ROUND(SUM(s.mrr_amount), 2) AS total_mrr_lost_usd
FROM ravenstack-analytics.saas_data.churrn_events c
JOIN `ravenstack-analytics.saas_data.subscriptions` s ON c.account_id = s.account_id
GROUP BY s.plan_tier
ORDER BY total_mrr_lost_usd DESC;

-- Niche 2: The "Time-to-Rage-Quit" (Survival Curve)
-- Do people who leave because of 'pricing' quit faster than people who leave for 'support'?
SELECT 
    c.reason_code,
    COUNT(c.churn_event_id) AS total_cancellations,
    ROUND(AVG(DATE_DIFF(CAST(c.churn_date AS DATE), CAST(a.signup_date AS DATE), DAY)), 1) AS avg_days_to_churn
FROM ravenstack-analytics.saas_data.churrn_events c
JOIN `ravenstack-analytics.saas_data.accounts` a ON c.account_id = a.account_id
GROUP BY c.reason_code
ORDER BY avg_days_to_churn ASC;

-- Advanced 3: The "Silent Downgrade" Warning Sign
-- Did users who left because of 'budget' try to downgrade their plan first?
SELECT 
    preceding_downgrade_flag,
    COUNT(churn_event_id) AS total_cancellations
FROM ravenstack-analytics.saas_data.churrn_events
WHERE reason_code IN ('pricing', 'budget')
GROUP BY preceding_downgrade_flag;
