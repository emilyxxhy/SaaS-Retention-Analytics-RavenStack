# RavenStack: End-to-End SaaS Retention & Predictive Churn Analytics

![SQL](https://img.shields.io/badge/SQL-Advanced-blue) ![BigQuery](https://img.shields.io/badge/Google_BigQuery-Data_Warehouse-blue) ![Analytics](https://img.shields.io/badge/Analytics-Predictive_Modeling-green) ![Domain](https://img.shields.io/badge/Domain-B2B_SaaS-orange) ![Status](https://img.shields.io/badge/Status-Production_Ready-success)
-----

# RavenStack: End-to-End SaaS Retention & Predictive Churn Analytics
**Author:** River @ Rivalytics  
**Blog:** [Building a Dataset Generator App Journey](https://rivalytics.medium.com)  
**License:** MIT-like (Fully synthetic, zero Personally Identifiable Information / PII)  
**Refresh Interval:** Monthly  
**Data Format:** CSV
    

## 📌 Executive Summary

  * **Core Objective:** A comprehensive behavioral data pipeline and predictive analytics engine built for RavenStack. This project shifts the analytics strategy from standard descriptive reporting to predictive churn modeling.
  * **Technical Approach:** Built natively within the Google Cloud ecosystem, leveraging advanced Standard SQL (CTEs, Window Functions, Self-Joins, and Time-Series) in BigQuery to extract user lifecycle signals from raw telemetry logs.
  * **Business Impact:** Identified $2.07M in MRR at risk due to support bottlenecks and built a "Silent Churn" detector to flag engagement drops 30 days before cancellation.
  * **Project Scope:** Executed during the platform's pre-launch pilot phase to establish rigorous baseline retention metrics and behavioral patterns prior to scaling.

-----

## 🏢 Business Context & Tech Stack

RavenStack is a B2B SaaS platform delivering AI-driven productivity tools. The primary objective of this project is to audit pre-launch telemetry data to establish baseline retention metrics and architect an automated, predictive churn-prevention framework.

  * **Database:** Google BigQuery
  * **Language:** Standard SQL
  * **Visualization:** Looker Studio / Tableau
  * **Data Schema:** Star schema consisting of `accounts`, `subscriptions`, `feature_usage`, `support_tickets`, and `churn_events`.

# ⭐ Featured SQL Analysis (Core Business Questions)

This section demonstrates how SQL is used to answer critical product and business questions, uncover insights, and drive strategic decisions.

---

## 🚨 1. Does Poor Support Actually Cause Churn?

### Business Question
Are customers churning because of slow support response times?

### SQL Query
```sql
WITH BadSupportTickets AS (
    SELECT DISTINCT account_id
    FROM support_tickets
    WHERE resolution_time_hours > 48
)

SELECT 
    COUNT(*) AS churned_due_to_bad_support
FROM churn_events c
JOIN BadSupportTickets b 
    ON c.account_id = b.account_id
WHERE c.reason_code = 'support';
```

### Insight
👉 **80.7%** of support-related churn involved tickets unresolved for more than 48 hours.

### Business Impact
- Clear causal signal between SLA failure and churn  
- High-priority intervention point for Customer Success  

---

## 💰 2. Revenue at Risk from Support Escalations

### Business Question
How much revenue is tied to customers experiencing escalations?

### SQL Query
```sql
WITH EscalatedAccounts AS (
    SELECT DISTINCT account_id
    FROM support_tickets
    WHERE escalation_flag = TRUE
)

SELECT 
    SUM(mrr_amount) AS mrr_at_risk
FROM subscriptions s
JOIN EscalatedAccounts e 
    ON s.account_id = e.account_id;
```

### Insight
👉 **$2.07M (~18% of total MRR)** is at risk.

### Business Impact
- Identifies high-value accounts needing attention  
- Justifies investment in Tier-2 support  

---

## ⚡ 3. Time-to-Value (Activation Speed)

### Business Question
How quickly do users reach their first meaningful product interaction?

### SQL Query
```sql
WITH FirstAction AS (
    SELECT 
        account_id,
        usage_date,
        ROW_NUMBER() OVER (
            PARTITION BY account_id 
            ORDER BY usage_date
        ) AS rn
    FROM feature_usage
)

SELECT 
    account_id,
    usage_date AS first_value_date
FROM FirstAction
WHERE rn = 1;
```

### Insight
👉 Faster activation strongly correlates with retention.

### Business Impact
- Optimize onboarding flows  
- Reduce early churn risk  

---

## 🔍 4. Feature Adoption → Retention Drivers

### Business Question
Which features are most associated with retained users?

### SQL Query
```sql
SELECT 
    f.feature_name,
    SUM(f.usage_count) AS total_usage
FROM feature_usage f
JOIN subscriptions s 
    ON f.subscription_id = s.subscription_id
JOIN accounts a 
    ON s.account_id = a.account_id
WHERE a.churn_flag = FALSE
GROUP BY f.feature_name
ORDER BY total_usage DESC;
```

### Insight
👉 High-usage features (e.g., `feature_32`) correlate with retention.

### Business Impact
- Prioritize onboarding exposure  
- Inform product roadmap  

---

## ⚠️ 5. Predicting Churn via Behavioral Signals

### Business Question
Can declining engagement predict churn?

### SQL Logic
```sql
CASE 
    WHEN avg_last_7_days < (0.5 * avg_last_28_days)
    THEN 'High Churn Risk'
    ELSE 'Healthy'
END
```

### Insight
👉 Short-term engagement drop is an early churn signal.

### Business Impact
- Enables proactive retention campaigns  
- Forms basis of churn prediction system  

---

# 🏢 Business Context & Tech Stack

### Company Context
**RavenStack** is a B2B SaaS platform delivering AI-driven productivity tools.

### Objective
Audit user behavior and design a predictive churn prevention system.

### Tech Stack
- **Warehouse:** Google BigQuery  
- **Language:** Standard SQL  
- **Visualization:** Looker Studio / Tableau  
- **Schema:** Star schema  
--- 
## 📊 Foundational EDA & Diagnostics (Phases 1-4)

Before developing predictive models, a rigorous exploratory data analysis (EDA) was conducted to diagnose baseline business health across Revenue, Product, Support, and Churn.

### Phase 1: Customer Base & Revenue Health

  * **The Insight:** The **Dev Tools** segment is the highest performing vertical, converting in just 34.5 days and generating **$2.4M in MRR**. Conversely, **Cybersecurity** clients face a sluggish 52.1-day sales cycle.
  * **The Pain Point:** Extended sales cycles for Cybersecurity accounts are delaying revenue realization and increasing Customer Acquisition Cost (CAC).
  * **Implementation Plan:** RevOps should shorten the Dev Tools trial period to 14 days to accelerate cash flow. Product Marketing must integrate security compliance documentation directly into the Day-1 onboarding flow for Cybersecurity accounts to remove procurement friction.

### Phase 2: Product Health & Feature Adoption

  * **The Insight:** `feature_32` is the undisputed "Aha\! Moment," ranking as the top retention driver with 6,686 uses. Surprisingly, legacy features generate significantly more errors than new Beta features (which maintain a low 5.53% error rate).
  * **The Pain Point:** Technical debt in legacy code is degrading the core experience, while users are hitting paywall friction points on `feature_12` and `feature_40` before seeing full value.
  * **Implementation Plan:** Product Management should prioritize Day-1 onboarding tutorials that guide users toward `feature_32`. Engineering must pause non-critical feature rollouts to refactor and resolve legacy bugs in `feature_4` and `feature_9`.

### Phase 3: Support Operations & Customer Experience

  * **The Insight:** While escalated tickets are low volume, 91 unique accounts in the queue represent **$2.07M (18.34%) of total MRR**. Seat count does not correlate with ticket volume (0.02), proving the platform scales well for Enterprise.
  * **The Pain Point:** High-value enterprise revenue is disproportionately at risk due to a critical bottleneck in Tier-2 support escalations.
  * **Implementation Plan:** Customer Success must deploy an automated routing system to instantly flag Enterprise tickets containing high-risk keywords (e.g., "error," "outage") to senior agents, bypassing Tier-1 queues.

### Phase 4: Churn & Retention Diagnostics

  * **The Insight:** 80.7% of customers who churned due to "support" had a ticket ignored for over 48 hours. Enterprise churn is catastrophic, accounting for \*\*$9.8M in lost MRR** compared to only ~$898k in the Basic tier.
  * **The Pain Point:** Poor SLA adherence is the direct root cause of massive revenue hemorrhage among enterprise clients who demonstrate a high initial intent to stay.
  * **Implementation Plan:** Enforce a strict 24-hour SLA for all Enterprise accounts. Automatically trigger proactive CS interventions if an Enterprise ticket remains unresolved past the 12-hour mark.

-----

## 🚀 Predictive Behavioral Modeling (Phase 5)

The project utilizes a predictive, behavioral analytics framework broken into three distinct lifecycle pillars:

  * **Pillar A: Activation & The Setup Funnel:** Measures Time-to-Value (TTV) by calculating the velocity at which new accounts trigger their first core `feature_usage` event within the crucial 14-day onboarding window.
  * **Pillar B: Engagement & Feature Synergy:** Utilizes **Market Basket Analysis** (Self-Joins and rolling 7-day windows) to identify correlated feature usage and track if new features cannibalize legacy tools.
  * **Pillar C: The Early Warning System (Silent Churn):** Analyzes the slope of decreasing activity (engagement degradation) 30 to 60 days before cancellation to predict "Silent Churn" before the user ever contacts support.

-----

## 💡 Consolidated Implementation Roadmap

To operationalize these insights, the following data pipelines should be integrated into production:

1.  **Automate Early Warning:** Schedule `03_predictive_churn_warning.sql` to run daily at 6:00 AM, pushing "High Risk" `account_ids` directly to the Customer Success CRM.
2.  **Optimize UI for Cross-Selling:** Implement an in-app prompt suggesting `feature_4` to users immediately after they trigger `feature_11` (based on Market Basket synergy).
3.  **Targeted Marketing:** Pivot ad spend toward Dev Tools channels. Send automated 10% discount upgrade campaigns to Basic users as they approach usage limits on `feature_12` and `feature_40`.
4.  **Refine Onboarding:** Investigate accounts with a TTV \> 30 days to identify and remove specific UX bottlenecks in the setup funnel.

-----

## 🔗 Dataset Architecture

The analysis is based on the **RavenStack Synthetic SaaS Dataset**, a multi-table relational schema designed to mimic real-world production environments.

### Table Relationships

```text
accounts (PK: account_id)
│
├── subscriptions (FK → accounts.account_id)
│   └── feature_usage (FK → subscriptions.subscription_id)
│
├── support_tickets (FK → accounts.account_id)
└── churn_events (FK → accounts.account_id)
```

### Data Volume

  * `accounts`: 500 records
  * `subscriptions`: 5,000 records
  * `feature_usage`: 25,000 records
  * `support_tickets`: 2,000 records
  * `churn_events`: 600 records

-----

## 📂 Repository Structure

```text
/SQL_Queries
  ├── 01_time_to_value_analysis.sql     # CTEs and date math for activation velocity
  ├── 02_feature_market_basket.sql      # Self-joins and rolling windows for product synergy
  └── 03_predictive_churn_warning.sql   # Time-series window functions for engagement degradation
/Data_Dictionary
  └── DATA_DICTIONARY.md                # Detailed schema definitions and column types
README.md                               # Project overview and executive summary
```

-----

## 📄 Licensing & Usage
This dataset is fully synthetic and distributed under a permissive MIT-like license.
