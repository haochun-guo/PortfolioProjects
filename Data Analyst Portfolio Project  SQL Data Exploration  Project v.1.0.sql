USE PortfolioProject
GO

SELECT *
FROM CovidDeaths
ORDER BY 3, 4

--SELECT *
--FROM CovidVaccinations
--ORDER BY 3, 4

-- Select data that we are going to be using

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths
ORDER BY 1, 2

-- Looking at Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract Covid in your country
SELECT location, date, total_cases, total_deaths, ROUND((total_deaths/total_cases) * 100, 4) AS DeathPercentage
FROM CovidDeaths
WHERE location LIKE '%new zealand%'
ORDER BY 1, 2 

-- Looking at  Total Cases vs Population
-- Shows what percentage of population got Covid
SELECT location, date, total_cases, population, (total_cases/population)*100 AS PercentPopulationInfected
FROM CovidDeaths
WHERE location LIKE '%United States%'
ORDER BY 1, 2

-- Looking at Countries with Highest Infection Rate compared to Population
SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population))*100 AS PercentPopulationInfected
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC

-- Showing Countries with Highest Death Count per Population
SELECT location, MAX(CAST(total_deaths AS INT)) AS HighestDeathCount, MAX((CAST(total_deaths AS INT)/population)*100) AS PercentPopulationDied
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY 2 DESC

-- LET'S BREAK THINGS DOWN BY CONTINENT
SELECT continent, MAX(CAST(total_deaths AS int)) AS TotalDeathCount
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC

SELECT location, MAX(CAST(total_deaths AS int)) AS TotalDeathCount
FROM CovidDeaths
WHERE continent IS NULL AND location NOT IN ('Upper middle income', 'World', 'High income', 'Lower middle income', 'Low income', 'European Union', 'International')
GROUP BY location
ORDER BY 2 DESC

WITH Total_Deaths AS (
SELECT continent, location, MAX(total_deaths) AS TotalDeathCountPerCountry
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent, location)

SELECT continent, SUM(CAST(TotalDeathCountPerCountry AS INT)) AS TotalDeathCountPerContinent
FROM Total_Deaths
GROUP BY continent
ORDER BY TotalDeathCountPerContinent DESC

SELECT continent, SUM(CAST(TotalDeathCountPerCountry AS INT)) AS TotalDeathCountPerContinent
FROM (SELECT continent, location, MAX(total_deaths) AS TotalDeathCountPerCountry
	   FROM CovidDeaths
	   WHERE continent IS NOT NULL
       GROUP BY continent, location) sub
GROUP BY continent
ORDER BY TotalDeathCountPerContinent DESC

-- Showing continents with the highest death count

SELECT location, MAX(CAST(total_deaths AS int)) AS TotalDeathCount
FROM CovidDeaths
WHERE continent IS NULL AND location NOT IN ('Upper middle income', 'World', 'High income', 'Lower middle income', 'Low income', 'European Union', 'International')
GROUP BY location
ORDER BY 2 DESC

-- GLOBAL NUMBERS

SELECT date, SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS INT)) AS total_deaths, SUM(CAST(new_deaths AS INT))/SUM(new_cases) * 100 AS DeathPercentage
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date

SELECT SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS INT)) AS total_deaths, SUM(CAST(new_deaths AS INT))/SUM(new_cases) * 100 AS DeathPercentage
FROM CovidDeaths
WHERE continent IS NOT NULL

-- Looking at Total Population vs Vaccinations
 
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
,SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPoepleVaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2, 3

-- USE CTE
WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS 
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
,SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPoepleVaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL)

SELECT *, (RollingPeopleVaccinated/Population) * 100 AS RollingPeopleVaccinationRate
FROM PopvsVac
ORDER BY Continent, Location

WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, PeopleVaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
		SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY dea.continent, dea.location) AS PeopleVaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)

SELECT *, (PeopleVaccinated/Population) * 100 AS PeopleVaccinatedRate
FROM PopvsVac
ORDER BY Continent, Location


-- TEMP TABLE
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
RollingPoepleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
,SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPoepleVaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT *, (RollingPoepleVaccinated/Population) * 100 
FROM #PercentPopulationVaccinated
ORDER BY Continent, Location

--SubQuery

SELECT continent, location, date, population, new_vaccinations, RollingPoepleVaccinated, (RollingPoepleVaccinated/population) * 100 AS VaccinationRates
FROM (SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
			SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (PARTITION BY dea.continent, dea.location ORDER BY dea.location, dea.date) AS RollingPoepleVaccinated
		FROM CovidDeaths dea
		JOIN CovidVaccinations vac
			ON dea.location = vac.location
			AND dea.date = vac.date
		WHERE dea.continent IS NOT NULL) AS POP_SUB

-- Creating View to store data for later visualizations

CREATE VIEW PercentPopulationVaccinated AS (
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
			SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (PARTITION BY dea.continent, dea.location ORDER BY dea.location, dea.date) AS RollingPoepleVaccinated
		FROM CovidDeaths dea
		JOIN CovidVaccinations vac
			ON dea.location = vac.location
			AND dea.date = vac.date
		WHERE dea.continent IS NOT NULL)

SELECT * 
FROM PercentPopulationVaccinated