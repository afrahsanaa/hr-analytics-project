# Star Schema Design

## Overview

After cleaning and validating the HR dataset, a dimensional model was designed following Kimball methodology to support workforce analytics in Power BI.

The objective of this model is to provide a simple and scalable structure for answering HR business questions related to:

- Workforce composition
- Compensation analysis
- Employee performance
- Hiring trends
- Geographic distribution of employees

The model consists of a single fact table surrounded by seven conformed dimensions.

## Grain

The grain of the fact table is defined as:

**One row represents one employee in the workforce snapshot.**

Defining the grain first was a critical design decision because every dimension and measure in the model must conform to this level of detail.

Since the source dataset contains a single workforce snapshot rather than historical employee events, each employee appears exactly once in the fact table.

This design enables straightforward calculation of workforce KPIs such as:

- Headcount
- Average salary
- Average tenure
- Performance distribution
- Workforce composition by department, location, and job level

---

## Dimensions

The dimensional model uses seven dimensions that provide business context for the employee records stored in the fact table.

### Department

Stores organizational structure information used to analyze headcount, compensation, and performance across departments.

### Job Level

Represents employee seniority and supports compensation benchmarking and career progression analysis.

### Location

Provides geographic information (country and city) for regional workforce reporting.

### Performance Rating

Stores performance categories and a numerical score used for aggregation and KPI calculations.

### Status

Represents the employee employment status (Active, Terminated, etc.).

### Work Mode

Allows analysis of workforce distribution across on-site, hybrid, and remote employees.

### Date

Supports hiring trend analysis and time-based reporting in Power BI.

| Dimension | Attributes | Source |
|-----------|------------|--------|
| `dim_department` | `department_key`, `department_name` | `clean.hr_employees.department` |
| `dim_job_level` | `job_level_key`, `job_level_name` | `clean.hr_employees.job_level` |
| `dim_location` | `location_key`, `country`, `city` | `clean.hr_employees.country`, `city` |
| `dim_performance_rating` | `performance_rating_key`, `performance_rating`, `rating_score` | `clean.hr_employees.performance_rating` |
| `dim_status` | `status_key`, `status_name` | `clean.hr_employees.status` |
| `dim_work_mode` | `work_mode_key`, `work_mode_name` | `clean.hr_employees.work_mode` |
| `dim_date` | `date_key` (YYYYMMDD), `full_date`, `year`, `quarter`, `month`, `month_name` | Generated from `MIN(hire_date)` to `MAX(hire_date)` |

- All dimensions use **surrogate keys** (`SERIAL PRIMARY KEY`).
- All surrogate keys are opaque, no business meaning encoded in the key value.

---

## Fact Table

| Column | Type | Role |
|--------|------|------|
| `employee_id` | Degenerate dimension | Employee identifier (no separate dimension needed) |
| `department_key` | FK → `dim_department` | |
| `job_level_key` | FK → `dim_job_level` | |
| `location_key` | FK → `dim_location` | |
| `hire_date_key` | FK → `dim_date` | |
| `performance_rating_key` | FK → `dim_performance_rating` | |
| `status_key` | FK → `dim_status` | |
| `work_mode_key` | FK → `dim_work_mode` | |
| `salary` | Measure | Numeric |
| `age` | Measure | Integer |
| `experience_years` | Measure | Integer |
| `tenure_years` | Measure | Numeric (1 decimal) |

#### Measures

The fact table contains the quantitative metrics used for analysis.

These measures support workforce, compensation, and performance analytics across all dimensions.

---

## Schema Diagram

```
┌───────────────────┐
│   dim_department  │
├───────────────────┤
│ department_key PK │──┐
│ department_name   │  │
└───────────────────┘  │
                       │
┌───────────────────┐  │
│   dim_job_level   │  │
├───────────────────┤  │
│ job_level_key PK  │──┤
│ job_level_name    │  │
└───────────────────┘  │
                       │
┌───────────────────┐  │
│   dim_location    │  │
├───────────────────┤  │
│ location_key PK   │──┤
│ country           │  │
│ city              │  │
└───────────────────┘  │     ┌─────────────────────────────────┐
                       ├─────│         fact_employee           │
┌───────────────────┐  │     │─────────────────────────────────│
│ dim_perf_rating   │  │     │ employee_id          (DD)       │
├───────────────────┤  │     │ department_key        (FK)  ────│
│ perf_rating_key PK│──┤     │ job_level_key         (FK)  ────│
│ performance_rating│  │     │ location_key          (FK)  ────│
│ rating_score      │  │     │ hire_date_key         (FK)  ────│
└───────────────────┘  │     │ performance_rating_key(FK)  ────│
                       │     │ status_key            (FK)  ────│
┌───────────────────┐  │     │ work_mode_key         (FK)  ────│
│    dim_status     │  │     │─────────────────────────────────│
├───────────────────┤  │     │ salary                (measure) │
│ status_key PK     │──┤     │ age                   (measure) │
│ status_name       │  │     │ experience_years      (measure) │
└───────────────────┘  │     │ tenure_years          (measure) │
                       │     └─────────────────────────────────┘
┌───────────────────┐  │
│  dim_work_mode    │  │
├───────────────────┤  │
│ work_mode_key PK  │──┤
│ work_mode_name    │  │
└───────────────────┘  │
                       │
┌───────────────────┐  │
│     dim_date      │  │
├───────────────────┤  │
│ date_key PK       │──┘
│ full_date         │  
│ year              │  
│ quarter           │  
│ month             │  
│ month_name        │  
└───────────────────┘  
                       
All relationships: 1:N, single direction (dimension → fact)
```

---

## Design Decisions

Several modeling decisions were made to keep the schema simple while preserving analytical flexibility.

### Single Fact Table

A single fact table was chosen because all analytical measures share the same grain: one row per employee.

Creating separate fact tables for compensation, workforce, and performance would have duplicated dimension keys and increased model complexity without providing additional analytical value.

### Degenerate Employee Dimension

Employee identifiers are stored directly in the fact table as a degenerate dimension.

Since employee_id has no descriptive attributes, creating a dedicated dimension table would result in a one-to-one relationship with the fact table and provide no analytical benefit.

### Performance Rating Score

Performance ratings are stored both as descriptive labels and numerical scores.

The numerical score enables aggregation functions such as averages, rankings, and KPI calculations while preserving the original business categories.

---

## Power BI Relationships

| Dimension | Relates To | Cardinality |
|-----------|-----------|-------------|
| `dim_department` | `fact_employee[department_key]` | 1:N |
| `dim_job_level` | `fact_employee[job_level_key]` | 1:N |
| `dim_location` | `fact_employee[location_key]` | 1:N |
| `dim_performance_rating` | `fact_employee[performance_rating_key]` | 1:N |
| `dim_status` | `fact_employee[status_key]` | 1:N |
| `dim_work_mode` | `fact_employee[work_mode_key]` | 1:N |
| `dim_date` | `fact_employee[hire_date_key]` | 1:N |

All relationships: **Cross filter direction = Single**, **Cardinality = One-to-Many**.

## Supported Analytics

This dimensional model supports the following analytical use cases:

### Workforce Analytics
- Headcount by department
- Workforce by location
- Workforce by job level
- Employee status distribution

### Compensation Analytics
- Average salary by department
- Salary benchmarking by job level
- Payroll cost analysis

### Performance Analytics
- Performance distribution
- Average rating by department
- High performer identification

### Hiring Analytics
- Hiring trends over time
- Hiring distribution by location
- Workforce growth analysis

