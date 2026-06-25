# HR Analytics | End-to-End Data Warehouse & Power BI Solution

![Python](https://img.shields.io/badge/Python-3.11-3776AB?style=flat&logo=python&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15-336791?style=flat&logo=postgresql&logoColor=white)
![Power BI](https://img.shields.io/badge/Power%20BI-Dashboard-F2C811?style=flat&logo=powerbi&logoColor=black)
![SQL](https://img.shields.io/badge/SQL-Kimball%20Star%20Schema-CC2927?style=flat)
![Records](https://img.shields.io/badge/Dataset-2%2C000%2C000%20records-4CAF50?style=flat)
![Status](https://img.shields.io/badge/Status-Complete-success?style=flat)

> A production-grade HR analytics pipeline built on 2 million employee records, from raw CSV ingestion to a validated Kimball star schema and interactive Power BI dashboards.

---

## Dashboard Preview

| HR Overview | Workforce Analysis |
|---|---|
| ![Overview](images/PowerBI_hr_analytics.png) | ![Workforce](images/PowerBI_workforce_analysis.png) |

| Compensation Analysis | Hiring Trends |
|---|---|
| ![Compensation](images/PowerBI_Dashboard_Compensation_Analysis.png) | ![Hiring](images/PowerBI_hiring_trends.png) |

| Business Recommendations | Data Model |
|---|---|
| ![Recommendations](images/PowerBI_Business_Recommendations.png) | ![Model](images/PowerBI_data_model.png) |

---

## Architecture

```
Raw CSV (2M rows)
      │
      ▼
┌─────────────────────┐
│  Python ETL Script  │  load_raw.py - PostgreSQL COPY (bulk load)
│  etl/load_raw.py    │  ~30s for 2M rows, row-count validation
└─────────────────────┘
      │
      ▼
┌─────────────────────┐
│   raw.hr_employees_ │  Landing zone - untouched, preserved
│   raw (PostgreSQL)  │  Baseline for audit & reprocessing
└─────────────────────┘
      │
      ▼
┌─────────────────────┐
│  SQL Cleaning       │  02_cleaning.sql - 5-step CTE pipeline
│  clean.hr_employees │  Business rules, median fallback, imputation
└─────────────────────┘
      │
      ▼
┌─────────────────────┐
│  Kimball Star Schema│  04_star_schema.sql - 1 fact + 7 dimensions
│  mart schema        │  Surrogate keys, FK constraints, indexes
└─────────────────────┘
      │
      ▼
┌─────────────────────┐
│  Power BI           │  6 dashboard pages - DAX measures
│  Semantic Model     │  Connected to mart schema
└─────────────────────┘
```

---

## Key Results

| Metric | Value |
|--------|-------|
| Total employee records | 2,000,000 |
| Records corrected | 173,329 (8.67%) |
| Records passing all checks | 1,826,671 (91.33%) |
| Duplicate IDs | 0 |
| Quality checks passed | 13 / 13 ✅ |
| Star schema FK violations | 0 ✅ |
| Fact table rows reconciled | 2,000,000 / 2,000,000 ✅ |

---

## Data Quality Pipeline

The raw dataset contained **48,000+ intentional logical errors** across 4 categories, corrected in a single SQL pass using CTEs:

| Issue | Records | Fix Applied |
|-------|---------|-------------|
| Negative Experience_Years | 2,421 | Set to 0 |
| Non-positive Salary | 3,333 | Median by (Department, Job Level) |
| Age / Experience violations (`Age < Exp + 22`) | 164,830 | Age corrected to `Exp + 22` |
| Missing Performance_Rating | 3,333 | Departmental mode imputation |

Every corrected record is flagged with audit columns (`was_corrected`, `correction_count`) for full traceability in Power BI.

---

## Star Schema

```
dim_department ──┐
dim_job_level  ──┤
dim_location   ──┤
dim_date       ──┼──► fact_employee (2,000,000 rows)
dim_perf_rating──┤         salary, age, experience_years, tenure_years
dim_status     ──┤
dim_work_mode  ──┘
```

| Table | Rows |
|-------|------|
| `fact_employee` | 2,000,000 |
| `dim_department` | 5 |
| `dim_job_level` | 4 |
| `dim_location` | 35 |
| `dim_performance_rating` | 4 |
| `dim_status` | 4 |
| `dim_work_mode` | 3 |
| `dim_date` | 6,576 |

---

## Project Structure

```
hr-analytics-project/
│
├── data/
│   ├── raw/
│   │   └── hr_raw.csv              ← not committed (2 GB+)
│   └── processed/
│       └── hr_cleaned.csv
│
├── etl/
│   └── load_raw.py                 ← PostgreSQL COPY bulk loader
│
├── sql/
│   ├── 01_schema.sql               ← raw + clean + mart schema creation
│   ├── 02_cleaning.sql             ← CTE cleaning pipeline
│   ├── 03_quality_checks.sql       ← quality validation checks
│   ├── 04_star_schema.sql          ← Kimball star schema (mart)
│   └── 05_mart_quality_checks.sql  ← FK + measure validation
│
├── notebooks/
│   └── 01_exploratory_data_analysis.ipynb
│
├── docs/
│   ├── data_quality_report.md      ← cleaning results & audit
│   └── star_schema.md              ← design decisions & diagram
│
├── powerbi/
│   └── hr_analytics.pbix           ← Power BI dashboard
│
├── images/                         ← dashboard screenshots
│
├── .env                            ← DATABASE_URL (not committed)
├── .env.example                    ← DATABASE_URL template
├── .gitignore
├── .python-version
├── pyproject.toml
├── uv.lock
└── README.md
```

---

## Quick Start

### Prerequisites
- Python 3.11+
- PostgreSQL 15+
- Power BI Desktop

### 1. Clone & install

```bash
git clone https://github.com/afrahsanaa/hr-analytics-project.git
cd hr-analytics-project
pip install -r pyproject.toml

# or with uv:
uv sync
```

### 2. Configure database

```bash
cp .env.example .env
# Edit .env and set your DATABASE_URL
# DATABASE_URL=postgresql://user:password@localhost:5432/hr_analytics
```

### 3. Run the pipeline

```bash
# Create schemas and tables
psql "$DATABASE_URL" -f sql/01_schema.sql

# Load raw data (2M rows, ~30s)
python etl/load_raw.py

# Clean and transform
psql "$DATABASE_URL" -f sql/02_cleaning.sql

# Validate cleaning
psql "$DATABASE_URL" -f sql/03_quality_checks.sql

# Build star schema
psql "$DATABASE_URL" -f sql/04_star_schema.sql

# Validate star schema
psql "$DATABASE_URL" -f sql/05_mart_quality_checks.sql
```

### 4. Connect Power BI

Open `powerbi/hr_analytics.pbix` → Transform Data → update the PostgreSQL server/database settings to point to your instance.

---

## Dashboard Pages

| Page | Description |
|------|-------------|
| **HR Analytics** | Executive overview - 8 KPIs, treemap, salary ranking, work mode |
| **Workforce Analysis** | Demographics - age distribution, map, job level pyramid |
| **Compensation Analysis** | Salary by dept/level/tenure band, performance distribution |
| **Hiring Trends** | Annual volume, quarterly seasonality, dept hiring split |
| **Business Recommendations** | 4 data-driven findings with strategic recommendations |
| **About This Project** | Architecture, tech stack, business questions, skills |

---

## Skills Demonstrated

`Data Warehouse Design` · `Kimball Star Schema Modeling` · `SQL CTEs & Window Functions` · `Python ETL (COPY bulk load)` · `Data Quality Assessment` · `PostgreSQL Constraints & Indexes` · `Power BI DAX` · `Dashboard Storytelling` · `Business Intelligence Reporting`

---

## Requirements

```
psycopg2-binary>=2.9
python-dotenv>=1.0
```


