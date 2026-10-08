SET search_path TO banking_loan_ops;
-- Q1. Customer Loan Application Report
-- Using appropriate JOINs, display:
-- - Customer Name
-- - Customer Segment
-- - Loan Product
-- - Branch Name
-- - Application Date
-- - Requested Loan Amount
-- - Application Status
--===============================================================================
SELECT c.customer_name,c.customer_segment,
lp.loan_product_name,b.branch_name,
la.application_date,la.requested_loan_amount,la.application_status
FROM fact_loan_application la
INNER JOIN dim_customer c ON la.customer_id = c.customer_id
INNER JOIN dim_branch b ON la.branch_id = b.branch_id
INNER JOIN dim_loan_product lp ON la.loan_product_id = lp.loan_product_id;

--===============================================================================
--  Q2. Approved Loan Portfolio
-- Display all approved loans with:
-- - Customer Name
-- - Branch
-- - Loan Product
-- - Requested Amount
-- - Sanctioned Amount
-- - Disbursement Date
-- - Loan Status

SELECT c.customer_name,
b.branch_name,
lp.loan_product_name,
la.requested_loan_amount,application_status,
lac.sanctioned_amount,lac.disbursement_date,lac.loan_status
FROM fact_loan_application la
INNER JOIN dim_customer c ON la.customer_id = c.customer_id
INNER JOIN dim_branch b ON la.branch_id = b.branch_id
INNER JOIN dim_loan_product lp ON la.loan_product_id = lp.loan_product_id
INNER JOIN fact_loan_account lac ON la.loan_application_id = lac.loan_application_id
WHERE la.application_status = 'Approved';
--===============================================================================
--  Q3. Branch Approval Performance

-- For every branch calculate:
-- - Total Applications
-- - Approved Applications
-- - Rejected Applications
-- - Approval Rate %
-- Sort branches by Approval Rate descending.
-- - Total Applications


-- - Total Applications
SELECT b.branch_name,COUNT(la.loan_application_id) AS total_application
from fact_loan_application la
left join dim_branch b ON la.branch_id = b.branch_id
group by b.branch_name
order by total_application DESC;

-- - Approved Applications
SELECT b.branch_name,COUNT(la.application_status) AS approved_application
from fact_loan_application la
left join dim_branch b ON la.branch_id = b.branch_id
where application_status='Approved'
group by b.branch_name
order by approved_application DESC;

-- - Rejected Applications
SELECT b.branch_name,COUNT(la.application_status) AS rejected_application
from fact_loan_application la
left join dim_branch b ON la.branch_id = b.branch_id
where application_status='Rejected'
group by b.branch_name
order by rejected_application DESC;

-- - Approval Rate %
-- Sort branches by Approval Rate descending.
SELECT b.branch_name,ROUND(
        (
            SELECT COUNT(*)
            FROM fact_loan_application la
            WHERE la.branch_id = b.branch_id
              AND la.application_status = 'Approved'
        ) * 100.0 / COUNT(la.loan_application_id),
        2
    ) AS approval_rate
FROM dim_branch b
LEFT JOIN fact_loan_application la ON b.branch_id = la.branch_id
GROUP BY b.branch_name,b.branch_id
ORDER BY approval_rate DESC;
--===============================================================================
-- ### Q4. Customer Credit Rating

-- Using `CASE`, classify customers based on `credit_score`:

-- | Credit Score | Rating |
-- | --- | --- |
-- | 750+ | Excellent |
-- | 700–749 | Good |
-- | 650–699 | Average |
-- | 600–649 | Poor |
-- | < 600 | Very Poor |

-- Display the original credit score and calculated rating.
SELECT customer_name,credit_score,
		(CASE
		WHEN credit_score<600 THEN 'Very Poor'
		WHEN credit_score>600 AND credit_score<649 THEN 'Poor'
		WHEN credit_score>650 AND credit_score<699 THEN 'Average'
		WHEN credit_score>700 AND credit_score<749 THEN 'Good'
		WHEN credit_score>750 THEN 'Excellent'
		END) AS Rating
FROM dim_customer;
		
--===============================================================================
-- ### Q5. Loan Size Classification

-- Using `CASE`, classify loans based on `sanctioned_amount`:

-- | Amount | Category |
-- | --- | --- |
-- | < ₹5 Lakh | Small |
-- | ₹5–15 Lakh | Medium |
-- | ₹15–30 Lakh | Large |
-- | > ₹30 Lakh | Very Large |

-- Display:

-- - Loan Account
-- - Customer
-- - Loan Product
-- - Sanctioned Amount
-- - Loan Category

SELECT lac.loan_account_id,c.customer_name,p.loan_product_name,lac.sanctioned_amount,
	(CASE 
	WHEN lac.sanctioned_amount<500000 THEN 'Small'
	WHEN lac.sanctioned_amount>500000 AND lac.sanctioned_amount<1500000  THEN 'Medium'
	WHEN lac.sanctioned_amount>1500000 AND lac.sanctioned_amount<3000000  THEN 'Large'
	WHEN lac.sanctioned_amount>300000 THEN 'Very Large'
	END) as loan_Category
from fact_loan_application la
inner join dim_customer c on c.customer_id =la.customer_id
inner join dim_loan_product p on p.loan_product_id =la.loan_product_id
inner join fact_loan_account lac on lac.loan_application_id =la.loan_application_id
order by sanctioned_amount asc;


select sanctioned_amount
from fact_loan_account;
--===============================================================================

-- ### Q6. Monthly Application Analysis

-- Using `TO_CHAR()`, `EXTRACT()` or `DATE_TRUNC()`, calculate monthly:

-- - Year
-- - Month
-- - Number of Applications
-- - Total Requested Amount

SELECT 
EXTRACT(YEAR FROM application_date) AS Year,
TO_CHAR(application_date,'MM') AS Month,
COUNT(loan_application_id) AS Total_Application,
SUM(requested_loan_amount) AS Total_Requested_Amount
FROM fact_loan_application
GROUP BY Year,Month
ORDER BY Year desc,Month desc;

select application_date
from fact_loan_application;
--===============================================================================
-- ### Q7. Loan Processing Time

-- Calculate the number of days between:

-- `application_date → approval_date`

-- Classify processing time using `CASE`:

-- - ≤ 3 days → Fast
-- - 4–7 days → Normal
-- - 8–15 days → Delayed
-- - 15 days → Highly Delayed

select loan_application_id ,application_date,
approval_date ,
nullif(approval_date - application_date,0) AS Processing_day,
(CASE
	 WHEN approval_date IS NULL THEN 'Pending'
	 WHEN approval_date - application_date BETWEEN 0 AND 3 THEN 'Fast'
	 WHEN approval_date - application_date BETWEEN 4 AND 7 THEN 'Normal'
	 WHEN approval_date - application_date BETWEEN 8 AND 15 THEN 'Delay'
	 ELSE 'Highly Delayed'
	 END) AS Prcessing_Catogary
from fact_loan_application
order by application_date desc ;


select application_date,approval_date
from fact_loan_application;
select *
from fact_loan_application
where approval_date IS NULL;
--===============================================================================
-- ### Q8. EMI Payment Delay Analysis

-- Using `due_date` and `payment_date`, classify EMI payments as:

-- - On Time
-- - Minor Delay
-- - Moderate Delay
-- - Severe Delay

-- Also display the calculated delay days.
SELECT
    loan_account_id,
    installment_number,
    due_date,
    payment_date,

    -- Calculate delay days
    CASE
        WHEN payment_date > due_date
        THEN payment_date - due_date
        ELSE 0
    END AS delay_days,

    -- Classify payment delay
    CASE
        WHEN payment_date <= due_date
            THEN 'On Time'

        WHEN payment_date - due_date BETWEEN 1 AND 7
            THEN 'Minor Delay'

        WHEN payment_date - due_date BETWEEN 8 AND 30
            THEN 'Moderate Delay'

        WHEN payment_date - due_date > 30
            THEN 'Severe Delay'

        ELSE 'Unknown'
    END AS payment_delay_category

FROM fact_emi_payment
ORDER BY due_date;

--===============================================================================
-- ### Q9. Year-wise Recovery Analysis

-- Calculate for every year:

-- - Recovery Cases
-- - Total Recovery Amount
-- - Average Recovery Amount
-- - Settlement Cases
-- - Written-off Cases

SELECT EXTRACT(YEAR FROM recovery_date) AS Year, COUNT(recovery_id) AS Recovery_Cases,
SUM(recovery_amount) AS Total_Recovery_Amount,round(AVG(recovery_amount),2)AS Average_Recovery_Amount ,
count(CASE 
	 WHEN settlement_flag='true' THEN settlement_flag
	END) AS settlement_case ,
count(CASE 
	 WHEN written_off_flag='true' THEN written_off_flag
	END) AS written_off_case 
from fact_recovery
GROUP BY Year
order by year desc;

--===============================================================================
-- ### Q10. Customer Loan Exposure

-- Create a CTE that calculates for every customer:

-- - Number of Loans
-- - Total Sanctioned Amount
-- - Total Outstanding Principal

-- Return customers whose **outstanding principal > ₹10 Lakh**.

WITH customer_exposure AS (
    SELECT
        la.customer_id,
        COUNT(loa.loan_account_id) AS number_of_loans,
        SUM(loa.sanctioned_amount) AS total_sanctioned_amount,
        SUM(loa.outstanding_principal) AS total_outstanding_principal
    FROM fact_loan_application la
    INNER JOIN fact_loan_account loa
        ON la.loan_application_id = loa.loan_application_id
    GROUP BY la.customer_id
)
SELECT
    c.customer_name,
    ce.number_of_loans,
    ce.total_sanctioned_amount,
    ce.total_outstanding_principal
FROM customer_exposure ce
INNER JOIN dim_customer c
    ON ce.customer_id = c.customer_id
WHERE ce.total_outstanding_principal > 1000000
order by ce.total_outstanding_principal asc;
--===============================================================================
-- ### Q11. High-Risk Loan Portfolio

-- Using a CTE:

-- 1. Identify High and Very High risk applications.
-- 2. Join them with loan accounts.
-- 3. Calculate:
--     - Number of Loans
--     - Sanctioned Amount
--     - Outstanding Principal

-- Show the results by **Loan Product**.

select application_status,risk_category from fact_loan_application;

WITH high_risk_applications AS (
    SELECT
        loan_application_id,
        loan_product_id,
		risk_category
    FROM fact_loan_application
    WHERE risk_category IN ('High', 'Very High')
)

SELECT
    lp.loan_product_name,
    COUNT(la.loan_account_id) AS number_of_loans,
    SUM(la.sanctioned_amount) AS sanctioned_amount,
    SUM(la.outstanding_principal) AS outstanding_principal,
	hra.risk_category
FROM high_risk_applications hra

INNER JOIN fact_loan_account la
    ON hra.loan_application_id = la.loan_application_id

INNER JOIN dim_loan_product lp
    ON hra.loan_product_id = lp.loan_product_id

GROUP BY
    lp.loan_product_id,
    lp.loan_product_name,
	hra.risk_category

ORDER BY
    outstanding_principal DESC;
	
--===============================================================================
-- ### Q12. Delinquency Analysis

-- Create a CTE to calculate:

-- - DPD Bucket
-- - Number of Loans
-- - Outstanding Principal
-- - Overdue Amount

-- Also calculate each bucket's **percentage contribution to total delinquent outstanding**.
select dpd_bucket from fact_loan_account;


WITH delinquency_data AS (
    SELECT
        lac.dpd_bucket,
        COUNT(DISTINCT lac.loan_account_id) AS number_of_loans,
        SUM(lac.outstanding_principal) AS outstanding_principal,
        SUM(ds.overdue_amount) AS overdue_amount
    FROM fact_loan_account lac
		INNER JOIN fact_delinquency_snapshot ds
		ON lac.loan_account_id = ds.loan_account_id
    GROUP BY lac.dpd_bucket
)

SELECT
    dpd_bucket,
    number_of_loans,
    outstanding_principal,
    overdue_amount,
    ROUND(
        outstanding_principal * 100.0 /
        NULLIF(SUM(outstanding_principal) OVER (), 0),
        2
    ) AS percentage_contribution
FROM delinquency_data
ORDER BY outstanding_principal DESC;

--===============================================================================

-- ### Q13. Repeat Applicants

-- Using a CTE, identify customers who have submitted **more than one loan application**.

-- Display:

-- - Customer Name
-- - Total Applications
-- - Approved Applications
-- - Rejected Applications
-- - Total Requested Amount

WITH repeat_applicants AS (
    SELECT
        customer_id,
        COUNT(loan_application_id) AS total_applications,
        COUNT(CASE
            WHEN application_status = 'Approved'
            THEN loan_application_id
        END) AS approved_applications,
        COUNT(CASE
            WHEN application_status = 'Rejected'
            THEN loan_application_id
        END) AS rejected_applications,
        SUM(requested_loan_amount) AS total_requested_amount
    FROM fact_loan_application
    GROUP BY customer_id
    HAVING COUNT(loan_application_id) > 1
)

SELECT
    c.customer_name,
    ra.total_applications,
    ra.approved_applications,
    ra.rejected_applications,
    ra.total_requested_amount
FROM repeat_applicants ra
INNER JOIN dim_customer c
    ON ra.customer_id = c.customer_id
ORDER BY ra.total_applications DESC;

--===============================================================================
-- ### Q14. Monthly Collection Performance

-- Using a CTE, calculate monthly:

-- - Total Amount Demanded
-- - Total Amount Collected
-- - Collection Efficiency %

-- Identify the month with the **highest collection efficiency**.

WITH monthly_collection AS (
    SELECT
	    EXTRACT(YEAR FROM activity_date) AS Year,
	    EXTRACT(MONTH FROM activity_date) AS Month,
        SUM(amount_demanded) AS total_amount_demanded,
        SUM(amount_collected) AS total_amount_collected
    FROM fact_collection_activity
    GROUP BY Year,Month
)

SELECT
	Year,
    month,
    total_amount_demanded,
    total_amount_collected,
    ROUND(
        total_amount_collected * 100.0 /
        NULLIF(total_amount_demanded, 0),
        2
    ) AS collection_efficiency
FROM monthly_collection
ORDER BY Year desc,Month asc;

--===============================================================================
-- Q15. Customer Loan Summary View
-- Create a view:
-- vw_customer_loan_summary
-- It should contain:
-- Customer ID
-- Customer Name
-- Customer Segment
-- Loan Count
-- Total Sanctioned Amount
-- Total Outstanding Principal
-- Delinquent Loan Count

CREATE OR REPLACE VIEW vw_customer_loan_summary AS

WITH loan_summary AS (
    SELECT
        la.customer_id,
        COUNT(DISTINCT loa.loan_account_id) AS loan_count,
        SUM(loa.sanctioned_amount) AS total_sanctioned_amount,
        SUM(loa.outstanding_principal) AS total_outstanding_principal
    FROM fact_loan_application la
    INNER JOIN fact_loan_account loa
        ON la.loan_application_id = loa.loan_application_id
    GROUP BY la.customer_id
),

delinquency_summary AS (
    SELECT
        la.customer_id,
        COUNT(DISTINCT ds.loan_account_id) AS delinquent_loan_count
    FROM fact_loan_application la
    INNER JOIN fact_loan_account loa
        ON la.loan_application_id = loa.loan_application_id
    INNER JOIN fact_delinquency_snapshot ds
        ON loa.loan_account_id = ds.loan_account_id
    WHERE ds.dpd_days > 0
    GROUP BY la.customer_id
)

SELECT
    c.customer_id,
    c.customer_name,
    c.customer_segment,
    ls.loan_count,
    ls.total_sanctioned_amount,
    ls.total_outstanding_principal,
    COALESCE(ds.delinquent_loan_count, 0) AS delinquent_loan_count

FROM dim_customer c

INNER JOIN loan_summary ls
    ON c.customer_id = ls.customer_id

LEFT JOIN delinquency_summary ds
    ON c.customer_id = ds.customer_id;

SELECT *
FROM vw_customer_loan_summary;

--===============================================================================
-- ### Q16. Branch Performance View

-- Create:

-- `vw_branch_loan_performance`

-- Include:

-- - Region
-- - Branch
-- - Total Applications
-- - Approved Applications
-- - Rejected Applications
-- - Approval Rate
-- - Total Sanctioned Amount

CREATE OR REPLACE VIEW vw_branch_loan_performance AS

WITH application_summary AS (
    SELECT
        branch_id,
        COUNT(loan_application_id) AS total_applications,

        COUNT(
            CASE
                WHEN application_status = 'Approved'
                THEN loan_application_id
            END
        ) AS approved_applications,

        COUNT(
            CASE
                WHEN application_status = 'Rejected'
                THEN loan_application_id
            END
        ) AS rejected_applications
    FROM fact_loan_application
    GROUP BY branch_id
),

sanction_summary AS (
    SELECT
        la.branch_id,
        SUM(loa.sanctioned_amount) AS total_sanctioned_amount
    FROM fact_loan_application la
    INNER JOIN fact_loan_account loa
        ON la.loan_application_id = loa.loan_application_id
    GROUP BY la.branch_id
)

SELECT
   
    b.branch_name AS branch,

    COALESCE(a.total_applications, 0) AS total_applications,

    COALESCE(a.approved_applications, 0) AS approved_applications,

    COALESCE(a.rejected_applications, 0) AS rejected_applications,

    ROUND(
        COALESCE(a.approved_applications, 0) * 100.0
        / NULLIF(COALESCE(a.total_applications, 0), 0),
        2
    ) AS approval_rate,

    COALESCE(s.total_sanctioned_amount, 0) AS total_sanctioned_amount

FROM dim_region r

INNER JOIN dim_branch b
    ON r.region_id = b.region_id

LEFT JOIN application_summary a
    ON b.branch_id = a.branch_id

LEFT JOIN sanction_summary s
    ON b.branch_id = s.branch_id;

SELECT *
FROM vw_branch_loan_performance;

--===============================================================================
-- ### Q17. Loan Delinquency View

-- Create:

-- `vw_loan_delinquency`

-- Include:

-- - Customer
-- - Loan Account
-- - Loan Product
-- - Outstanding Principal
-- - DPD Bucket
-- - Overdue Amount
-- - Collection Amount
-- - Recovery Amount

CREATE OR REPLACE VIEW vw_loan_delinquency AS

WITH delinquency_data AS (
    SELECT DISTINCT ON (loan_account_id)
        loan_account_id,
        dpd_bucket,
        overdue_amount
    FROM fact_delinquency_snapshot
    ORDER BY loan_account_id, snapshot_date DESC
),

collection_data AS (
    SELECT
        loan_account_id,
        SUM(amount_collected) AS collection_amount
    FROM fact_collection_activity
    GROUP BY loan_account_id
),

recovery_data AS (
    SELECT
        loan_account_id,
        SUM(recovery_amount) AS recovery_amount
    FROM fact_recovery
    GROUP BY loan_account_id
)

SELECT
    c.customer_name AS customer,
    loa.loan_account_number AS loan_account,
    lp.loan_product_name AS loan_product,
    loa.outstanding_principal,
    dd.dpd_bucket,
    dd.overdue_amount,
    COALESCE(cd.collection_amount, 0) AS collection_amount,
    COALESCE(rd.recovery_amount, 0) AS recovery_amount

FROM fact_loan_account loa

INNER JOIN fact_loan_application la
    ON loa.loan_application_id = la.loan_application_id

INNER JOIN dim_customer c
    ON la.customer_id = c.customer_id

INNER JOIN dim_loan_product lp
    ON la.loan_product_id = lp.loan_product_id

LEFT JOIN delinquency_data dd
    ON loa.loan_account_id = dd.loan_account_id

LEFT JOIN collection_data cd
    ON loa.loan_account_id = cd.loan_account_id

LEFT JOIN recovery_data rd
    ON loa.loan_account_id = rd.loan_account_id;

SELECT *
FROM vw_loan_delinquency;

--===============================================================================

-- ### Q18. View-Based Analysis

-- Using `vw_customer_loan_summary`, find the **Top 20 customers by outstanding principal**.

-- > Do not directly query the underlying tables for this question.
-- >

SELECT
    customer_id,
    customer_name,
    customer_segment,
    loan_count,
    total_sanctioned_amount,
    total_outstanding_principal,
    delinquent_loan_count
FROM vw_customer_loan_summary
ORDER BY total_outstanding_principal DESC
LIMIT 20;

--===============================================================================

-- ### Q19. Customer Loan Exposure Function

-- Create:

-- `fn_customer_loan_exposure(customer_id)`

-- The function should return:

-- - Total Loans
-- - Total Sanctioned Amount
-- - Total Outstanding Principal

-- Test the function for at least **5 customers**.

CREATE OR REPLACE FUNCTION fn_customer_loan_exposure(
    p_customer_id INT
)
RETURNS TABLE (
    total_loans BIGINT,
    total_sanctioned_amount NUMERIC,
    total_outstanding_principal NUMERIC
)
LANGUAGE plpgsql
AS $$
BEGIN

    RETURN QUERY
    SELECT
        COUNT(loa.loan_account_id),
        COALESCE(SUM(loa.sanctioned_amount), 0),
        COALESCE(SUM(loa.outstanding_principal), 0)

    FROM fact_loan_application la

    INNER JOIN fact_loan_account loa
        ON la.loan_application_id = loa.loan_application_id

    WHERE la.customer_id = p_customer_id;

END;
$$;

SELECT *
FROM fn_customer_loan_exposure(1);

--===============================================================================

-- ### Q20. DPD Classification Function

-- Create:

-- `fn_dpd_bucket(dpd_days)`

-- The function should return:

-- | DPD | Bucket |
-- | --- | --- |
-- | 0 | Current |
-- | 1–30 | 1–30 DPD |
-- | 31–60 | 31–60 DPD |
-- | 61–90 | 61–90 DPD |
-- | 90+ | 90+ DPD |

-- Test it with different DPD values.

CREATE OR REPLACE FUNCTION fn_dpd_bucket(dpd_days INT)
RETURNS VARCHAR
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN CASE
        WHEN dpd_days = 0 THEN 'Current'
        WHEN dpd_days BETWEEN 1 AND 30 THEN '1–30 DPD'
        WHEN dpd_days BETWEEN 31 AND 60 THEN '31–60 DPD'
        WHEN dpd_days BETWEEN 61 AND 90 THEN '61–90 DPD'
        WHEN dpd_days > 90 THEN '90+ DPD'
        ELSE 'Invalid DPD'
    END;
END;
$$;

SELECT fn_dpd_bucket(0);

--===============================================================================
-- ### Q21. Loan EMI Function

-- Create:

-- `fn_calculate_emi(loan_amount, annual_interest_rate, tenure_months)`

-- The function should calculate and return the **monthly EMI**.

-- Test it using at least **3 different loan scenarios**.

-- Q21. Loan EMI Function

CREATE OR REPLACE FUNCTION fn_calculate_emi(
    loan_amount NUMERIC,
    annual_interest_rate NUMERIC,
    tenure_months INTEGER
)
RETURNS NUMERIC
LANGUAGE plpgsql
AS $$
DECLARE
    monthly_rate NUMERIC;
    emi NUMERIC;
BEGIN
    -- Validation
    IF loan_amount <= 0 THEN
        RAISE EXCEPTION 'Loan amount must be greater than 0';
    END IF;

    IF annual_interest_rate < 0 THEN
        RAISE EXCEPTION 'Interest rate cannot be negative';
    END IF;

    IF tenure_months <= 0 THEN
        RAISE EXCEPTION 'Tenure must be greater than 0';
    END IF;

    -- Convert annual interest rate to monthly rate
    monthly_rate := annual_interest_rate / 12 / 100;

    -- EMI calculation
    IF monthly_rate = 0 THEN
        emi := loan_amount / tenure_months;
    ELSE
        emi := (
            loan_amount
            * monthly_rate
            * POWER(1 + monthly_rate, tenure_months)
        )
        / (
            POWER(1 + monthly_rate, tenure_months) - 1
        );
    END IF;

    RETURN ROUND(emi, 2);
END;
$$;

SELECT fn_calculate_emi(1000000, 9.5, 120) AS monthly_emi;

--===============================================================================

-- ### Q22. Update Loan DPD Procedure

-- Create:

-- `sp_update_dpd_bucket()`

-- The procedure should update `fact_loan_account.dpd_bucket` based on the latest available delinquency information.

CREATE OR REPLACE PROCEDURE sp_update_dpd_bucket()
LANGUAGE plpgsql
AS $$
BEGIN

    UPDATE fact_loan_account fla
    SET dpd_bucket =
        CASE
            WHEN emi.dpd_days = 0
                THEN 'Current'

            WHEN emi.dpd_days BETWEEN 1 AND 30
                THEN '1-30 DPD'

            WHEN emi.dpd_days BETWEEN 31 AND 60
                THEN '31-60 DPD'

            WHEN emi.dpd_days BETWEEN 61 AND 90
                THEN '61-90 DPD'

            WHEN emi.dpd_days > 90
                THEN '90+ DPD'

            ELSE 'Unknown'
        END

    FROM
    (
        SELECT
            loan_account_id,
            CASE
                WHEN payment_date > due_date
                    THEN payment_date - due_date
                ELSE 0
            END AS dpd_days
        FROM fact_emi_payment
    ) emi

    WHERE fla.loan_account_id = emi.loan_account_id;

END;
$$;

CALL sp_update_dpd_bucket();

select * from fact_loan_account;

--===============================================================================
-- ### Q23. Process EMI Payment Procedure

-- Create:

-- `sp_process_emi_payment()`

-- Parameters should include:

-- - Loan Account ID
-- - Installment Number
-- - Payment Date
-- - Amount Paid
-- - Payment Mode

-- The procedure should:

-- 1. Locate the EMI record.
-- 2. Update payment information.
-- 3. Calculate delay days.
-- 4. Determine payment status using `CASE`.

CREATE OR REPLACE PROCEDURE sp_process_emi_payment(
    p_loan_account_id INT,
    p_installment_number INT,
    p_payment_date DATE,
    p_amount_paid NUMERIC(15,2),
    p_payment_mode VARCHAR(50)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_due_date DATE;
BEGIN

    -- 1. Locate the EMI record
    SELECT due_date
    INTO v_due_date
    FROM fact_emi_payment
    WHERE loan_account_id = p_loan_account_id
      AND installment_number = p_installment_number;

    -- Check whether EMI exists
    IF NOT FOUND THEN
        RAISE EXCEPTION 
        'EMI record not found for Loan Account ID % and Installment %',
        p_loan_account_id, p_installment_number;
    END IF;

    -- 2, 3 & 4. Update payment information,
    -- calculate delay days and determine payment status
    UPDATE fact_emi_payment
    SET 
        payment_date = p_payment_date,
        amount_paid = p_amount_paid,
        payment_mode = p_payment_mode,

        delay_days =
            CASE
                WHEN p_payment_date > v_due_date
                THEN p_payment_date - v_due_date
                ELSE 0
            END,

        payment_status =
            CASE
                WHEN p_payment_date <= v_due_date
                    THEN 'On Time'
                WHEN p_payment_date > v_due_date
                     AND p_payment_date <= v_due_date + 30
                    THEN 'Late'
                WHEN p_payment_date > v_due_date + 30
                    THEN 'Severely Late'
                ELSE 'Unknown'
            END

    WHERE loan_account_id = p_loan_account_id
      AND installment_number = p_installment_number;

END;
$$;

CALL sp_process_emi_payment(
    1001,
    3,
    '2026-08-20',
    12500.00,
    'UPI'
);

--===============================================================================

-- ### Q24. Record Loan Recovery Procedure

-- Create:

-- `sp_record_recovery()`

-- Parameters:

-- - Loan Account ID
-- - Agent ID
-- - Recovery Date
-- - Recovery Amount
-- - Recovery Type

-- The procedure should validate that the loan is **delinquent/problematic** before inserting the recovery record.

CREATE OR REPLACE PROCEDURE sp_record_recovery(
    p_loan_account_id INT,
    p_agent_id INT,
    p_recovery_date DATE,
    p_recovery_amount NUMERIC,
    p_recovery_type VARCHAR
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_dpd_days INT;
BEGIN

    -- Get latest DPD
    SELECT dpd_days
    INTO v_dpd_days
    FROM fact_delinquency_snapshot
    WHERE loan_account_id = p_loan_account_id
    ORDER BY snapshot_date DESC
    LIMIT 1;

    -- Check whether loan is delinquent
    IF v_dpd_days <= 0 OR v_dpd_days IS NULL THEN
        RAISE EXCEPTION
        'Recovery cannot be recorded. Loan Account ID % is Current.',
        p_loan_account_id;
    END IF;

    -- Insert recovery
    INSERT INTO fact_recovery (
        loan_account_id,
        agent_id,
        recovery_date,
        recovery_amount,
        recovery_type
    )
    VALUES (
        p_loan_account_id,
        p_agent_id,
        p_recovery_date,
        p_recovery_amount,
        p_recovery_type
    );

END;
$$;

CALL sp_record_recovery(
    1302,
    25,
    '2026-08-21',
    15000.00,
    'Cash'
);

SELECT
    loan_account_id,
    snapshot_date,
    dpd_days,
    dpd_bucket
FROM fact_delinquency_snapshot
ORDER BY snapshot_date DESC
LIMIT 1;
--===============================================================================

-- ### Q25. Executive Loan Portfolio Report 

-- Create one final management-level SQL report containing:

-- - Loan Product
-- - Total Applications
-- - Approval Rate
-- - Total Loans
-- - Total Sanctioned Amount
-- - Total Outstanding Principal
-- - Delinquent Loans
-- - Delinquency Rate
-- - Total Recovery
-- - Recovery Rate

-- ### Requirements

-- Your solution **must use**:

-- -  Multiple JOINs
-- -  At least 2 CTEs
-- -  `CASE`
-- -  Date functions
-- -  Aggregate functions
-- -  Meaningful column aliases

-- ### Expected Outcome

-- The final query should answer:

-- > **"What is the current performance and risk position of each loan product?"

WITH application_summary AS (
    SELECT
        loan_product_id,

        COUNT(loan_application_id) AS total_applications,

        ROUND(
            100.0 *
            COUNT(
                CASE
                    WHEN application_status = 'Approved'
                    THEN 1
                END
            )
            / NULLIF(COUNT(loan_application_id), 0),
            2
        ) AS approval_rate

    FROM fact_loan_application

    GROUP BY loan_product_id
),

loan_summary AS (
    SELECT
        la.loan_product_id,

        COUNT(DISTINCT loa.loan_account_id) AS total_loans,

        SUM(loa.sanctioned_amount) AS total_sanctioned_amount,

        SUM(loa.outstanding_principal) AS total_outstanding_principal,

        COUNT(
            CASE
                WHEN ds.dpd_days > 0
                THEN loa.loan_account_id
            END
        ) AS delinquent_loans,

        SUM(
            CASE
                WHEN ds.dpd_days > 0
                THEN ds.overdue_amount
                ELSE 0
            END
        ) AS total_overdue_amount,

        SUM(r.total_recovery) AS total_recovery

    FROM fact_loan_application la

    INNER JOIN fact_loan_account loa
        ON la.loan_application_id = loa.loan_application_id

    LEFT JOIN (
        SELECT
            loan_account_id,
            dpd_days,
            overdue_amount
        FROM (
            SELECT
                loan_account_id,
                dpd_days,
                overdue_amount,
                ROW_NUMBER() OVER (
                    PARTITION BY loan_account_id
                    ORDER BY snapshot_date DESC
                ) AS rn
            FROM fact_delinquency_snapshot
        ) d
        WHERE rn = 1
    ) ds
        ON loa.loan_account_id = ds.loan_account_id

    LEFT JOIN (
        SELECT
            loan_account_id,
            SUM(recovery_amount) AS total_recovery
        FROM fact_recovery
        WHERE DATE_TRUNC('year', recovery_date)
              = DATE_TRUNC('year', CURRENT_DATE)
        GROUP BY loan_account_id
    ) r
        ON loa.loan_account_id = r.loan_account_id

    GROUP BY la.loan_product_id
)

SELECT
    lp.loan_product_name AS "Loan Product",

    a.total_applications AS "Total Applications",

    a.approval_rate AS "Approval Rate (%)",

    l.total_loans AS "Total Loans",

    l.total_sanctioned_amount AS "Total Sanctioned Amount",

    l.total_outstanding_principal AS "Total Outstanding Principal",

    l.delinquent_loans AS "Delinquent Loans",

    ROUND(
        100.0 * l.delinquent_loans
        / NULLIF(l.total_loans, 0),
        2
    ) AS "Delinquency Rate (%)",

    l.total_recovery AS "Total Recovery",

    ROUND(
        100.0 * l.total_recovery
        / NULLIF(l.total_overdue_amount, 0),
        2
    ) AS "Recovery Rate (%)"

FROM dim_loan_product lp

INNER JOIN application_summary a
    ON lp.loan_product_id = a.loan_product_id

INNER JOIN loan_summary l
    ON lp.loan_product_id = l.loan_product_id

ORDER BY l.total_outstanding_principal DESC;
