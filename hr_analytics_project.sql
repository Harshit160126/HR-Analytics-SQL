/*
PROJECT: HR Workforce, Attrition and Compensation Analysis
DATABASE: hr_analytics
SOURCE TABLE: hr_data
DATASET: 3,000 synthetic employee records
DBMS: PostgreSQL

OBJECTIVE:
Analyse workforce composition, historical exits, hiring trends,
tenure at exit, compensation and recruitment sources.

METRIC DEFINITIONS:
Historical exit percentage = exited records / total records * 100.
This differs from attrition measured over a specific period.
2026 results represent a partial year.
*/


SELECT * from hr_data;

SELECT employee_id, date_of_birth, date_of_joining
FROM hr_data
ORDER BY employee_id
LIMIT 10;

SELECT COUNT(*) AS total_records
FROM hr_data;

SELECT employee_id, COUNT(*) as occurences
FROM hr_data
GROUP BY employee_id
HAVING COUNT(*) > 1;

SELECT employment_status, COUNT(*) AS employee_count
FROM hr_data
GROUP BY employment_status
ORDER BY employee_count DESC;

SELECT 
employee_id,
employment_status,
date_of_joining,
date_of_exit 
FROM hr_data 
WHERE date_of_joining IS NULL 
OR date_of_exit < date_of_joining
OR (employment_status = 'Active' AND date_of_exit IS NOT NULL)
OR (employment_status = 'Exited' AND date_of_exit IS NULL);

SELECT
    MIN(date_of_joining) AS earliest_joining,
    MAX(date_of_joining) AS latest_joining,
    MIN(date_of_exit) AS earliest_exit,
    MAX(date_of_exit) AS latest_exit
FROM hr_data;

SELECT
    COUNT(*) AS total_employee_records,
    COUNT(*) FILTER (
        WHERE employment_status = 'Active'
    ) AS active_employees,
    COUNT(*) FILTER (
        WHERE employment_status = 'Exited'
    ) AS exited_employees,
    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE employment_status = 'Exited'
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS historical_exit_percentage,
    ROUND(
        AVG(annual_salary_inr) FILTER (
            WHERE employment_status = 'Active'
        ),
        2
    ) AS average_active_salary_inr
FROM hr_data;

SELECT
    department,
    COUNT(*) AS total_employee_records,
    COUNT(*) FILTER (
        WHERE employment_status = 'Active'
    ) AS active_employees,
    COUNT(*) FILTER (
        WHERE employment_status = 'Exited'
    ) AS exited_employees,
    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE employment_status = 'Exited'
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS historical_exit_percentage,
    ROUND(
        AVG(annual_salary_inr) FILTER (
            WHERE employment_status = 'Active'
        ),
        2
    ) AS average_active_salary_inr
FROM hr_data
GROUP BY department
ORDER BY historical_exit_percentage DESC,
         total_employee_records DESC;

SELECT
    COALESCE(
        NULLIF(TRIM(exit_reason), ''),
        'Not recorded'
    ) AS exit_reason,
    COUNT(*) AS exited_employees,
    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER (),
        2
    ) AS percentage_of_exits
FROM hr_data
WHERE employment_status = 'Exited'
GROUP BY
    COALESCE(
        NULLIF(TRIM(exit_reason), ''),
        'Not recorded'
    )
ORDER BY exited_employees DESC, exit_reason;

SELECT
    COALESCE(
        NULLIF(TRIM(exit_reason), ''),
        'Not recorded'
    ) AS exit_reason,
    COUNT(*) AS exited_employees,
    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER (),
        2
    ) AS percentage_of_department_exits
FROM hr_data
WHERE employment_status = 'Exited'
  AND department = 'Customer Support'
GROUP BY
    COALESCE(
        NULLIF(TRIM(exit_reason), ''),
        'Not recorded'
    )
ORDER BY exited_employees DESC, exit_reason;

WITH employee_events AS (
    SELECT
        EXTRACT(YEAR FROM date_of_joining)::int AS year,
        'Hire' AS event_type
    FROM hr_data
    WHERE date_of_joining IS NOT NULL

    UNION ALL

    SELECT
        EXTRACT(YEAR FROM date_of_exit)::int AS year,
        'Exit' AS event_type
    FROM hr_data
    WHERE date_of_exit IS NOT NULL
)
SELECT
    year,
    COUNT(*) FILTER (WHERE event_type = 'Hire') AS hires,
    COUNT(*) FILTER (WHERE event_type = 'Exit') AS exits,
    COUNT(*) FILTER (WHERE event_type = 'Hire')
        - COUNT(*) FILTER (WHERE event_type = 'Exit')
        AS net_headcount_change
FROM employee_events
GROUP BY year
ORDER BY year;

WITH employee_events AS (
    SELECT
        EXTRACT(YEAR FROM date_of_joining)::int AS year,
        1 AS headcount_change
    FROM hr_data
    WHERE date_of_joining IS NOT NULL

    UNION ALL

    SELECT
        EXTRACT(YEAR FROM date_of_exit)::int AS year,
        -1 AS headcount_change
    FROM hr_data
    WHERE date_of_exit IS NOT NULL
),
yearly_summary AS (
    SELECT
        year,
        COUNT(*) FILTER (
            WHERE headcount_change = 1
        ) AS hires,
        COUNT(*) FILTER (
            WHERE headcount_change = -1
        ) AS exits,
        SUM(headcount_change) AS net_headcount_change
    FROM employee_events
    GROUP BY year
)
SELECT
    year,
    hires,
    exits,
    net_headcount_change,
    SUM(net_headcount_change) OVER (
        ORDER BY year
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS closing_headcount
FROM yearly_summary
ORDER BY year;


WITH exit_tenure AS (
    SELECT
        employee_id,
        CASE
            WHEN date_of_joining IS NULL
              OR date_of_exit IS NULL
              OR date_of_exit < date_of_joining
                THEN 'Invalid or missing dates'
            WHEN date_of_exit < date_of_joining + INTERVAL '1 year'
                THEN 'Less than 1 year'
            WHEN date_of_exit < date_of_joining + INTERVAL '3 years'
                THEN '1 to less than 3 years'
            WHEN date_of_exit < date_of_joining + INTERVAL '5 years'
                THEN '3 to less than 5 years'
            ELSE '5 years or more'
        END AS tenure_band
    FROM hr_data
    WHERE employment_status = 'Exited'
)
SELECT
    tenure_band,
    COUNT(*) AS exited_employees,
    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER (),
        2
    ) AS percentage_of_exits
FROM exit_tenure
GROUP BY tenure_band
ORDER BY CASE tenure_band
    WHEN 'Less than 1 year' THEN 1
    WHEN '1 to less than 3 years' THEN 2
    WHEN '3 to less than 5 years' THEN 3
    WHEN '5 years or more' THEN 4
    ELSE 5
END;

SELECT
    COALESCE(
        NULLIF(TRIM(exit_reason), ''),
        'Not recorded'
    ) AS exit_reason,
    COUNT(*) AS first_year_exits,
    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER (),
        2
    ) AS percentage_of_first_year_exits
FROM hr_data
WHERE employment_status = 'Exited'
  AND date_of_exit >= date_of_joining
  AND date_of_exit < date_of_joining + INTERVAL '1 year'
GROUP BY
    COALESCE(
        NULLIF(TRIM(exit_reason), ''),
        'Not recorded'
    )
ORDER BY first_year_exits DESC, exit_reason;

SELECT
    performance_rating,
    COUNT(*) AS active_employees,
    ROUND(AVG(annual_salary_inr), 2) AS average_salary_inr,
    MIN(annual_salary_inr) AS minimum_salary_inr,
    MAX(annual_salary_inr) AS maximum_salary_inr
FROM hr_data
WHERE employment_status = 'Active'
GROUP BY performance_rating
ORDER BY performance_rating;

SELECT
    department,
    performance_rating,
    COUNT(*) AS active_employees,
    ROUND(AVG(annual_salary_inr), 2) AS average_salary_inr
FROM hr_data
WHERE employment_status = 'Active'
GROUP BY department, performance_rating
ORDER BY department, performance_rating;

WITH job_salary AS (
    SELECT
        department,
        job_title,
        COUNT(*) AS active_employees,
        AVG(annual_salary_inr) AS average_salary
    FROM hr_data
    WHERE employment_status = 'Active'
    GROUP BY department, job_title
    HAVING COUNT(*) >= 5
),
ranked_jobs AS (
    SELECT
        *,
        DENSE_RANK() OVER (
            PARTITION BY department
            ORDER BY average_salary DESC
        ) AS salary_rank
    FROM job_salary
)
SELECT
    department,
    job_title,
    active_employees,
    ROUND(average_salary, 2) AS average_salary_inr,
    salary_rank
FROM ranked_jobs
WHERE salary_rank <= 3
ORDER BY department, salary_rank, job_title;

SELECT
    COALESCE(
        NULLIF(TRIM(recruitment_source), ''),
        'Not recorded'
    ) AS recruitment_source,
    COUNT(*) AS total_employee_records,
    COUNT(*) FILTER (
        WHERE employment_status = 'Active'
    ) AS active_employees,
    COUNT(*) FILTER (
        WHERE employment_status = 'Exited'
    ) AS exited_employees,
    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE employment_status = 'Exited'
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS historical_exit_percentage
FROM hr_data
GROUP BY
    COALESCE(
        NULLIF(TRIM(recruitment_source), ''),
        'Not recorded'
    )
ORDER BY total_employee_records DESC;

CREATE OR REPLACE VIEW vw_department_summary AS
SELECT
    department,
    COUNT(*) AS total_employee_records,
    COUNT(*) FILTER (
        WHERE employment_status = 'Active'
    ) AS active_employees,
    COUNT(*) FILTER (
        WHERE employment_status = 'Exited'
    ) AS exited_employees,
    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE employment_status = 'Exited'
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS historical_exit_percentage,
    ROUND(
        AVG(annual_salary_inr) FILTER (
            WHERE employment_status = 'Active'
        ),
        2
    ) AS average_active_salary_inr
FROM hr_data
GROUP BY department;

SELECT *
FROM vw_department_summary
ORDER BY historical_exit_percentage DESC;

CREATE OR REPLACE VIEW vw_workforce_summary AS
SELECT
    COUNT(*) AS total_employee_records,
    COUNT(*) FILTER (
        WHERE employment_status = 'Active'
    ) AS active_employees,
    COUNT(*) FILTER (
        WHERE employment_status = 'Exited'
    ) AS exited_employees,
    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE employment_status = 'Exited'
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS historical_exit_percentage,
    ROUND(
        AVG(annual_salary_inr) FILTER (
            WHERE employment_status = 'Active'
        ),
        2
    ) AS average_active_salary_inr
FROM hr_data;

SELECT * FROM vw_workforce_summary;

/*
VERIFIED FINDINGS:
1. 3,000 employee records: 2,498 active and 502 exited.
2. Historical exit percentage: 16.73%.
3. Customer Support had the highest departmental exit
   percentage: 21.38%; IT had the lowest: 14.24%.
4. Better Opportunity, Career Growth and Compensation
   accounted for 308 exits, or 61.35% of all exits.
5. 194 exits (38.65%) occurred before the first anniversary.
6. 372 exits (74.10%) occurred before completing three years.
7. Average active annual salary: INR 1,057,301.84.
8. Average salary did not consistently increase with
   performance rating; patterns varied by department.

LIMITATIONS:
Results describe synthetic data.
Salary comparisons do not establish causes of exits or pay differences.
Recruitment source comparisons depend on hiring dates and time employed.
*/
