# Data Quality Report
## HR Analytics - 2,000,000 Employee Records

*Pipeline: `raw.hr_employees_raw` → `clean.hr_employees` → `mart.fact_employee`*

---

## 1. Raw Dataset Overview

| Metric | Value |
|--------|-------|
| Total records | 2,000,000 |
| Columns | 15 |
| Primary key (`employee_id`) | Unique - 0 duplicates |
| Departments | 5 |
| Job levels | 4 (Junior, Mid, Senior, Director) |
| Hire date range | 2008 – 2026 |

---

## 2. Issues Identified in Raw Data

| Issue | Records Affected | % of Total |
|-------|-----------------|------------|
| Negative `experience_years` | 2,421 | 0.12% |
| Non-positive `salary` (≤ 0) | 3,333 | 0.17% |
| Age / Experience violations (`age < exp + 22`) | 164,830 | 8.24% |
| Missing `performance_rating` | 3,333 | 0.17% |
| **Total records with at least one issue** | **173,329** | **8.67%** |

---

## 3. Cleaning Rules Applied

All corrections were applied in a single SQL pass (`02_cleaning.sql`) using chained CTEs, in the following order:

| Step | Issue | Rule Applied |
|------|-------|-------------|
| 1 | Negative `experience_years` | Set to `0` |
| 2 | Non-positive `salary` | Replace with `PERCENTILE_CONT(0.5)` median by `(Department, Job Level)` - falls back to global median if group is too small |
| 3 | `age < experience_years + 22` | Correct `age` to `experience_years + 22` |
| 4 | NULL `performance_rating` | Impute with departmental mode (most frequent rating per department) - preserves distribution |
| 5 | Feature engineering | Derive `hire_year` from `hire_date`; compute `tenure_years` relative to `2026-12-31` |

Every corrected record carries audit flags: `was_corrected` (boolean) and `correction_count` (integer) for full traceability.

---

## 4. Correction Distribution

| Corrections per Record | Records |
|-----------------------|---------|
| 0 - no changes needed | 1,826,671 |
| 1 - single correction | 172,741 |
| 2 - multiple corrections | 588 |

**Interpretation:** 91.33% of records required no modification. The 588 multi-correction records indicate isolated compounding errors, not systemic data issues.

---

## 5. Post-Cleaning Validation - `clean.hr_employees`

All 13 checks passed with **0 violations**.

| Check | Result | Count |
|-------|--------|-------|
| Row count - raw vs clean | ✅ PASS | 2,000,000 = 2,000,000 |
| Unique `employee_id` | ✅ PASS | 2,000,000 distinct |
| Duplicate IDs | ✅ PASS | 0 |
| Negative / zero salary | ✅ PASS | 0 |
| Age / Experience violations | ✅ PASS | 0 |
| Negative `tenure_years` | ✅ PASS | 0 |
| Negative `experience_years` | ✅ PASS | 0 |
| NULL `employee_id` | ✅ PASS | 0 |
| NULL `department` | ✅ PASS | 0 |
| NULL `job_level` | ✅ PASS | 0 |
| NULL `salary` | ✅ PASS | 0 |
| NULL `performance_rating` | ✅ PASS | 0 |
| NULL `hire_date` | ✅ PASS | 0 |
| Invalid `job_level` values | ✅ PASS | 0 |
| `salary > 1,000,000` | ✅ PASS | 0 |
| Future `hire_date` (> 2026-12-31) | ✅ PASS | 0 |
| `hire_year` ≠ `EXTRACT(YEAR FROM hire_date)` | ✅ PASS | 0 |
| Correction flags total | ✅ PASS | 173,329 rows / 173,917 corrections |

---

## 6. Star Schema Validation - `mart.fact_employee`

All checks passed after running `04_star_schema.sql` + `05_mart_quality_checks.sql`.

| Check | Result | Value |
|-------|--------|-------|
| Fact table row count | ✅ PASS | 2,000,000 |
| Row count match (clean → mart) | ✅ PASS | Exact |
| Orphan `department_key` | ✅ PASS | 0 |
| Orphan `job_level_key` | ✅ PASS | 0 |
| Orphan `location_key` | ✅ PASS | 0 |
| Orphan `hire_date_key` | ✅ PASS | 0 |
| Orphan `performance_rating_key` | ✅ PASS | 0 |
| Orphan `status_key` | ✅ PASS | 0 |
| Orphan `work_mode_key` | ✅ PASS | 0 |
| `salary ≤ 0` in fact | ✅ PASS | 0 |
| `age < 18` in fact | ✅ PASS | 0 |
| Negative `tenure_years` in fact | ✅ PASS | 0 |

---

## 7. Final Dataset Summary

| Metric | Value |
|--------|-------|
| Total rows (clean + mart) | 2,000,000 |
| Distinct employees | 2,000,000 |
| Departments | 5 |
| Job levels | 4 |
| Locations | 35 |
| Hire year range | 2008 – 2026 |
| Tenure range | 0.8 – 18.8 years |
| Average tenure | 6.5 years |

---

## 8. Conclusion

The cleaning pipeline successfully transformed the raw dataset into a fully validated, analysis-ready employee table. 91.33% of records passed all rules without modification. The remaining 8.67% were corrected using domain-driven business logic with full audit traceability.

The resulting `mart.fact_employee` (2,000,000 rows, 7 validated foreign keys, 0 constraint violations) is ready for Power BI reporting and KPI development.
