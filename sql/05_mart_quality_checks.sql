-- =============================================================
-- HR Analytics - Mart Schema Validation
-- =============================================================
-- All checks should pass (0 violations).
-- =============================================================

-- ── 1. Row count ───────────────────────────────────────────
SELECT 'fact_employee row count' AS check_name, COUNT(*) AS cnt
FROM mart.fact_employee;

-- ── 2. Row count matches clean layer ───────────────────────
SELECT 'Row count match' AS check_name,
       CASE
           WHEN (SELECT COUNT(*) FROM mart.fact_employee) = (SELECT COUNT(*) FROM clean.hr_employees)
           THEN 'PASS'
           ELSE 'FAIL'
       END AS status;

-- ── 3. FK: Department validation ──────────────────────────
SELECT 'Orphan department_key' AS check_name, COUNT(*) AS cnt
FROM mart.fact_employee f
WHERE NOT EXISTS (
    SELECT 1 FROM mart.dim_department d WHERE d.department_key = f.department_key
);

-- ── 4. FK: Job level validation ────────────────────────────
SELECT 'Orphan job_level_key' AS check_name, COUNT(*) AS cnt
FROM mart.fact_employee f
WHERE NOT EXISTS (
    SELECT 1 FROM mart.dim_job_level j WHERE j.job_level_key = f.job_level_key
);

-- ── 5. FK: Location validation ─────────────────────────────
SELECT 'Orphan location_key' AS check_name, COUNT(*) AS cnt
FROM mart.fact_employee f
WHERE NOT EXISTS (
    SELECT 1 FROM mart.dim_location l WHERE l.location_key = f.location_key
);

-- ── 6. FK: Date validation ─────────────────────────────────
SELECT 'Orphan hire_date_key' AS check_name, COUNT(*) AS cnt
FROM mart.fact_employee f
WHERE NOT EXISTS (
    SELECT 1 FROM mart.dim_date d WHERE d.date_key = f.hire_date_key
);

-- ── 7. FK: Performance rating validation ───────────────────
SELECT 'Orphan performance_rating_key' AS check_name, COUNT(*) AS cnt
FROM mart.fact_employee f
WHERE NOT EXISTS (
    SELECT 1 FROM mart.dim_performance_rating p WHERE p.performance_rating_key = f.performance_rating_key
);

-- ── 8. FK: Status validation ───────────────────────────────
SELECT 'Orphan status_key' AS check_name, COUNT(*) AS cnt
FROM mart.fact_employee f
WHERE NOT EXISTS (
    SELECT 1 FROM mart.dim_status s WHERE s.status_key = f.status_key
);

-- ── 9. FK: Work mode validation ────────────────────────────
SELECT 'Orphan work_mode_key' AS check_name, COUNT(*) AS cnt
FROM mart.fact_employee f
WHERE NOT EXISTS (
    SELECT 1 FROM mart.dim_work_mode w WHERE w.work_mode_key = f.work_mode_key
);

-- ── 10. Measure sanity checks ──────────────────────────────
SELECT 'Salary <= 0' AS check_name, COUNT(*) AS cnt
FROM mart.fact_employee
WHERE salary <= 0

UNION ALL

SELECT 'Age < 18' AS check_name, COUNT(*) AS cnt
FROM mart.fact_employee
WHERE age < 18
UNION ALL

SELECT 'Negative tenure' AS check_name, COUNT(*) AS cnt
FROM mart.fact_employee
WHERE tenure_years < 0;

-- ── 11. Dimension summary ──────────────────────────────────
SELECT 'Dimensions' AS section, table_name, row_count
FROM (
    SELECT 'dim_department' AS table_name, COUNT(*) AS row_count FROM mart.dim_department
    UNION ALL
    SELECT 'dim_job_level',             COUNT(*) FROM mart.dim_job_level
    UNION ALL
    SELECT 'dim_location',              COUNT(*) FROM mart.dim_location
    UNION ALL
    SELECT 'dim_performance_rating',    COUNT(*) FROM mart.dim_performance_rating
    UNION ALL
    SELECT 'dim_status',                COUNT(*) FROM mart.dim_status
    UNION ALL
    SELECT 'dim_work_mode',             COUNT(*) FROM mart.dim_work_mode
    UNION ALL
    SELECT 'dim_date',                  COUNT(*) FROM mart.dim_date
    UNION ALL
    SELECT 'fact_employee',             COUNT(*) FROM mart.fact_employee
) AS _
ORDER BY table_name;
