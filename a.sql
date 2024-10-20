--SELECT * FROM ['Covid Deaths$'] ;

--SELECT * FROM ['Covid Vaccinations$'] ;

--SELECT * FROM CovidDiseases ;

SELECT
    Location,
    date,
    total_cases,
    new_cases,
    total_deaths,
    population
FROM ['Covid Deaths$']
WHERE continent IS NOT NULL;


-- Comparison of Total Diagnosed Cases to Total Deaths
-- Demonstrates the Mortality Rate per Country in the Event of Infection

SELECT
    Location,
    date,
    total_cases,
    total_deaths,
    CAST(total_deaths AS float) / CAST(total_cases AS float) AS DeathPercentage
FROM ['Covid Deaths$'];

--
SELECT 
    Location, 
    date, 
    total_cases, 
    total_deaths,  
    (CAST(total_deaths AS float) / CAST(total_cases AS float)) * 100 AS DeathPercentage
FROM ['Covid Deaths$']
--WHERE location LIKE '%africa%'


-- Analysis of Total COVID-19 Cases vs. Population
-- Illustrates the Percentage of Population Infected with COVID-19

SELECT 
    Location, 
    date, 
    total_cases, 
    population, 
    (CAST(total_cases AS float) / CAST(population AS float)) * 100 AS InfectedPopulationPercentage
FROM ['Covid Deaths$']
-- WHERE location like '%africa%'

-- Countries with the Highest Infection Rate Relative to Population

SELECT 
    Location, 
    Population, 
    MAX(total_cases) as HighestInfectionCount,  
    MAX((CAST(total_cases AS float) / CAST(population AS float)) * 100) AS InfectedPopulationPercentage
FROM ['Covid Deaths$']
GROUP BY Location, Population
ORDER BY InfectedPopulationPercentage desc


-- Countries with the Highest Death Count per Population

SELECT 
    Location,  
    MAX(CAST(total_deaths AS int)) AS TotalDeathCount
FROM ['Covid Deaths$']
GROUP BY Location
ORDER BY TotalDeathCount desc

-- Analysis by Continent: Identifying Continents with the Highest Death Count per Population

SELECT 
    continent,  
    MAX(CAST(total_deaths AS int)) AS TotalDeathCount
FROM ['Covid Deaths$']
GROUP BY continent
ORDER BY TotalDeathCount desc

-- Global COVID-19 Statistics
-- Calculate the total COVID-19 cases per location and date
SELECT
    Location,
    Date,
    SUM(new_cases) AS TotalCovidCases
FROM ['Covid Deaths$']
WHERE continent IS NOT NULL
GROUP BY Location, Date
ORDER BY Location, Date;

-- Calculate the total cardiovascular deaths per location and date
SELECT
    Location,
    Date,
    SUM(cardiovasc_death_rate) AS TotalCardioDeaths
FROM CovidDiseases
GROUP BY Location, Date
ORDER BY Location, Date;

-- Calculate the average diabetes prevalence per location and date
SELECT
    Location,
    Date,
    AVG(diabetes_prevalence) AS AvgDiabetesPrevalence
FROM CovidDiseases
GROUP BY Location, Date
ORDER BY Location, Date;

-- Calculate the correlation between COVID-19 cases and cardiovascular deaths
-- Calculate the correlation between COVID-19 cases and cardiovascular deaths
SELECT
    CORRELATION(new_cases, cardiovasc_death_rate) AS CasesCardioCorrelation
FROM ['Covid Deaths$']
WHERE continent IS NOT NULL;

-- Calculate the correlation between COVID-19 cases and diabetes prevalence
SELECT
    CORRELATION(new_cases, diabetes_prevalence) AS CasesDiabetesCorrelation
FROM ['Covid Deaths$']
WHERE continent IS NOT NULL;

-- Calculate the correlation between COVID-19 deaths and cardiovascular deaths
SELECT
    CORRELATION(new_deaths, cardiovasc_death_rate) AS DeathsCardioCorrelation
FROM ['Covid Deaths$']
WHERE continent IS NOT NULL;

-- Calculate the correlation between COVID-19 deaths and diabetes prevalence
SELECT
    CORRELATION(new_deaths, diabetes_prevalence) AS DeathsDiabetesCorrelation
FROM ['Covid Deaths$']
WHERE continent IS NOT NULL;




-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

SELECT
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated,
    (SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) / dea.population) * 100 AS VaccinationPercentage
FROM ['Covid Deaths$'] dea
JOIN ['Covid Vaccinations$'] vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;



-- COVID-19 Vaccination Statistics with Rolling Vaccination Percentage

WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated, VaccinationPercentage)
AS
(
    SELECT
        dea.continent,
        dea.location,
        dea.date,
        dea.population,
        vac.new_vaccinations,
        SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated,
        (SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) / dea.population) * 100 AS VaccinationPercentage
    FROM PortfolioProject..CovidDeaths dea
    JOIN PortfolioProject..CovidVaccinations vac
        ON dea.location = vac.location
        AND dea.date = vac.date
    WHERE dea.continent IS NOT NULL
)
SELECT *
FROM PopvsVac;


-- COVID-19 Vaccination Statistics with Rolling Vaccination Percentage Using Temp Table

-- Drop the temporary table if it exists
DROP TABLE IF EXISTS #PercentPopulationVaccinated;

-- Create the temporary table
CREATE TABLE #PercentPopulationVaccinated
(
    Continent NVARCHAR(255),
    Location NVARCHAR(255),
    Date DATETIME,
    Population NUMERIC,
    New_vaccinations NUMERIC,
    RollingPeopleVaccinated NUMERIC
);

-- Insert data into the temporary table
INSERT INTO #PercentPopulationVaccinated
SELECT
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date;

-- Calculate and retrieve the percentage of the population vaccinated
SELECT *, (RollingPeopleVaccinated / Population) * 100 AS VaccinationPercentage
FROM #PercentPopulationVaccinated;


-- Creating a View to Store Data for Vaccination Visualization

-- Create the view
CREATE VIEW PercentPopulationVaccinated AS
SELECT
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;



-- Global COVID-19 Statistics
-- Calculate the total COVID-19 cases per location and date
SELECT
    Location,
    Date,
    SUM(new_cases) AS TotalCovidCases
FROM ['Covid Deaths$']
WHERE continent IS NOT NULL
GROUP BY Location, Date
ORDER BY Location, Date;

-- Calculate the total cardiovascular deaths per location and date
SELECT
    Location,
    Date,
    SUM(cardiovasc_death_rate) AS TotalCardioDeaths
FROM CovidDiseases
GROUP BY Location, Date
ORDER BY Location, Date;

-- Calculate the average diabetes prevalence per location and date
SELECT
    Location,
    Date,
    AVG(diabetes_prevalence) AS AvgDiabetesPrevalence
FROM CovidDiseases
GROUP BY Location, Date
ORDER BY Location, Date;

-- Calculate the correlation between COVID-19 cases and cardiovascular deaths
-- Calculate the correlation between COVID-19 cases and cardiovascular deaths
SELECT
    CORRELATION(new_cases, cardiovasc_death_rate) AS CasesCardioCorrelation
FROM ['Covid Deaths$']
WHERE continent IS NOT NULL;

-- Calculate the correlation between COVID-19 cases and diabetes prevalence
SELECT
    CORRELATION(new_cases, diabetes_prevalence) AS CasesDiabetesCorrelation
FROM ['Covid Deaths$']
WHERE continent IS NOT NULL;

-- Calculate the correlation between COVID-19 deaths and cardiovascular deaths
SELECT
    CORRELATION(new_deaths, cardiovasc_death_rate) AS DeathsCardioCorrelation
FROM ['Covid Deaths$']
WHERE continent IS NOT NULL;

-- Calculate the correlation between COVID-19 deaths and diabetes prevalence
SELECT
    CORRELATION(new_deaths, diabetes_prevalence) AS DeathsDiabetesCorrelation
FROM ['Covid Deaths$']
WHERE continent IS NOT NULL;

