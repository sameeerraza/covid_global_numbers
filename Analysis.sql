
SELECT *
FROM project_1..covid_death
ORDER BY 3,4

SELECT *
FROM project_1..covid_vaccinations
ORDER BY 3,4

SELECT location, date, total_cases, 
	   new_cases, total_deaths, population
FROM project_1..covid_death
ORDER BY 1,2


-- looking at total cases vs. total deaths

SELECT location, date, total_cases, total_deaths, 
	   (total_deaths / total_cases) * 100 AS death_percentage
FROM project_1..covid_death
--WHERE location = 'Pakistan'
ORDER BY 1,2


-- total cases vs. population
-- shows what percantage of population got covid

SELECT location, date, total_cases, population, 
	   (total_cases / population) * 100 AS percentpopulationinfected
FROM project_1..covid_death
-- WHERE location = 'Pakistan'
ORDER BY 1,2


-- looking at countries with highest infection rate compare to population
-- TABLE 3

SELECT location, population, 
	   MAX(total_cases) AS highest_infection_count, 
	   MAX((total_cases / population)) * 100 AS percent_population_infected
FROM project_1..covid_death
GROUP BY location, population
ORDER BY percent_population_infected desc

-- TABLE 4

SELECT location, population, date,
	   MAX(total_cases) AS highest_infection_count, 
	   MAX((total_cases / population)) * 100 AS percent_population_infected
FROM project_1..covid_death
GROUP BY location, population, date
ORDER BY percent_population_infected desc


-- showing countries with highest death count per population
-- TABLE 2

SELECT location, SUM(CAST(new_deaths as bigint)) AS total_death_count 
FROM project_1..covid_death
WHERE continent IS NULL
AND location NOT IN ('World', 'European Union', 'International',
                     'High income', 'Upper middle income', 'Lower middle income',
					 'Low income')
GROUP BY location
ORDER BY total_death_count desc


-- lets break things down by continent
-- showing continents with highest death count per population

SELECT continent, 
	   MAX(CAST(total_deaths as int)) AS total_death_count 
FROM project_1..covid_death
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY total_death_count desc


-- global numbers
--TABLE 1

SELECT SUM(new_cases) AS total_new_cases,
	   SUM(CAST(new_deaths as bigint)) AS total_deaths,
	   SUM(CAST(new_deaths AS bigint)) / SUM(new_cases) * 100 AS death_percentage
FROM project_1..covid_death
WHERE continent IS NOT NULL
ORDER BY 1,2


-- total population vs. vaccinations

SELECT dea.continent, dea.location, dea.date, dea.population, 
	   vac.new_vaccinations,
	   SUM(CONVERT(bigint, vac.new_vaccinations)) 
			OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM project_1..covid_death dea
JOIN project_1..covid_vaccinations vac
	ON dea.location = vac.location
	   AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2, 3

-- using CTE

WITH pop_vs_vac (continent, location, date, population, new_vaccinations, rolling_people_vaccinated) AS
(
SELECT dea.continent, dea.location, dea.date, 
	   dea.population, vac.new_vaccinations,
	   SUM(CONVERT(bigint, vac.new_vaccinations)) 
			OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM project_1..covid_death dea
JOIN project_1..covid_vaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
SELECT *, (rolling_people_vaccinated / population) * 100
FROM pop_vs_vac



-- TEMP TABLE

DROP TABLE IF EXISTS #percentpopulationvaccinated
CREATE TABLE #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population bigint,
new_vaccinations bigint,
rolling_people_vaccinated bigint
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, 
	   dea.population, vac.new_vaccinations,
	   SUM(CONVERT(bigint, vac.new_vaccinations)) 
			OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM project_1..covid_death dea
JOIN project_1..covid_vaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT *, (rolling_people_vaccinated / population) * 100
FROM #PercentPopulationVaccinated

-- creating view to store data for visualizations

CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, 
	   dea.population, vac.new_vaccinations,
	   SUM(CONVERT(bigint, vac.new_vaccinations)) 
			OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM project_1..covid_death dea
JOIN project_1..covid_vaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT *
FROM PercentPopulationVaccinated
