
-- SQL DATA EXPLORATION OF COVID DEATHS AND VACCINATIONS

-- Table1- CovidDeaths
SELECT *
FROM ProjectPortfolio.dbo.CovidDeaths
ORDER BY 3,4

-- Table 2- CovidVaccinations
SELECT *
FROM ProjectPortfolio.dbo.CovidVaccinations
ORDER BY 3,4

-- Select data that we are going to be using
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM ProjectPortfolio.dbo.CovidDeaths
ORDER BY 1,2

-- Comparing Total cases vs Total deaths & Calculating the DeathPercentage
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM ProjectPortfolio.dbo.CovidDeaths
-- WHERE location like 'Sri lanka'
ORDER BY 1,2

-- Comparing Total cases vs Population & Calculating the Percentage of Infection
SELECT location, date, population, total_cases, (total_cases/population)*100 AS PercentPopulationInfected
FROM ProjectPortfolio.dbo.CovidDeaths
-- WHERE location like 'Sri lanka'
ORDER BY 1,2

-- Looking at countries with highest infection rate compared to population
SELECT location, population, MAX(total_cases) AS HighestInfectionCountPerLocation, MAX((total_cases/population))*100 AS PercentPopulationInfected
FROM ProjectPortfolio.dbo.CovidDeaths
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC

-- Showing countries with highest death count per poulation
-- Use the CAST function to change total_deaths (nvarchar(255)) to integer
SELECT location, MAX(CAST (Total_deaths as int)) AS TotalDeathCount
FROM ProjectPortfolio.dbo.CovidDeaths
WHERE continent is not null
GROUP BY location
ORDER BY TotalDeathCount DESC

-- LET'S BREAK THINGS DOWN BY CONTINENT (INSTEAD OF LOCATION) WHERE continent is not null
-- Showing continents with the highest death count per population
SELECT continent, MAX(CAST (Total_deaths as int)) AS TotalDeathCount
FROM ProjectPortfolio.dbo.CovidDeaths
WHERE continent is not null
GROUP BY continent
ORDER BY TotalDeathCount DESC

-- LET'S BREAK THINGS DOWN BY CONTINENT where continent is null
SELECT location, MAX(CAST (Total_deaths as int)) AS TotalDeathCount
FROM ProjectPortfolio.dbo.CovidDeaths
WHERE continent is null
GROUP BY location
ORDER BY TotalDeathCount DESC

--GLOBAL NUMBERS- Calculating the death percentage all over the world
SELECT SUM(new_cases) AS TotalCases, SUM(CAST(new_deaths AS INT)) AS TotalDeaths, (SUM(CAST(new_deaths AS INT))/SUM(new_cases))*100 AS GlobalDeathPercentage
FROM ProjectPortfolio.dbo.CovidDeaths
WHERE continent is not null
ORDER BY 1,2

-- LETS JOIN TABLE 1 & TABLE 2 TOGETHER - CovidDeaths and CovidVaccinations
SELECT *
FROM ProjectPortfolio.dbo.CovidDeaths dea
JOIN ProjectPortfolio.dbo.CovidVaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date

-- Looking at Total population per country vs Total vaccinations per country 
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
FROM ProjectPortfolio.dbo.CovidDeaths dea
JOIN ProjectPortfolio.dbo.CovidVaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2,3

-- Calculate the total vaccinations for each location
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CAST(vac.new_vaccinations AS INT)) OVER (PARTITION BY dea.location ORDER BY dea.location,dea.date ) AS RollingVaccinationCount
FROM ProjectPortfolio.dbo.CovidDeaths dea
JOIN ProjectPortfolio.dbo.CovidVaccinations vac
  ON dea.location = vac.location
  AND dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2,3

-- The column that was just created 'RollingVaccinationCount' will be used to calculate the vaccination rate in each country
-- Let's calculate the percentage of people vaccinated in each country

-- Use CTE
WITH PopvsVac (continent, location, date, population, new_vaccinations, RollingVaccinationCount)
AS

(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CAST(vac.new_vaccinations AS INT)) OVER (PARTITION BY dea.location ORDER BY dea.location,dea.date ) AS RollingVaccinationCount
FROM ProjectPortfolio.dbo.CovidDeaths dea
JOIN ProjectPortfolio.dbo.CovidVaccinations vac
  ON dea.location = vac.location
  AND dea.date = vac.date
WHERE dea.continent is not null
)
SELECT *, (RollingVaccinationCount/population)*100 AS PercentPopulationVaccinated
FROM PopvsVac


-- TEMPORARY TABLE

DROP TABLE if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingVaccinationCount numeric,
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CAST(vac.new_vaccinations AS INT)) OVER (PARTITION BY dea.location ORDER BY dea.location,dea.date ) AS RollingVaccinationCount
FROM ProjectPortfolio.dbo.CovidDeaths dea
JOIN ProjectPortfolio.dbo.CovidVaccinations vac
  ON dea.location = vac.location
  AND dea.date = vac.date
WHERE dea.continent is not null

SELECT *, (RollingVaccinationCount/population)*100 AS PercentPopulationVaccinated
FROM #PercentPopulationVaccinated



-- Creating view to store data for later visualizations

CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CAST(vac.new_vaccinations AS INT)) OVER (PARTITION BY dea.location ORDER BY dea.location,dea.date ) AS RollingVaccinationCount
FROM ProjectPortfolio.dbo.CovidDeaths dea
JOIN ProjectPortfolio.dbo.CovidVaccinations vac
  ON dea.location = vac.location
  AND dea.date = vac.date
WHERE dea.continent is not null


SELECT *
FROM PercentPopulationVaccinated