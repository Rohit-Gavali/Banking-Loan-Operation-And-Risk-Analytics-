--DATABASE CREATE

CREATE DATABASE banking_loan_operations;

-- DIMENSION TABLE
--1.dim_region
--=================================
CREATE TABLE dim_region (
    region_id INT PRIMARY KEY,
    country_name VARCHAR(50) NOT NULL,
    state_name VARCHAR(50),
    city_name VARCHAR(50),
    region_zone VARCHAR(30) NOT NULL
);

--=================================

--2.dim_branch
--=================================
CREATE TABLE dim_branch (
    branch_id BIGINT PRIMARY KEY,
    branch_code VARCHAR(20) NOT NULL UNIQUE,
    branch_name VARCHAR(100) NOT NULL,
    region_id INT,
    branch_type VARCHAR(30) NOT NULL,
    opening_date DATE,
    CONSTRAINT fk_branch_region
        FOREIGN KEY(region_id)
        REFERENCES dim_region(region_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
);
--=================================
--3.dim_customer
--=================================

CREATE TABLE dim_customer (
    customer_id BIGINT PRIMARY KEY,
    customer_code VARCHAR(20) UNIQUE NOT NULL,
    customer_name VARCHAR(100),
    gender VARCHAR(10) NOT NULL
        CHECK (gender IN ('Male','Female')),
    date_of_birth DATE NOT NULL,
    employment_type VARCHAR(50),
    annual_income NUMERIC(15,2)
        CHECK (annual_income>=0),
    credit_score INT NOT NULL,
    marital_status VARCHAR(20),
    city_name VARCHAR(50),
    customer_segment VARCHAR(30) DEFAULT 'Retail'
);

--=================================
--4.dim_collection_agent
--=================================
CREATE TABLE dim_collection_agent (
    agent_id INT PRIMARY KEY,
    agent_code VARCHAR(20) UNIQUE NOT NULL,
    agent_name VARCHAR(100) NOT NULL,
    agent_region VARCHAR(50),
    experience_level VARCHAR(20),
    active_flag BOOLEAN
);
--=================================
--5.dim_calendar
--=================================
CREATE TABLE dim_calendar (
    calendar_date DATE PRIMARY KEY,
    year INT NOT NULL,
    quarter INT CHECK (quarter BETWEEN 1 AND 4),
    month_no INT CHECK (month_no BETWEEN 1 AND 12),
    month_name VARCHAR(20),
    week_no INT,
    day_name VARCHAR(20),
    is_weekend BOOLEAN DEFAULT FALSE
);
--=================================
--6.dim_loan_product
--=================================
CREATE TABLE dim_loan_product (
    loan_product_id INT PRIMARY KEY,
    loan_product_code VARCHAR(20) UNIQUE NOT NULL,
    loan_product_name VARCHAR(100),
    secured_flag BOOLEAN,
    interest_rate NUMERIC(5,2)
        CHECK (interest_rate>=0),
    max_tenure_months INT
        CHECK (max_tenure_months>0)
);
--=================================
--FACT TABLE
--1.fact_loan_application
--=================================
CREATE TABLE fact_loan_application (
    loan_application_id BIGINT PRIMARY KEY,
    customer_id BIGINT NOT NULL,
    branch_id INT NOT NULL,
    loan_product_id INT NOT NULL,
    application_date DATE,
    requested_loan_amount NUMERIC(15,2),
    requested_tenure_months INT CHECK(requested_tenure_months>0),
    application_status VARCHAR(30) DEFAULT 'Pending',
    risk_category VARCHAR(20),
    approval_date DATE,
    rejection_reason TEXT,
    CONSTRAINT fk_application_customer
        FOREIGN KEY(customer_id)
        REFERENCES dim_customer(customer_id),
    CONSTRAINT fk_application_branch
        FOREIGN KEY(branch_id)
        REFERENCES dim_branch(branch_id),
    CONSTRAINT fk_application_product
        FOREIGN KEY(loan_product_id)
        REFERENCES dim_loan_product(loan_product_id)
);
--=================================
--2.fact_loan_account
--=================================
CREATE TABLE fact_loan_account (
    loan_account_id BIGINT PRIMARY KEY,
    loan_application_id INT NOT NULL,
    loan_account_number VARCHAR(30) UNIQUE,
    disbursement_date DATE NOT NULL,
    sanctioned_amount NUMERIC(15,2) CHECK(sanctioned_amount>0),
    emi_amount NUMERIC(15,2) CHECK(emi_amount>0),
    outstanding_principal NUMERIC(15,2),
    loan_status VARCHAR(20),
    dpd_bucket VARCHAR(20),
    closure_date DATE,
    CONSTRAINT fk_account_application
        FOREIGN KEY(loan_application_id)
        REFERENCES fact_loan_application(loan_application_id)
);
--=================================
--3.fact_emi_payment
--=================================
CREATE TABLE fact_emi_payment (
    emi_payment_id BIGINT PRIMARY KEY,
    loan_account_id INT NOT NULL,
    installment_number INT,
    due_date DATE,
    payment_date DATE,
    emi_amount NUMERIC(15,2),
    amount_paid NUMERIC(15,2) DEFAULT 0,
    payment_status VARCHAR(20),
    delay_days INT DEFAULT 0,
    payment_mode VARCHAR(30),
    CONSTRAINT fk_emi_account
        FOREIGN KEY(loan_account_id)
        REFERENCES fact_loan_account(loan_account_id)
);
--=================================
--4.fact_collection_activity
--=================================
CREATE TABLE fact_collection_activity (
    collection_activity_id INT PRIMARY KEY,
    loan_account_id INT NOT NULL,
    agent_id INT NOT NULL,
    activity_date DATE NOT NULL,
    contact_mode VARCHAR(30),
    amount_demanded NUMERIC(15,2),
    amount_collected NUMERIC(15,2) DEFAULT 0,
    promise_date DATE,
    next_followup_date DATE,
    collection_status VARCHAR(30),
    remarks TEXT,
    CONSTRAINT fk_collection_account
        FOREIGN KEY(loan_account_id)
        REFERENCES fact_loan_account(loan_account_id),
    CONSTRAINT fk_collection_agent
        FOREIGN KEY(agent_id)
        REFERENCES dim_collection_agent(agent_id)
);
--=================================
--5.fact_delinquency_snapshot
--=================================
CREATE TABLE fact_delinquency_snapshot (
    delinquency_id INT PRIMARY KEY,
    loan_account_id INT NOT NULL,
    snapshot_date DATE NOT NULL,
    dpd_days INT DEFAULT 0,
    dpd_bucket VARCHAR(20),
    overdue_amount NUMERIC(15,2) DEFAULT 0,
    delinquency_flag BOOLEAN,
    CONSTRAINT fk_delinquency_account
        FOREIGN KEY(loan_account_id)
        REFERENCES fact_loan_account(loan_account_id),
    CONSTRAINT fk_snapshot_calendar
        FOREIGN KEY(snapshot_date)
        REFERENCES dim_calendar(calendar_date)
);
--=================================
--6.fact_recovery
--=================================
CREATE TABLE fact_recovery (
    recovery_id INT PRIMARY KEY,
    loan_account_id INT NOT NULL,
    agent_id INT NOT NULL,
    recovery_date DATE,
    recovery_amount NUMERIC(15,2) CHECK(recovery_amount>=0),
    recovery_type VARCHAR(30),
    settlement_flag BOOLEAN,
    written_off_flag BOOLEAN,
    remarks TEXT,
    CONSTRAINT fk_recovery_account
        FOREIGN KEY(loan_account_id)
        REFERENCES fact_loan_account(loan_account_id),
    CONSTRAINT fk_recovery_agent
        FOREIGN KEY(agent_id)
        REFERENCES dim_collection_agent(agent_id)
);