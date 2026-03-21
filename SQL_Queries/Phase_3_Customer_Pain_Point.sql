-- 1. Average Resolution Time by Ticket Priority
SELECT 
    priority,
    COUNT(ticket_id) AS total_tickets,
    ROUND(AVG(resolution_time_hours), 1) AS avg_resolution_hours
FROM ravenstack-analytics.saas_data.support_tickets
GROUP BY priority
ORDER BY avg_resolution_hours DESC;

-- 2. VIP Treatment: Do Enterprise customers get faster support?
SELECT 
    a.plan_tier,
    COUNT(t.ticket_id) AS total_tickets,
    ROUND(AVG(t.first_response_time_minutes), 1) AS avg_first_response_mins,
    ROUND(AVG(t.resolution_time_hours), 1) AS avg_resolution_hours
FROM ravenstack-analytics.saas_data.support_tickets t
JOIN `ravenstack-analytics.saas_data.accounts` a ON t.account_id = a.account_id
GROUP BY a.plan_tier
ORDER BY avg_resolution_hours ASC;

-- 3. Low Satisfaction Tickets (Score < 3)
SELECT *
FROM ravenstack-analytics.saas_data.support_tickets
WHERE satisfaction_score IS NOT NULL;

-- Let's see every score that actually exists!
SELECT 
    satisfaction_score, 
    COUNT(ticket_id) AS total_tickets
FROM ravenstack-analytics.saas_data.support_tickets
WHERE satisfaction_score IS NOT NULL
GROUP BY satisfaction_score
ORDER BY satisfaction_score ASC;

-- 1. Speed vs Quality: Does a faster response mean a higher score?
SELECT 
    satisfaction_score,
    COUNT(ticket_id) AS total_tickets,
    ROUND(AVG(first_response_time_minutes), 1) AS avg_first_response_mins,
    ROUND(AVG(resolution_time_hours), 1) AS avg_resolution_hours
FROM ravenstack-analytics.saas_data.support_tickets
WHERE satisfaction_score IS NOT NULL
GROUP BY satisfaction_score
ORDER BY satisfaction_score DESC;

-- 2. Technical Blindspots: Do accounts with 'urgent' tickets also have high feature errors?
WITH UrgentAccounts AS (
    SELECT DISTINCT account_id 
    FROM ravenstack-analytics.saas_data.support_tickets
    WHERE priority IN ('urgent', 'high')
)
SELECT 
    CASE WHEN u.account_id IS NOT NULL THEN 'Has Urgent Tickets' ELSE 'No Urgent Tickets' END AS ticket_status,
    COUNT(DISTINCT a.account_id) AS total_accounts,
    ROUND(AVG(f.error_count), 1) AS avg_errors_per_account
FROM ravenstack-analytics.saas_data.accounts a
JOIN ravenstack-analytics.saas_data.subscriptions s ON a.account_id = s.account_id
JOIN ravenstack-analytics.saas_data.usage f ON s.subscription_id = f.subscription_id
LEFT JOIN UrgentAccounts u ON a.account_id = u.account_id
GROUP BY ticket_status;

-- 3. Escalation Red Flags: Which industries escalate the most tickets?
SELECT 
    a.industry,
    COUNT(t.ticket_id) AS total_escalated_tickets,
    ROUND(COUNT(t.ticket_id) / (SELECT COUNT(*) FROM ravenstack-analytics.saas_data.support_tickets WHERE escalation_flag = TRUE) * 100, 1) AS percentage_of_all_escalations
FROM ravenstack-analytics.saas_data.support_tickets t
JOIN ravenstack-analytics.saas_data.accounts a ON t.account_id = a.account_id
WHERE t.escalation_flag = TRUE
GROUP BY a.industry
ORDER BY total_escalated_tickets DESC;

-- Niche 1 FIXED: Actual Revenue at Risk (Avoiding the Fan-Out Trap!)
WITH EscalatedAccounts AS (
    -- Step 1: Find the unique accounts that have at least one escalated ticket
    SELECT DISTINCT account_id
    FROM `ravenstack-analytics.saas_data.support_tickets`
    WHERE escalation_flag = TRUE
)
-- Step 2: Sum their MRR exactly once
SELECT 
    COUNT(DISTINCT s.account_id) AS total_angry_accounts,
    ROUND(SUM(s.mrr_amount), 2) AS true_mrr_at_risk,
    ROUND(SUM(s.mrr_amount) / (SELECT SUM(mrr_amount) FROM `ravenstack-analytics.saas_data.subscriptions`) * 100, 2) AS real_percent_of_company_mrr
FROM `ravenstack-analytics.saas_data.subscriptions` s
JOIN EscalatedAccounts e ON s.account_id = e.account_id;

-- Niche 2: Scalability (Does more users = more support tickets?)
WITH TicketsPerAccount AS (
    SELECT 
        account_id, 
        COUNT(ticket_id) AS ticket_count
    FROM `ravenstack-analytics.saas_data.support_tickets`
    GROUP BY account_id
)
SELECT 
    CORR(a.seats, COALESCE(t.ticket_count, 0)) AS seats_to_tickets_correlation
FROM `ravenstack-analytics.saas_data.accounts` a
LEFT JOIN TicketsPerAccount t ON a.account_id = t.account_id;
