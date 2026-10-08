# Banking Loan & Risk Analytics

## 📌 Project Overview

**Banking Loan & Risk Analytics** is a PostgreSQL-based SQL analytics project designed to analyze the complete loan lifecycle — from **loan application and approval to disbursement, EMI payments, delinquency, collection, and recovery**.

The project uses SQL to generate business insights related to:

* Loan applications and approval performance
* Customer loan exposure
* Loan portfolio size
* Credit and risk classification
* EMI payment delays
* Delinquency and DPD analysis
* Collection efficiency
* Loan recovery performance
* Branch performance
* Loan product performance

The final analysis helps answer:

> **"What is the current performance and risk position of each loan product?"**

---

## 🎯 Project Objectives

The main objectives of this project are:

1. Analyze loan applications and approval status.
2. Evaluate branch-wise approval performance.
3. Classify customers based on credit score.
4. Classify loans based on sanctioned amount.
5. Analyze monthly loan application trends.
6. Measure loan processing time.
7. Analyze EMI payment delays.
8. Analyze yearly loan recovery performance.
9. Calculate customer-level loan exposure.
10. Identify high-risk and very-high-risk loan portfolios.
11. Analyze delinquency using DPD buckets.
12. Identify repeat loan applicants.
13. Calculate monthly collection efficiency.
14. Create reusable SQL views for reporting.
15. Develop PostgreSQL functions for business calculations.
16. Develop stored procedures for operational processing.
17. Generate an executive-level loan portfolio report.

---

## 🛠️ Technologies Used

| Technology          | Purpose                                  |
| ------------------- | ---------------------------------------- |
| PostgreSQL          | Database management and SQL analysis     |
| pgAdmin             | Database development and query execution |
| SQL                 | Data analysis and business logic         |
| PL/pgSQL            | Functions and stored procedures          |
| CTEs                | Complex analytical queries               |
| CASE Statements     | Business classification                  |
| JOINs               | Combining fact and dimension tables      |
| Aggregate Functions | Portfolio and performance calculations   |
| Date Functions      | Time-based analysis                      |

---

## 🗄️ Database Structure

The project follows a **fact and dimension table structure**.

### Dimension Tables

```text
dim_customer
dim_branch
dim_loan_product
dim_region
```

### Fact Tables

```text
fact_loan_application
fact_loan_account
fact_emi_payment
fact_delinquency_snapshot
fact_collection_activity
fact_recovery
```

### Simplified Data Model

```text
                 dim_customer
                      |
                      |
                      v
dim_branch ---> fact_loan_application <--- dim_loan_product
                      |
                      |
                      v
               fact_loan_account
                /      |       \
               /       |        \
              v        v         v
      fact_emi_payment  fact_delinquency_snapshot
                       |
                       v
             fact_collection_activity
                       |
                       v
                 fact_recovery

dim_region ---> dim_branch
```

---

# 📊 SQL Analysis Performed

## 1. Customer Loan Application Analysis

Used multiple JOINs to combine:

* Customer information
* Customer segment
* Loan product
* Branch
* Application date
* Requested amount
* Application status

This provides a complete view of each loan application.

---

## 2. Approved Loan Portfolio

Analyzed approved loans using:

* Customer
* Branch
* Loan product
* Requested amount
* Sanctioned amount
* Disbursement date
* Loan status

Only applications with an **Approved** status are included in the approved portfolio.

---

## 3. Branch Approval Performance

Calculated branch-level:

* Total applications
* Approved applications
* Rejected applications
* Approval rate

Branches are ranked based on approval rate.

### Approval Rate

```text
Approval Rate =
Approved Applications / Total Applications × 100
```

---

## 4. Customer Credit Rating

Used `CASE` statements to classify customers based on credit score.

| Credit Score | Rating    |
| -----------: | --------- |
|         750+ | Excellent |
|      700–749 | Good      |
|      650–699 | Average   |
|      600–649 | Poor      |
|        < 600 | Very Poor |

The analysis displays both the original credit score and calculated rating.

---

## 5. Loan Size Classification

Loans are classified according to sanctioned amount.

| Sanctioned Amount | Category   |
| ----------------: | ---------- |
|         < ₹5 Lakh | Small      |
|        ₹5–15 Lakh | Medium     |
|       ₹15–30 Lakh | Large      |
|        > ₹30 Lakh | Very Large |

This classification is implemented using SQL `CASE` logic.

---

# 📅 Date & Time Analysis

## 6. Monthly Loan Application Analysis

Monthly analysis calculates:

* Year
* Month
* Number of applications
* Total requested loan amount

The project uses PostgreSQL date functions such as:

```sql
EXTRACT()
TO_CHAR()
DATE_TRUNC()
```

---

## 7. Loan Processing Time

Processing time is calculated between:

```text
Application Date → Approval Date
```

Processing time is classified into:

|  Processing Time | Category       |
| ---------------: | -------------- |
|         ≤ 3 days | Fast           |
|         4–7 days | Normal         |
|        8–15 days | Delayed        |
|        > 15 days | Highly Delayed |
| No approval date | Pending        |

---

## 8. EMI Payment Delay Analysis

EMI payments are analyzed using:

* Due date
* Payment date
* Delay days
* Payment delay category

|     Delay | Category       |
| --------: | -------------- |
|  ≤ 0 days | On Time        |
|  1–7 days | Minor Delay    |
| 8–30 days | Moderate Delay |
| > 30 days | Severe Delay   |

---

## 9. Year-wise Recovery Analysis

Recovery performance is analyzed annually using:

* Recovery cases
* Total recovery amount
* Average recovery amount
* Settlement cases
* Written-off cases

---

# 🧩 CTE-Based Analysis

## 10. Customer Loan Exposure

A CTE is used to calculate customer-level:

* Number of loans
* Total sanctioned amount
* Total outstanding principal

Customers with outstanding principal greater than:

```text
₹10,00,000
```

are identified.

---

## 11. High-Risk Loan Portfolio

The project identifies applications classified as:

```text
High
Very High
```

The analysis then calculates by loan product:

* Number of loans
* Sanctioned amount
* Outstanding principal

---

## 12. Delinquency Analysis

A CTE is used to calculate:

* DPD bucket
* Number of loans
* Outstanding principal
* Overdue amount
* Percentage contribution to total delinquent outstanding

The analysis uses the latest delinquency information to evaluate loan risk.

### DPD Buckets

```text
0       → Current
1–30    → 1–30 DPD
31–60   → 31–60 DPD
61–90   → 61–90 DPD
90+     → 90+ DPD
```

---

## 13. Repeat Applicants

Identifies customers who have submitted more than one loan application.

The report includes:

* Customer name
* Total applications
* Approved applications
* Rejected applications
* Total requested amount

---

## 14. Monthly Collection Performance

Monthly collection performance calculates:

* Total amount demanded
* Total amount collected
* Collection efficiency %

### Collection Efficiency

```text
Collection Efficiency =
Total Amount Collected / Total Amount Demanded × 100
```

The analysis can be used to identify the month with the highest collection efficiency.

---

# 👁️ SQL Views

Reusable database views were created for reporting and analysis.

## 15. Customer Loan Summary

### View

```sql
vw_customer_loan_summary
```

Includes:

* Customer ID
* Customer name
* Customer segment
* Loan count
* Total sanctioned amount
* Total outstanding principal
* Delinquent loan count

---

## 16. Branch Loan Performance

### View

```sql
vw_branch_loan_performance
```

Includes:

* Region
* Branch
* Total applications
* Approved applications
* Rejected applications
* Approval rate
* Total sanctioned amount

---

## 17. Loan Delinquency View

### View

```sql
vw_loan_delinquency
```

Includes:

* Customer
* Loan account
* Loan product
* Outstanding principal
* DPD bucket
* Overdue amount
* Collection amount
* Recovery amount

---

## 18. Top 20 Customers by Outstanding Principal

The project performs view-based analysis using:

```sql
vw_customer_loan_summary
```

The Top 20 customers are identified based on total outstanding principal.

---

# ⚙️ PostgreSQL Functions

Three reusable PostgreSQL functions were developed.

## 19. Customer Loan Exposure Function

```sql
fn_customer_loan_exposure(customer_id)
```

Returns:

* Total loans
* Total sanctioned amount
* Total outstanding principal

---

## 20. DPD Classification Function

```sql
fn_dpd_bucket(dpd_days)
```

Converts DPD days into standardized risk buckets:

```text
Current
1–30 DPD
31–60 DPD
61–90 DPD
90+ DPD
```

---

## 21. Loan EMI Calculation Function

```sql
fn_calculate_emi(
    loan_amount,
    annual_interest_rate,
    tenure_months
)
```

The function calculates monthly EMI and validates:

* Loan amount
* Interest rate
* Loan tenure

It also handles zero-interest loans.

---

# 🔄 Stored Procedures

## 22. Update Loan DPD Procedure

```sql
sp_update_dpd_bucket()
```

Updates the DPD bucket in `fact_loan_account` using the latest available EMI payment information.

---

## 23. Process EMI Payment Procedure

```sql
sp_process_emi_payment()
```

The procedure:

1. Locates the EMI record.
2. Updates payment information.
3. Calculates delay days.
4. Determines payment status.

Parameters include:

* Loan Account ID
* Installment Number
* Payment Date
* Amount Paid
* Payment Mode

---

## 24. Record Loan Recovery Procedure

```sql
sp_record_recovery()
```

The procedure validates:

* Loan account existence
* Loan delinquency status
* Recovery amount

It prevents recovery from being recorded for a current loan and requires a positive recovery amount.

---

# 🏆 Executive Loan Portfolio Analysis

The final business challenge produces a management-level report for each loan product.

### Key Metrics

* Total Applications
* Approval Rate
* Total Loans
* Total Sanctioned Amount
* Total Outstanding Principal
* Delinquent Loans
* Delinquency Rate
* Total Recovery
* Recovery Rate

The final query uses:

* Multiple JOINs
* At least 2 CTEs
* CASE statements
* Date functions
* Aggregate functions
* Meaningful column aliases

### Final Business Question

```text
What is the current performance and risk position
of each loan product?
```

---

# 📈 Key Business KPIs

| KPI                     | Description                                    |
| ----------------------- | ---------------------------------------------- |
| Total Applications      | Total number of loan applications              |
| Approval Rate           | Percentage of applications approved            |
| Total Loans             | Number of active loan accounts                 |
| Total Sanctioned Amount | Total approved loan value                      |
| Outstanding Principal   | Remaining principal amount                     |
| Delinquent Loans        | Loans with overdue payments                    |
| Delinquency Rate        | Percentage of loans that are delinquent        |
| Total Recovery          | Total amount recovered                         |
| Recovery Rate           | Recovery amount compared with overdue amount   |
| Collection Efficiency   | Amount collected compared with amount demanded |

---

# 🔍 Business Insights Supported by the Project

This SQL project can help management identify:

* Which loan products have the highest application volume.
* Which branches have stronger approval performance.
* Which customers have high outstanding exposure.
* Which loan products carry higher risk.
* Where delinquency is concentrated.
* Which customers have repeated applications.
* How efficiently EMI collections are being performed.
* How much money is being recovered from problematic loans.
* Which loan products have high outstanding principal.
* Which products require greater risk monitoring.

---


# 🚀 How to Run the Project

## Step 1 — Install PostgreSQL

Install PostgreSQL and pgAdmin.

## Step 2 — Create Database

Create a PostgreSQL database, for example:

```sql
CREATE DATABASE banking_loan_operation_db;
```

## Step 3 — Create Tables

Create/import the required fact and dimension tables:

```text
dim_customer
dim_branch
dim_loan_product
dim_region

fact_loan_application
fact_loan_account
fact_emi_payment
fact_delinquency_snapshot
fact_collection_activity
fact_recovery
```

## Step 4 — Load Data

Load the required data into the respective tables.

## Step 5 — Execute SQL Scripts

Run the SQL scripts in the following order:

```text
1. JOINs & CASE
2. Date Functions & Analysis
3. CTE Analysis
4. Views
5. PostgreSQL Functions
6. Stored Procedures
7. Executive Loan Portfolio Report
```

## Step 6 — Analyze Results

Execute the queries and review:

* Loan portfolio
* Customer exposure
* Branch performance
* Delinquency
* Collection
* Recovery
* Risk metrics

---

# 🧠 SQL Concepts Demonstrated

This project demonstrates practical knowledge of:

```text
SELECT
WHERE
GROUP BY
HAVING
ORDER BY
INNER JOIN
LEFT JOIN
CASE
COUNT()
SUM()
AVG()
ROUND()
EXTRACT()
TO_CHAR()
DATE_TRUNC()
NULLIF()
CTE
Window Functions
Views
PL/pgSQL Functions
Stored Procedures
Conditional Logic
Data Validation
Business Rules
```

---

# 💼 Resume Description

### Banking Loan & Risk Analytics — PostgreSQL

> Developed a PostgreSQL-based Banking Loan & Risk Analytics project to analyze loan applications, approval performance, customer exposure, delinquency, EMI payment delays, collections, and recovery. Implemented complex JOINs, CASE statements, CTEs, date functions, aggregate functions, reusable SQL views, PL/pgSQL functions, and stored procedures. Created an executive-level loan portfolio analysis covering approval rate, outstanding principal, delinquency rate, recovery, and collection performance.

---

# 👨‍💻 Skills Demonstrated

**SQL | PostgreSQL | pgAdmin | Data Analysis | Banking Analytics | Risk Analytics | CTEs | JOINs | CASE Statements | Window Functions | Views | PL/pgSQL | Stored Procedures | Business KPI Analysis | Loan Portfolio Analysis | Delinquency Analysis | Recovery Analysis**

---

## ⭐ Project Highlights

* ✔️ End-to-end banking loan analytics
* ✔️ Fact and dimension table structure
* ✔️ Complex SQL JOINs
* ✔️ CTE-based business analysis
* ✔️ Customer exposure analysis
* ✔️ Credit and risk classification
* ✔️ DPD and delinquency analysis
* ✔️ Collection and recovery analysis
* ✔️ Reusable SQL views
* ✔️ PostgreSQL functions
* ✔️ Stored procedures
* ✔️ Executive-level portfolio reporting
* ✔️ Business-focused SQL KPIs
