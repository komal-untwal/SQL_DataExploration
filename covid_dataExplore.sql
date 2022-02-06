-- /*
-- Covid 19 Data Exploration 
-- Skills used: Joins, CTE's, Temp Tables creation, Windows Functions, Aggregate Functions, Creating Views.
-- */

-- select * from covid_deaths
-- select * from covid_vaccinations

-- Death percentage calculation
SELECT LOCATION, DATE, TOTAL_CASES, TOTAL_DEATHS, (TOTAL_DEATHS/TOTAL_CASES) * 100 AS DEATH_PERCENTAGE 
FROM COVID_DEATHS 
WHERE CONTINENT IS NOT NULL 
ORDER BY 1,2

-- Death percentage calculation (filter by location)
SELECT LOCATION, DATE, TOTAL_CASES, TOTAL_DEATHS, (TOTAL_DEATHS/TOTAL_CASES) * 100 AS DEATH_PERCENTAGE 
FROM COVID_DEATHS 
WHERE LOCATION = "India" 
ORDER BY 1,2

-- calculate Percentage of population affected by covid
SELECT LOCATION, DATE, TOTAL_CASES, POPULATION, (TOTAL_CASES/POPULATION) * 100 AS INFECTED_POPULATION_PERCENTAGE
FROM COVID_DEATHS 
WHERE CONTINENT IS NOT NULL 
-- and location = "India"
ORDER BY 1,2

-- Find countries with the Highest infection rate compared to population ***
SELECT LOCATION, POPULATION, MAX(TOTAL_CASES) AS HIGHEST_TOTALCASE_COUNT, MAX((TOTAL_CASES/POPULATION)) * 100 AS HIGHEST_INFECTED_POPULATION_PERCENTAGE
FROM COVID_DEATHS
WHERE CONTINENT IS NOT NULL 
GROUP BY LOCATION,POPULATION
ORDER BY HIGHEST_INFECTED_POPULATION_PERCENTAGE DESC

-- Find countries with the Highest mortality rate compared to population ****
SELECT LOCATION, POPULATION, MAX(CAST(TOTAL_DEATHS AS UNSIGNED)) AS HIGHEST_TOTALDEATH_COUNT, (MAX(CAST(TOTAL_DEATHS AS UNSIGNED))/POPULATION) * 100 AS HIGHEST_DEATH_PERCENTAGE
FROM COVID_DEATHS 
WHERE CONTINENT IS NOT NULL 
GROUP BY LOCATION,POPULATION
ORDER BY HIGHEST_DEATH_PERCENTAGE DESC


--  Countries with Highest Death Count ******
SELECT LOCATION, MAX(CAST(TOTAL_DEATHS AS UNSIGNED)) AS TOTALDEATHCOUNT
FROM COVID_DEATHS
WHERE CONTINENT IS NOT NULL 
-- and location = 'India'
GROUP BY LOCATION
ORDER BY TOTALDEATHCOUNT DESC

-- Continents with highest death COUNT **
SELECT CONTINENT, MAX(CAST(TOTAL_DEATHS AS UNSIGNED)) AS HIGHEST_DEATHCOUNT
FROM COVID_DEATHS
WHERE CONTINENT IS NOT NULL
GROUP BY CONTINENT
ORDER BY HIGHEST_DEATHCOUNT DESC

-- Global data analysis (filter by per day)
SELECT DATE, SUM(NEW_CASES) AS SUM_TOTAL_CASES, SUM(NEW_DEATHS) AS SUM_TOTAL_DEATHS, SUM(NEW_DEATHS)/SUM(NEW_CASES) *100 AS TOTAL_DEATH_PERCENT
FROM COVID_DEATHS
WHERE CONTINENT IS NOT NULL
GROUP BY DATE
ORDER BY TOTAL_DEATH_PERCENT DESC

-- Global data analysis: total death percentage globally upto date 01/25/2022
SELECT SUM(NEW_CASES) AS SUM_TOTAL_CASES, SUM(NEW_DEATHS) AS SUM_TOTAL_DEATHS, SUM(NEW_DEATHS)/SUM(NEW_CASES) *100 AS TOTAL_DEATH_PERCENT
FROM COVID_DEATHS
WHERE CONTINENT IS NOT NULL


-- -----------------------------------
-- ********Joins******

-- total population vs vaccinations
 
SELECT DEATH.CONTINENT, DEATH.LOCATION, DEATH.DATE, DEATH.POPULATION, VACC.NEW_VACCINATIONS
FROM COVID_DEATHS DEATH
JOIN COVID_VACCINATIONS VACC
ON DEATH.LOCATION = VACC.LOCATION
   AND DEATH.DATE = VACC.DATE
 WHERE DEATH.CONTINENT IS NOT NULL  
 ORDER BY 1,2
 
 -- total population vs vaccinations : calculate rolling sum of population that has received covid vaccination
 
SELECT DEATH.CONTINENT, DEATH.LOCATION, DEATH.DATE, DEATH.POPULATION, VACC.NEW_VACCINATIONS,
SUM(VACC.NEW_VACCINATIONS) OVER (PARTITION BY DEATH.LOCATION ORDER BY DEATH.LOCATION,DEATH.DATE) AS TOTALPOPULATION_VACCINATED
FROM COVID_DEATHS DEATH
JOIN COVID_VACCINATIONS VACC
    ON DEATH.LOCATION = VACC.LOCATION
    AND DEATH.DATE = VACC.DATE
 WHERE DEATH.CONTINENT IS NOT NULL  
 ORDER BY 2,3

-- using CTE to perform calculation on partition by in previous query:  calculate percentage of population that has received covid vaccination 
 
WITH VACCINATED_POP_PERCENT (CONTINENT, LOCATION, DATE, POPULATION, NEW_VACCINATIONS, TOTALPOPULATION_VACCINATED) 
AS
(SELECT DEATH.CONTINENT, DEATH.LOCATION, DEATH.DATE, DEATH.POPULATION, VACC.NEW_VACCINATIONS,
SUM(VACC.NEW_VACCINATIONS) OVER (PARTITION BY DEATH.LOCATION ORDER BY DEATH.LOCATION,DEATH.DATE) AS TOTALPOPULATION_VACCINATED
FROM COVID_DEATHS DEATH
JOIN COVID_VACCINATIONS VACC
    ON DEATH.LOCATION = VACC.LOCATION
    AND DEATH.DATE = VACC.DATE
 WHERE DEATH.CONTINENT IS NOT NULL  
 )
 SELECT *, (TOTALPOPULATION_VACCINATED/POPULATION)*100 AS VACCINATED_POP 
 FROM VACCINATED_POP_PERCENT
 
 --- using temp table to perform calculation on partition by in previous query:  calculate percentage of population that has received covid vaccination 
 
 DROP TABLE IF EXISTS VACCINATED_POPULATION_PERCET
 CREATE TABLE VACCINATED_POPULATION_PERCET (
 CONTINENT TEXT,
 LOCATION TEXT,
 PER DATETIME,
 POPULATION BIGINT,
 NEW_VACCINATION BIGINT,
 TOTALPOPULATION_VACCINATED BIGINT);
 
 INSERT INTO VACCINATED_POPULATION_PERCET 
 SELECT DEATH.CONTINENT, DEATH.LOCATION, DEATH.DATE, DEATH.POPULATION, VACC.NEW_VACCINATIONS,
SUM(VACC.NEW_VACCINATIONS) OVER (PARTITION BY DEATH.LOCATION ORDER BY DEATH.LOCATION,DEATH.DATE) AS TOTALPOPULATION_VACCINATED
FROM COVID_DEATHS DEATH
JOIN COVID_VACCINATIONS VACC
    ON DEATH.LOCATION = VACC.LOCATION
    AND DEATH.DATE = VACC.DATE
 --where death.continent is not null  
 --order by 2,3
 
 SELECT *, (TOTALPOPULATION_VACCINATED/POPULATION)*100 AS VACCINATED_POP 
 FROM VACCINATED_POPULATION_PERCET
 
 -- **** Views *******
 -- creating views to store data
 CREATE VIEW VACCINATED_POPULATION_PERCENT AS
 SELECT DEATH.CONTINENT, DEATH.LOCATION, DEATH.DATE, DEATH.POPULATION, VACC.NEW_VACCINATIONS,
SUM(VACC.NEW_VACCINATIONS) OVER (PARTITION BY DEATH.LOCATION ORDER BY DEATH.LOCATION,DEATH.DATE) AS TOTALPOPULATION_VACCINATED
FROM COVID_DEATHS DEATH
JOIN COVID_VACCINATIONS VACC
    ON DEATH.LOCATION = VACC.LOCATION
    AND DEATH.DATE = VACC.DATE
 WHERE DEATH.CONTINENT IS NOT NULL  
 --order by 2,3