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

## Poorest States vs Unemployment Rate

```sql
SELECT
  entity,
  CONCAT(CAST(ROUND(AVG(poverty_rate), 1) AS STRING), '%') AS avg_poverty_rate_percent,
  CONCAT(CAST(ROUND(AVG(unemployment_rate), 1) AS STRING), '%') AS avg_unemployment_rate_percent
FROM
  `project-mexico-analysis`.`joined_datasets_analysis`.`joined_states_information`
GROUP BY
  entity
ORDER BY
  avg_poverty_rate_percent DESC;
```
## Average Poverty and Unemployment Rates by State

| entity              | avg_poverty_rate_percent | avg_unemployment_rate_percent |
|---------------------|--------------------------|-------------------------------|
| chiapas             | 73.4%                    | 2.7%                          |
| guerrero            | 65%                      | 1.7%                          |
| oaxaca              | 62.5%                    | 1.8%                          |
| puebla              | 59.3%                    | 3%                            |
| tlaxcala            | 55.9%                    | 3.9%                          |
| veracruz            | 55.2%                    | 2.9%                          |
| tabasco             | 51.1%                    | 6%                            |
| zacatecas           | 49.2%                    | 3%                            |
| hidalgo             | 49.1%                    | 2.5%                          |
| michoacan           | 48.9%                    | 2.4%                          |
| campeche            | 46.5%                    | 2.9%                          |
| morelos             | 45.7%                    | 2.2%                          |
| estado de mexico    | 44.8%                    | 4.4%                          |
| yucatan             | 44.2%                    | 2.1%                          |
| san luis potosi     | 43.3%                    | 2.9%                          |
| republica mexicana  | 42.2%                    | 3.4%                          |
| durango             | 40.7%                    | 3.9%                          |
| guanajuato          | 40.2%                    | 3.9%                          |
| nayarit             | 35.9%                    | 3.4%                          |
| quintana roo        | 32.9%                    | 3.6%                          |
| tamaulipas          | 32.7%                    | 3.8%                          |
| aguascalientes      | 29.9%                    | 3.7%                          |
| jalisco             | 29.8%                    | 3%                            |
| queretaro           | 29.4%                    | 4%                            |
| sinaloa             | 29.3%                    | 3.1%                          |
| colima              | 27.8%                    | 3.2%                          |
| ciudad de mexico    | 27.3%                    | 4.8%                          |
| chihuahua           | 26.9%                    | 3.1%                          |
| sonora              | 26.5%                    | 3.9%                          |
| coahuila            | 24.8%                    | 4.4%                          |
| baja california     | 22.1%                    | 2.7%                          |
| baja california sur | 21.6%                    | 3.8%                          |
| nuevo leon          | 19.5%                    | 3.8%                          |


