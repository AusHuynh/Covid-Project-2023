
SELECT *
FROM Covid.dbo.CovidDeath
WHERE continent IS NOT NULL
ORDER BY location, date

SELECT *
FROM Covid.dbo.CovidVaccination
WHERE continent IS NOT NULL
ORDER BY location, date

SELECT
	location, date, total_cases, new_cases, total_deaths, population
FROM Covid.dbo.CovidDeath
WHERE continent IS NOT NULL
ORDER BY location, date


-- Alter table datatype from varchar to float
ALTER TABLE Covid.[dbo].[CovidDeath]
ALTER COLUMN total_cases float


-- Observing Total Cases vs Total Death
SELECT	continent,
		location, 
		date, 
		total_cases, 
		total_deaths, (total_deaths/total_cases) * 100 AS DeathPercentage, 
		population
FROM Covid.dbo.CovidDeath
WHERE location like '%state%'
		AND continent IS NOT NULL
		AND total_cases IS NOT NULL
		AND total_deaths IS NOT NULL
ORDER BY location, date DESC


-- Observing Total Cases vs Population
SELECT	continent,
		location, 
		date,
		population, 
		total_cases, 
		(total_cases/population) * 100 AS DeathPercentage
FROM Covid.dbo.CovidDeath
WHERE continent IS NOT NULL
		AND total_cases IS NOT NULL
ORDER BY location, date DESC


-- Showing Country with Highest Death Count per Population
SELECT  continent,
		location,
		population,
		MAX(CAST(Total_deaths AS FLOAT)) AS TotalDeathCount,
		MAX(CAST(Total_deaths AS FLOAT))/population * 100 AS DeathPercentage
FROM Covid.dbo.CovidDeath
WHERE continent IS NOT NULL
GROUP BY continent, location, population
ORDER BY DeathPercentage DESC


-- Examining Continent with Highest Death Count per Population
SELECT  continent,
		MAX(CAST(Total_deaths AS FLOAT)) AS TotalDeathCount
FROM Covid.dbo.CovidDeath
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC


-- Global Numbers
SELECT	SUM(new_cases) AS Total_cases, 
		SUM(new_deaths) AS Total_deaths,
		SUM(new_deaths)/SUM(new_cases) * 100 AS DeathPercentage
FROM Covid.dbo.CovidDeath
WHERE continent IS NOT NULL
		AND new_cases <> 0
ORDER BY 1, 2


-- Looking at Total Population vs Vaccination
SELECT dea.continent,
	   dea.location,
	   dea.date,
	   dea.population,
	   vac.new_vaccinations,
	   SUM(CAST(new_vaccinations AS FLOAT)) 
			OVER (PARTITION BY dea.location
			ORDER BY dea.location,
			dea.date) AS RollingPeopleVaccinated
FROM Covid.dbo.CovidDeath dea
JOIN Covid.dbo.CovidVaccination vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3


-- Using Common Table Expression (CTE) Methods to calculated percentage of the population that are fully vaccinated
WITH PopvsFullyVac (continent, location, date, population, people_fully_vaccinated, RollingPeopleFullyVaccinated)
AS (
SELECT dea.continent,
	   dea.location,
	   dea.date,
	   dea.population,
	   vac.people_fully_vaccinated,
	   SUM(CAST(people_fully_vaccinated AS FLOAT)) 
			OVER (PARTITION BY dea.location
			ORDER BY dea.location,
			dea.date) AS RollingPeopleFullyVaccinated
	FROM Covid.dbo.CovidDeath dea
	JOIN Covid.dbo.CovidVaccination vac
		ON dea.location = vac.location
		AND dea.date = vac.date
	WHERE dea.continent IS NOT NULL
)
SELECT *, (RollingPeopleFullyVaccinated/population)*100 AS PercentFullyVaccinated
FROM PopvsFullyVac
WHERE RollingPeopleFullyVaccinated IS NOT NULL
	  AND people_fully_vaccinated IS NOT NULL;


-- Utilizing Temp Table method to calculate percentage of population that are vaccinated
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
data datetime,
population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent,
	   dea.location,
	   dea.date,
	   dea.population,
	   vac.new_vaccinations,
	   SUM(CAST(new_vaccinations AS FLOAT))
			OVER (PARTITION BY dea.location
			ORDER BY dea.location,
			dea.date) AS RollingPeopleVaccinated
FROM Covid.dbo.CovidDeath dea
	JOIN Covid.dbo.CovidVaccination vac
		ON dea.location = vac.location
		AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

SELECT *,
	   (RollingPeopleVaccinated/population) * 100 AS PercentVaccinated
FROM #PercentPopulationVaccinated
WHERE RollingPeopleVaccinated IS NOT NULL
	  AND new_vaccinations IS NOT NULL
ORDER BY 1,2


-- Creating View to store data for later visualizations
CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent,
	   dea.location,
	   dea.date,
	   dea.population,
	   vac.new_vaccinations,
	   SUM(CAST(new_vaccinations AS FLOAT)) 
			OVER (PARTITION BY dea.location
			ORDER BY dea.location,
			dea.date) AS RollingPeopleVaccinated
FROM Covid.dbo.CovidDeath dea
	JOIN Covid.dbo.CovidVaccination vac
		ON dea.location = vac.location
		AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT DISTINCT continent
FROM covid.dbo.CovidDeath