# Educational-Crime-Mexico-Analysis

This repository contains data on educational attainment across Mexico's 32 federal entities, crime statistics, economic indicators, and information about the political parties currently governing each state

## Project Overview 

This case study analyzes the relationship between education, socioeconomic indicators, political parties and crime rates accross the 32 Mexican states and the Republic of Mexico. The goal is to uncover patterns that can be shared publicly to address some of the major factors that cause high crime rates.

## Objectives

* Get and analyze official public information of poverty, unemployment and crime rates
* Investigate political party influence on crime rates
* Analyze possible trends and rates variation from 2015 to 2025
* Visualize trends using Tableau


## Data Sources

* Unemployment Rate (SQL Table) - SNIEG Sistema Nacional de Informacion Estadistica y Geografica
* Poverty Rate (SQL Table) - INEGI 
* Crime Rate (SQL Table) - Observatorio Nacional Ciudadano 
* Political Party (SQL Table) - Wikipedia

## Data Cleaning & Transformation Process

All original datasets were initially in wide format, with multiple columns representing different years or categories. These were transformed into long format to facilitate time-series analysis and easier joins across datasets.

### Cleaning Steps

* Removed null or inconsistent values.
* Standardized entity names across all datasets.
* Ensured consistent data types for joins (entity, year).
* Normalized percentage values.

Example: To prepare the crime rate dataset for time-series analysis and visualization, I transformed it from a wide format (multiple year columns) to a long format (one row per year per entity). This was done using BigQuery's UNPIVOT operation:  

```sql
-- Unpivot crime rate data from wide to long format for time series analysis
-- Source table: project-mexico-analysis.crime_rate.crime_rate_states_2015_2025
-- Output columns: entity, year, crime_rate

CREATE OR REPLACE TABLE `project-mexico-analysis.unpivoted_dataset_states.crime_rate_unpivoted` AS
SELECT
  federal_entity AS entity,
  REPLACE(year, 'year_', '') AS year,
  crime_rate
FROM `project-mexico-analysis.crime_rate.crime_rate_states_2015_2025`
UNPIVOT (
  crime_rate FOR year IN (
    year_2015, year_2016, year_2017, year_2018, year_2019, year_2020,
    year_2021, year_2022, year_2023, year_2024, year_2025
  )
)
```
## Tables Content


## 📄 Table: `crime_rate_long_format_unpivot`

| Column       | Type   | Description                          |
|--------------|--------|--------------------------------------|
| `entity`     | STRING | Name of the federal entity (state)   |
| `year`       | INT    | Year of the recorded crime rate      |
| `crime_rate` | FLOAT  | Crime rate per 100,000 inhabitants   |

---

## 📄 Table: `political_party_long_format_unpivot`

| Column            | Type   | Description                            |
|-------------------|--------|----------------------------------------|
| `entity`          | STRING | Name of the federal entity (state)     |
| `year`            | INT    | Year of the political party record     |
| `political_party` | STRING | Political party in power that year     |

---

## 📄 Table: `poverty_rate_long_format_unpivot`

| Column         | Type   | Description                                         |
|----------------|--------|-----------------------------------------------------|
| `entity`       | STRING | Name of the federal entity (state)                  |
| `year`         | INT    | Year of the poverty rate record                     |
| `poverty_rate` | FLOAT  | Percentage of inhabitants living in poverty         |

---

## 📄 Table: `unemployment_rate_long_format_unpivot`

| Column               | Type   | Description                                      |
|----------------------|--------|--------------------------------------------------|
| `entity`             | STRING | Name of the federal entity (state)               |
| `year`               | INT    | Year of the unemployment rate record             |
| `unemployment_rate`  | FLOAT  | Percentage of unemployed inhabitants             |


## Homologated Entity Names for Analysis

To ensure consistency across datasets, all entity names were standardized by removing trailing spaces and converting them to lowercase. A new reference table was created to facilitate joins with other datasets.

```sql
CREATE OR REPLACE TABLE `project-mexico-analysis.unpivoted_dataset_states.clean_entities` AS
SELECT entity
FROM (
  SELECT TRIM(LOWER(entity)) AS entity FROM `project-mexico-analysis.unpivoted_dataset_states.crime_rate_unpivoted`
  UNION DISTINCT
  SELECT TRIM(LOWER(entity)) FROM `project-mexico-analysis.unpivoted_dataset_states.political_party_unpivoted`
  UNION DISTINCT
  SELECT TRIM(LOWER(entity)) FROM `project-mexico-analysis.unpivoted_dataset_states.poverty_rate_unpivoted`
  UNION DISTINCT
  SELECT TRIM(LOWER(federal_entity)) FROM `project-mexico-analysis.unpivoted_dataset_states.unemployment_rate_unpivoted`
)
ORDER BY entity;
```

## Joined Table With The 4 Tables

A new table named joined_states_information was created to consolidate data from the four main sources for further analysis. The resulting table includes:

* entity
* year
* crime_rate
* political_party
* poverty_rate
* unemployment_rate

```sql
CREATE OR REPLACE TABLE `project-mexico-analysis.joined_datasets_analysis.joined_states_information` AS

WITH
clean_entities AS (
  SELECT DISTINCT TRIM(LOWER(entity)) AS entity
  FROM `project-mexico-analysis.unpivoted_dataset_states.clean_entities`
),

crime AS (
  SELECT TRIM(LOWER(entity)) AS entity, year, crime_rate
  FROM `project-mexico-analysis.unpivoted_dataset_states.crime_rate_unpivoted`
),

party AS (
  SELECT TRIM(LOWER(entity)) AS entity, year, political_party
  FROM `project-mexico-analysis.unpivoted_dataset_states.political_party_unpivoted`
),

poverty AS (
  SELECT TRIM(LOWER(entity)) AS entity, year, poverty_rate
  FROM `project-mexico-analysis.unpivoted_dataset_states.poverty_rate_unpivoted`
),

unemployment AS (
  SELECT TRIM(LOWER(entity)) AS entity, year, unemployment_rate
  FROM `project-mexico-analysis.unpivoted_dataset_states.unemployment_rate_unpivoted`
)

SELECT
  ce.entity AS entity,
  cr.year,
  cr.crime_rate,
  pt.political_party,
  pv.poverty_rate,
  un.unemployment_rate

FROM clean_entities ce
LEFT JOIN crime cr ON ce.entity = cr.entity
LEFT JOIN party pt ON ce.entity = pt.entity AND cr.year = pt.year
LEFT JOIN poverty pv ON ce.entity = pv.entity AND cr.year = pv.year
LEFT JOIN unemployment un ON ce.entity = un.entity AND cr.year = un.year

ORDER BY ce.entity, cr.year;


```
## Exploration and extraction of relevant insights

Different queries where performed to extract relevant information and find correlation patterns between the different indicators and years.

## Most Violent State vs Poorest State vs Unemployment Rate from 2015 to 2025

```sql
SELECT
  entity,
  ROUND(AVG(crime_rate), 1) AS avg_crime_rate_per_100k,
  CONCAT(CAST(ROUND(AVG(poverty_rate), 1) AS STRING), '%') AS avg_poverty_rate_percent,
  CONCAT(CAST(ROUND(AVG(unemployment_rate), 1) AS STRING), '%') AS avg_unemployment_rate_percent
FROM
  `project-mexico-analysis.joined_datasets_analysis.joined_states_information`
GROUP BY
  entity
ORDER BY
  avg_crime_rate_per_100k DESC;
```
## Averages by States

| entity              | avg_crime_rate_per_100k | avg_poverty_rate_percent | avg_unemployment_rate_percent |
|---------------------|-------------------------|--------------------------|-------------------------------|
| colima              | 246.0                   | 27.8%                    | 3.2%                          |
| baja california sur | 244.4                   | 21.6%                    | 3.8%                          |
| baja california     | 233.7                   | 22.1%                    | 2.7%                          |
| aguascalientes      | 206.2                   | 29.9%                    | 3.7%                          |
| republica mexicana  | 200.2                   | 42.2%                    | 3.4%                          |
| ciudad de mexico    | 198.4                   | 27.3%                    | 4.8%                          |
| quintana roo        | 196.4                   | 32.9%                    | 3.6%                          |
| morelos             | 183.2                   | 45.7%                    | 2.2%                          |
| guerrero            | 177.3                   | 65%                      | 1.7%                          |
| guanajuato          | 171.2                   | 40.2%                    | 3.9%                          |
| tabasco             | 167.7                   | 51.1%                    | 6%                            |
| chihuahua           | 153.5                   | 26.9%                    | 3.1%                          |
| coahuila            | 146.5                   | 24.8%                    | 4.4%                          |
| san luis potosi     | 134.1                   | 43.3%                    | 2.9%                          |
| estado de mexico    | 133.2                   | 44.8%                    | 4.4%                          |
| nayarit             | 129.0                   | 35.9%                    | 3.4%                          |
| oaxaca              | 127.0                   | 62.5%                    | 1.8%                          |
| jalisco             | 125.9                   | 29.8%                    | 3%                            |
| durango             | 122.9                   | 40.7%                    | 3.9%                          |
| zacatecas           | 112.1                   | 49.2%                    | 3%                            |
| tamaulipas          | 94.8                    | 32.7%                    | 3.8%                          |
| queretaro           | 87.4                    | 29.4%                    | 4%                            |
| sonora              | 84.5                    | 26.5%                    | 3.9%                          |
| michoacan           | 75.1                    | 48.9%                    | 2.4%                          |
| sinaloa             | 73.5                    | 29.3%                    | 3.1%                          |
| puebla              | 71.1                    | 59.3%                    | 3%                            |
| veracruz            | 71.1                    | 55.2%                    | 2.9%                          |
| hidalgo             | 65.5                    | 49.1%                    | 2.5%                          |
| campeche            | 64.6                    | 46.5%                    | 2.9%                          |
| yucatan             | 54.3                    | 44.2%                    | 2.1%                          |
| nuevo leon          | 44.3                    | 19.5%                    | 3.8%                          |
| tlaxcala            | 31.1                    | 55.9%                    | 3.9%                          |
| chiapas             | 28.6                    | 73.4%                    | 2.7%                          |

## Correlation Between Poverty Rate vs Crime Avg
### Process to find correlation

```sql
SELECT
  CORR(poverty_rate, crime_rate) AS poverty_crime_correlation
FROM
  `project-mexico-analysis.joined_datasets_analysis.joined_states_information`;
```
### Result

| poverty_crime_correlation |
|---------------------------|
| -0.36467106377769876      |


Based on the analysis of state-level data in Mexico, we found a moderate negative correlation between poverty rate and crime rate (–0.36). This suggests that, contrary to common assumptions, states with higher poverty levels tend to report slightly lower crime rates. Possible explanations include underreporting in marginalized areas, rural vs. urban dynamics, and the influence of political or institutional factors. Further investigation is recommended to explore these patterns in more detail
