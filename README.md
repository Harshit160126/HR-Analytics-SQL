# HR Workforce, Attrition and Compensation Analysis | PostgreSQL

## Project Overview

This project uses PostgreSQL to analyse 3,000 synthetic employee records and answer business questions about workforce composition, employee exits, hiring trends, tenure, compensation and recruitment sources.

The analysis includes data-quality checks, grouped summaries, date calculations, Common Table Expressions (CTEs), window functions and reusable reporting views.

## Tools and Dataset

- **Database:** PostgreSQL
- **Interface:** pgAdmin
- **Database name:** `hr_analytics`
- **Source table:** `hr_data`
- **Dataset:** 3,000 synthetic employee records
- **Salary currency:** Indian Rupees (INR)

## Business Questions

1. How many employees are active, and how many have exited?
2. Which departments have the highest historical exit percentages?
3. What are the most common reasons for leaving?
4. How have hiring, exits and headcount changed by year?
5. What proportion of exits occurred within the first year or first three years?
6. How does average salary vary across performance ratings and departments?
7. Which job titles have the highest average salaries within each department?
8. How do employee counts and historical exit percentages vary by recruitment source?

## Analysis Completed

### Data Quality
- Checked total record count and duplicate employee IDs.
- Reviewed employment-status values and date ranges.
- Checked missing joining dates, exits before joining, and inconsistencies between employment status and exit dates.

### Workforce and Employee Exits
- Calculated active employees, exited employees and historical exit percentage.
- Compared workforce and exit metrics by department.
- Analysed overall exit reasons and Customer Support exit reasons.

### Hiring and Headcount Trends
- Combined hiring and exit events using `UNION ALL`.
- Calculated annual hires, exits and net headcount change.
- Calculated cumulative closing headcount using a window function.

### Tenure at Exit
- Grouped exited employees into tenure bands.
- Analysed exit reasons among employees leaving before their first anniversary.

### Compensation
- Compared average, minimum and maximum active salaries by performance rating.
- Compared average salaries by department and performance rating.
- Ranked job titles by average active salary within each department using `DENSE_RANK()`.

The ranking includes job titles with at least five active employees. It returns the top three salary ranks, including ties.

### Recruitment Sources
- Compared total employee records, active employees, exited employees and historical exit percentages by recruitment source.

### Reporting Views
- `vw_department_summary`
- `vw_workforce_summary`

## Key Findings

| Metric | Result |
|---|---:|
| Total employee records | 3,000 |
| Active employees | 2,498 |
| Exited employees | 502 |
| Historical exit percentage | 16.73% |
| Highest departmental historical exit percentage | Customer Support: 21.38% |
| Lowest departmental historical exit percentage | IT: 14.24% |
| Exits attributed to Better Opportunity, Career Growth and Compensation | 308 — 61.35% of exits |
| Exits before the first anniversary | 194 — 38.65% of exits |
| Exits before completing three years | 372 — 74.10% of exits |
| Average active annual salary | ₹1,057,301.84 |

Average salary did not consistently increase with performance rating, and patterns varied across departments.

## Business Interpretation

- Customer Support warrants further investigation because it has the highest departmental historical exit percentage.
- The concentration of exits within the first three years suggests reviewing onboarding, early career development and employee support.
- Career growth, compensation and external opportunities are prominent recorded exit reasons.
- Salary comparisons could support a deeper review of pay structures, accounting for job title, experience and other relevant factors.

These are areas for investigation rather than proven causes or guaranteed solutions.

## SQL Techniques Demonstrated

- Aggregate functions: `COUNT`, `AVG`, `MIN`, `MAX`, `SUM`
- Conditional aggregation using `FILTER`
- `GROUP BY`, `HAVING` and `ORDER BY`
- `CASE` expressions
- Date calculations using `EXTRACT` and `INTERVAL`
- Common Table Expressions (CTEs)
- `UNION ALL`
- Window functions: `DENSE_RANK()` and cumulative `SUM() OVER`
- Missing-value handling using `COALESCE`, `NULLIF` and `TRIM`
- Reusable views using `CREATE OR REPLACE VIEW`

## How to Run

1. Create a PostgreSQL database named `hr_analytics`.
2. Create the `hr_data` table with column names matching the SQL script. Joining and exit dates should use date types, and annual salary should use a numeric-compatible type.
3. Import `HR_Analytics_3000_Employees.csv` into `hr_data`.
4. Open `hr_analytics_project.sql` in pgAdmin Query Tool.
5. Execute the entire script or run individual queries to inspect their results.

The script assumes the source table has already been created and populated. The full script was run in PostgreSQL without errors.

## Metric Definitions and Limitations

- **Historical exit percentage** = exited employee records ÷ total employee records × 100. It is not a period-specific attrition rate.
- Percentages in tenure and exit-reason analyses describe the share of exits, not the probability that an employee will leave.
- 2026 results represent a partial year.
- Cumulative headcount assumes the dataset contains the full relevant employee history.
- The dataset is synthetic; findings do not describe a real organisation.
- Salary comparisons do not establish causes of exits or pay differences.
- Recruitment-source comparisons are influenced by hiring dates and time employed.

## Author

**Harshit Kumar Tiwary**

[GitHub](https://github.com/Harshit160126) | [LinkedIn](https://www.linkedin.com/in/harshit-kumar-tiwary041994/)
