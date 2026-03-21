## 📖 Data Dictionary: RavenStack Analytics
This document provides a comprehensive breakdown of the data structures, types, and definitions within the RavenStack ecosystem. The data is organized into a Star Schema to optimize for Analytical Processing (OLAP).

## 🗺️ Entity Relationship Diagram (ERD)

The dataset consists of **5 core tables** interconnected via `account_id` and `subscription_id`.

---

## 🗂️ Table Definitions

### 1. accounts.csv

The primary **Dimension Table** containing identifying information for B2B customers.

| Column Name      | Data Type        | Description                          | Notes                           |
|-----------------|-----------------|--------------------------------------|---------------------------------|
| account_id      | String (PK)     | Unique identifier for the customer   | Primary Key                     |
| account_name    | String          | Fictional company name               |                                 |
| industry        | Categorical     | The business vertical                | DevTools, EdTech, FinTech, etc. |
| country         | String          | ISO-2 Country Code                   |                                 |
| signup_date     | Date            | Date the account was created         |                                 |
| referral_source | Categorical     | Acquisition channel                  | Organic, Ads, Partner, etc.     |
| plan_tier       | Categorical     | Initial subscription tier            | Basic, Pro, Enterprise          |
| seats           | Integer         | Number of licensed users             |                                 |
| is_trial        | Boolean         | Trial status                         | True if currently trialing      |
| churn_flag      | Boolean         | Lifetime churn status                | True if they ever churned       |

---

### 2. subscriptions.csv

A **Fact Table** tracking revenue cycles and subscription lifecycles.

| Column Name     | Data Type     | Description                           | Notes                     |
|----------------|--------------|---------------------------------------|--------------------------|
| subscription_id| String (PK)  | Unique identifier for the cycle       | Primary Key              |
| account_id     | String (FK)  | Links to the accounts table           | Foreign Key              |
| start_date     | Date         | Date the billing cycle began          |                          |
| end_date       | Date         | Date the cycle ended                  | NULL if plan is active   |
| mrr_amount     | Currency     | Monthly Recurring Revenue             |                          |
| billing_cycle  | Categorical  | Payment frequency                     | Monthly, Annual          |
| upgrade_flag   | Boolean      | Mid-cycle upgrade indicator           | True if tier increased   |
| auto_renew     | Boolean      | Auto-billing status                   |                          |

---

### 3. feature_usage.csv

A high-volume telemetry log capturing user behavioral interactions.

| Column Name     | Data Type    | Description                          | Notes                          |
|----------------|-------------|--------------------------------------|--------------------------------|
| usage_id       | String (PK) | Unique event identifier              |                                |
| subscription_id| String (FK) | Links to the active subscription     | Used for TTV (Time-to-Value)   |
| usage_date     | Date        | Date the event occurred              |                                |
| feature_name   | String      | The specific tool utilized           | 40 unique feature names        |
| usage_count    | Integer     | Frequency of use in a single day     |                                |
| error_count    | Integer     | Technical errors logged              | Used for Product Health KPIs   |
| is_beta        | Boolean     | Experimental feature flag            |                                |

---

### 4. support_tickets.csv

A log of customer success interactions and satisfaction metrics.

| Column Name   | Data Type    | Description                         | Notes                          |
|---------------|-------------|-------------------------------------|--------------------------------|
| ticket_id     | String (PK) | Unique ticket identifier            |                                |
| account_id    | String (FK) | The customer submitting the request |                                |
| priority      | Categorical | Severity of the issue               | Low, Medium, High, Urgent      |
| response_time | Float       | Time to first response (hours)      | Used for SLA tracking          |
| csat_score    | Integer     | Customer Satisfaction (1–5)         | NULL if no survey response     |
| escalated     | Boolean     | Escalation status                   | True if sent to Tier-2/Senior  |

---

### 5. churn_events.csv

An **Outcome Table** used to analyze the *why* and *when* of customer loss.

| Column Name   | Data Type    | Description                        | Notes                               |
|---------------|-------------|------------------------------------|-------------------------------------|
| churn_id      | String (PK) | Unique churn event identifier      |                                     |
| account_id    | String (FK) | The customer who churned           |                                     |
| churn_date    | Date        | Date service was terminated        |                                     |
| reason_code   | Categorical | Primary reason for cancellation    | Pricing, Support, Product Gap       |
| feedback_text | String      | Qualitative feedback comment       | Text-based user input               |

---

## 🛠️ Data Integrity Rules

To ensure accurate analysis, all SQL queries in this project follow these constraints:

- **Temporal Consistency**  
  `signup_date ≤ start_date ≤ churn_date`

- **Handling NULLs**  
  `csat_score` and `feedback_text` are expected to contain NULL values, as surveys are optional.

- **Churn Definition**  
  A customer is defined as **"Churned"** only if:
  - `churn_flag = TRUE`, and  
  - A corresponding entry exists in the `churn_events` table. Definition: A customer is defined as "Churned" only if churn_flag = TRUE and a corresponding entry exists in the churn_events table.
