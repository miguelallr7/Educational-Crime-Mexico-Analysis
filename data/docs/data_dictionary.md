# 📘 Data Dictionary

This document describes the structure and content of the output tables used in the **Educational-Crime-Mexico-Analysis** project.

---

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
