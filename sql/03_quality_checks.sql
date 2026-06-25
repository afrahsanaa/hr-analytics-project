-- =============================================================
-- HR Analytics - Data Quality Checks
-- =============================================================

--  1. Row count reconciliation 
SELECT 'Row count - raw'   AS check_name, COUNT(*) AS cnt FROM raw.hr_employees_raw
UNION ALL
SELECT 'Row count - clean'             , COUNT(*)      FROM clean.hr_employees;

--  2. Unique employee_ids 
SELECT 'Unique employee_ids' AS check_name, COUNT(DISTINCT employee_id) AS cnt
FROM clean.hr_employees;

--  3. Salary validation 
SELECT 'Negative salaries' AS check_name,
       COUNT(*)            AS cnt,
       COUNT(*) * 100.0 / NULLIF((SELECT COUNT(*) FROM clean.hr_employees), 0) AS pct
FROM clean.hr_employees
WHERE salary <= 0;

--  4. Business rule validation: Age >= Experience + 22 
SELECT 'Age/Exp violations' AS check_name,
       COUNT(*)             AS cnt,
       COUNT(*) * 100.0 / NULLIF((SELECT COUNT(*) FROM clean.hr_employees), 0) AS pct
FROM clean.hr_employees
WHERE age < experience_years + 22;

--  5. Negative tenure 
SELECT 'Negative tenure' AS check_name,
       COUNT(*)          AS cnt,
       COUNT(*) * 100.0 / NULLIF((SELECT COUNT(*) FROM clean.hr_employees), 0) AS pct
FROM clean.hr_employees
WHERE tenure_years < 0;

--  6. Negative experience_years 
SELECT 'Negative experience' AS check_name,
       COUNT(*)             AS cnt,
       COUNT(*) * 100.0 / NULLIF((SELECT COUNT(*) FROM clean.hr_employees), 0) AS pct
FROM clean.hr_employees
WHERE experience_years < 0;

--  7. NULL checks (all should be 0) 
SELECT 'NULL - employee_id'         AS check_name, COUNT(*) AS cnt FROM clean.hr_employees WHERE employee_id        IS NULL
UNION ALL
SELECT 'NULL - department'          , COUNT(*)        FROM clean.hr_employees WHERE department         IS NULL
UNION ALL
SELECT 'NULL - job_level'           , COUNT(*)        FROM clean.hr_employees WHERE job_level          IS NULL
UNION ALL
SELECT 'NULL - salary'              , COUNT(*)        FROM clean.hr_employees WHERE salary             IS NULL
UNION ALL
SELECT 'NULL - age'                 , COUNT(*)        FROM clean.hr_employees WHERE age                IS NULL
UNION ALL
SELECT 'NULL - performance_rating'  , COUNT(*)        FROM clean.hr_employees WHERE performance_rating IS NULL
UNION ALL
SELECT 'NULL - hire_date'           , COUNT(*)        FROM clean.hr_employees WHERE hire_date          IS NULL;


--  8. Domain validation 
SELECT 'Invalid job_level' AS check_name,
       COUNT(*)            AS cnt
FROM clean.hr_employees
WHERE job_level NOT IN ('Junior', 'Mid', 'Senior', 'Director');

--  9. Salary sanity (no extreme outliers) 
SELECT 'Salary < 0'  AS check_name, COUNT(*) AS cnt FROM clean.hr_employees WHERE salary < 0
UNION ALL
SELECT 'Salary > 1M', COUNT(*)       FROM clean.hr_employees WHERE salary > 1000000;

--  10. Hire date validity 
SELECT
    COUNT(*) AS future_hire_dates
FROM clean.hr_employees
WHERE hire_date > DATE '2026-12-31';

--  11. Hire year consistency 

SELECT
    COUNT(*) AS invalid_hire_year
FROM clean.hr_employees
WHERE hire_year <> EXTRACT(YEAR FROM hire_date);

--  12. Correction flags validation 
SELECT
    SUM(was_corrected::int) AS corrected_rows,
    SUM(correction_count)   AS total_corrections
FROM clean.hr_employees;

--  13. Summary report 
SELECT 'SUMMARY'                              AS metric,
       COUNT(*)::TEXT                         AS value
FROM clean.hr_employees
UNION ALL
SELECT 'Unique employees', COUNT(DISTINCT employee_id)::TEXT FROM clean.hr_employees
UNION ALL
SELECT 'Departments',       COUNT(DISTINCT department)::TEXT   FROM clean.hr_employees
UNION ALL
SELECT 'Job levels',        COUNT(DISTINCT job_level)::TEXT    FROM clean.hr_employees
UNION ALL
SELECT 'Min hire year',     MIN(hire_year)::TEXT               FROM clean.hr_employees
UNION ALL
SELECT 'Max hire year',     MAX(hire_year)::TEXT               FROM clean.hr_employees
UNION ALL
SELECT 'Min tenure',        MIN(tenure_years)::TEXT            FROM clean.hr_employees
UNION ALL
SELECT 'Max tenure',        MAX(tenure_years)::TEXT            FROM clean.hr_employees
UNION ALL
SELECT 'Avg tenure',        ROUND(AVG(tenure_years), 1)::TEXT  FROM clean.hr_employees;

