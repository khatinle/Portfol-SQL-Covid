/* Covid 19 Data Exploration
Data as off 1 Aug 2024 

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/

SELECT *
FROM PortfolioProject..CovidDeathsWiz
WHERE continent is not null
ORDER BY 3,4

-- Select Data that we are going to be starting with

SELECT continent, location, date, population, total_cases, new_cases, total_deaths
FROM PortfolioProject..CovidDeathsWiz
WHERE continent is not null
ORDER BY 2,3

-- Total Cases vs Total Deaths per day
-- Shows likelihood of dying if you contract covid in Vietnam
SELECT location, date, population, total_cases, new_cases, total_deaths, (total_deaths/nullif(total_cases, 0))*100 as DeathPercentage
FROM PortfolioProject..CovidDeathsWiz
WHERE location like '%Vietnam%'
    AND continent is not null
ORDER BY 1,2

-- Total Cases vs Population
-- Shows what percentage of population infected with Covid

WITH PercentPopulationInfected (location, population, TotalCases)
AS
(
    SELECT location, population, MAX(total_cases) as TotalCases
FROM PortfolioProject..CovidDeathsWiz
WHERE continent is not null
GROUP BY location, population
--ORDER BY TotalCases DESC
)
SELECT *, TotalCases/population*100 as PercentInfected
FROM PercentPopulationInfected
ORDER BY TotalCases DESC

-- Countries with Highest Infection Rate compared to Population

SELECT location, population, MAX(total_cases) as TotalCases, MAX(total_cases)/population*100 as InfectionRate
FROM PortfolioProject..CovidDeathsWiz
WHERE continent is not null
GROUP BY location, population
ORDER BY InfectionRate DESC

-- Countries with Highest Death Count per Population

SELECT location, population, MAX(total_cases) as TotalCases, MAX(total_deaths) as TotalDeaths, MAX(total_deaths)/population*100 as DeathRate
FROM PortfolioProject..CovidDeathsWiz
WHERE continent is not null
GROUP BY location, population
ORDER BY DeathRate DESC

-- BREAKING THINGS DOWN BY CONTINENT

-- Showing contintents with the highest death count per population

SELECT continent, MAX(total_cases) as TotalCases, MAX(total_deaths) as TotalDeaths
FROM PortfolioProject..CovidDeathsWiz
WHERE continent is not NULL
GROUP BY continent
ORDER BY TotalDeaths DESC

-- GLOBAL NUMBERS

SELECT SUM(new_cases) as TotalCases, SUM(new_deaths) as TotalDeaths, SUM(cast(new_deaths as float))/SUM(new_cases)*100 as DeathPercentage
FROM PortfolioProject..CovidDeathsWiz
WHERE continent is not null

-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
    SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingVaccinated
FROM PortfolioProject..CovidDeathsWiz dea 
    JOIN PortfolioProject..CovidVaccinations vac 
    ON dea.location = vac.location 
    AND dea.date = vac.date 
WHERE dea.continent is not null
ORDER BY 1,2,3

-- Using CTE to perform Calculation on Partition By in previous query

WITH PopvsVac (continent, location, date, population, new_vaccinations, RollingVaccinated)
AS
(
    SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
    SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingVaccinated
FROM PortfolioProject..CovidDeathsWiz dea 
    JOIN PortfolioProject..CovidVaccinations vac 
    ON dea.location = vac.location 
    AND dea.date = vac.date 
WHERE dea.continent is not null
--ORDER BY 1,2,3
)
SELECT *, RollingVaccinated/population*100 as PercentVaccinated
FROM PopvsVac


-- Using Temp Table to perform Calculation on Partition By in previous query

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
    Continent NVARCHAR(255),
    Location NVARCHAR(255),
    Date DATETIME,
    Population FLOAT,
    New_vaccinations FLOAT,
    RollingVaccinated FLOAT
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
    SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingVaccinated
FROM PortfolioProject..CovidDeathsWiz dea 
    JOIN PortfolioProject..CovidVaccinations vac 
    ON dea.date = vac.date 
    AND dea.location = vac.location
WHERE dea.continent is not null
--ORDER BY 1,2,3

SELECT *, RollingVaccinated/population*100
FROM #PercentPopulationVaccinated

-- Creating View to store data for later visualizations

CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
    SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingVaccinated
FROM PortfolioProject..CovidDeathsWiz dea 
    JOIN PortfolioProject..CovidVaccinations vac 
    ON dea.date = vac.date 
    AND dea.location = vac.location
WHERE dea.continent is not null

SELECT *
FROM PercentPopulationVaccinated