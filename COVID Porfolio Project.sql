--COVID DEATHS DATA CLEANING

SELECT *
FROM PorfolioProject..CovidDeaths
ORDER BY 3,4

SELECT *
FROM PorfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3,4

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PorfolioProject..CovidDeaths
ORDER BY 1,2


--LOOKING AT TOTAL CASES VS TOTAL DEATHS

--The likelihood of dying if you contract Covid in the Philippines:
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS death_percentage
FROM PorfolioProject..CovidDeaths
WHERE location = 'Philippines'
ORDER BY 2


--LOOKING AT TOTAL CASES VS POPULATION

--Percentage of population that had Covid in the Philippines
SELECT location, date, total_cases, population, (total_cases/population)*100 AS cases_percentage
FROM PorfolioProject..CovidDeaths
WHERE location = 'Philippines'
ORDER BY 2


--Top 10 countries with highest infection rate compared to population
SELECT TOP 10 location, population, MAX(total_cases) AS highest_infection_count, MAX((total_cases/population)*100) AS percent_population_infected
FROM PorfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY percent_population_infected DESC 

--Top 10 countries with highest death count per population
SELECT TOP 10 location, MAX(CAST(total_deaths AS INT)) AS highest_death_count
FROM PorfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY highest_death_count DESC 


--BREAKING DOWN BY CONTINENT

--Continents with the highest death count per population
SELECT continent, MAX(CAST(total_deaths as int)) as highest_death_count
FROM PorfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY highest_death_count DESC

--The right actualy breakdown
SELECT location, MAX(CAST(total_deaths as int)) as highest_death_count
FROM PorfolioProject..CovidDeaths
WHERE continent IS NULL
GROUP BY location
ORDER BY highest_death_count DESC


--LOOKING AT GLOBAL NUMBERS

SELECT SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS INT)) as total_deaths, SUM(CAST(new_deaths AS INT))/SUM(new_cases)*100 AS death_percentage
FROM PorfolioProject..CovidDeaths
WHERE continent IS NOT NULL
--GROUP BY date
ORDER BY 1,2



---WITH COVID CONTINENTS DATA

SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vac.new_vaccinations
FROM PorfolioProject..CovidDeaths deaths
JOIN PorfolioProject..CovidVaccinations vac
	ON deaths.location = vac.location
	AND deaths.date = vac.date
WHERE deaths.continent IS NOT NULL
ORDER BY 1,2,3

SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vac.new_vaccinations, SUM(CONVERT(INT,vac.new_vaccinations)) OVER (Partition by deaths.location ORDER BY deaths.location, deaths.date) AS rolling_people_vaccinated
FROM PorfolioProject..CovidDeaths deaths
JOIN PorfolioProject..CovidVaccinations vac
	ON deaths.location = vac.location
	AND deaths.date = vac.date
WHERE deaths.continent IS NOT NULL
ORDER BY 1,2,3

--use as CTE 
WITH PopvsVac(continent, location, date, population, new_vaccinations, rolling_people_vaccinated)
AS
(
SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vac.new_vaccinations, SUM(CONVERT(INT,vac.new_vaccinations)) OVER (Partition by deaths.location ORDER BY deaths.location, deaths.date) AS rolling_people_vaccinated
FROM PorfolioProject..CovidDeaths deaths
JOIN PorfolioProject..CovidVaccinations vac
	ON deaths.location = vac.location
	AND deaths.date = vac.date
WHERE deaths.continent IS NOT NULL
)
SELECT *, (rolling_people_vaccinated/population)*100 as rolling_percentage
FROM PopvsVac

--CREATING VIEW TO STORE DATA FOR LATER VISUALIZATION

CREATE VIEW PercentPopulationVaccinated AS
SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vac.new_vaccinations, SUM(CONVERT(INT,vac.new_vaccinations)) OVER (Partition by deaths.location ORDER BY deaths.location, deaths.date) AS rolling_people_vaccinated
FROM PorfolioProject..CovidDeaths deaths
JOIN PorfolioProject..CovidVaccinations vac
	ON deaths.location = vac.location
	AND deaths.date = vac.date
WHERE deaths.continent IS NOT NULL

