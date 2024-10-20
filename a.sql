a=int input()
SELECT
    Location,
    date,
    total_cases,
    new_cases,
    total_deaths,
    population
FROM ['Covid Deaths$']
WHERE continent IS NOT NULL;
