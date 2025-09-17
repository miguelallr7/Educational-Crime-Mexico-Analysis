
-- Unpivot crime rate data from wide to long format for time series analysis
-- Source table: project-mexico-analysis.crime_rate.crime_rate_states_2015_2025
-- Output columns: entity, year, crime_rate

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
);
