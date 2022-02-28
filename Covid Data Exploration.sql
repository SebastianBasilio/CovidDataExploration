use PortfolioProject;

SELECT * FROM ['CovidDeaths']
order BY 3,4

SELECT * FROM ['CovidVaccines']
order BY 3,4

--Selecciono la data que usaré inicialmente para la exploración
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM ['CovidDeaths']
ORDER BY 1,2

-- Comparación de Total de casos VS Total de muertes en Perú
-- Muestra el % de mortalidad por país
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM ['CovidDeaths']
WHERE location like '%peru%'
ORDER BY 1,2

-- Compración de Total de casos VS Población en Perú
-- Muestra la cantidad de casos acorde a la población
SELECT location, date, population, total_cases, (total_cases/population)*100 as InfecctionPercentage
FROM ['CovidDeaths']
WHERE location like '%peru%'
ORDER BY 1,2

-- Los paises con el mayor porcentaje de infección respecto a su población
SELECT location, population, max(total_cases) as HighestInfecctionCount, MAX((total_cases/population))*100 as InfecctionPercentage
FROM ['CovidDeaths']
where continent is not null
group by location, population
ORDER BY 4 DESC

-- Los paises con la mayor cantidad de defunciones
SELECT location, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM ['CovidDeaths']
where continent is not null
group by location
ORDER BY 2 DESC

-- Cantidad de defunciones por continente / clase social
SELECT location, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM ['CovidDeaths']
where continent is null
group by location
ORDER BY 2 DESC

-- Estadisticas globales por día
SELECT date, sum(new_cases) AS total_cases, sum(cast(new_deaths as int)) as total_deaths, 
	sum(cast(new_deaths as int))/sum(new_cases)*100 as DeathPercentage
FROM ['CovidDeaths']
where continent is not null
group by date
order by 1

-- Muestras de Población VS Vacunación
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
FROM ['CovidDeaths'] dea
JOIN ['CovidVaccines'] vac
	on dea.location=vac.location AND dea.date=vac.date
where dea.continent is not null
order by 1,2,3

-- Primera fecha de vacunación por país y cuantas vacunas se aplicaron ese día
select a.*, b.new_vaccinations
from
	(select dea.continent, dea.location, min(dea.date) as FirstVaccinationDate
	FROM ['CovidDeaths'] dea
	JOIN ['CovidVaccines'] vac
		on dea.location=vac.location AND dea.date=vac.date
	where dea.continent is not null AND vac.new_vaccinations is not null AND vac.new_vaccinations <>0
	group by dea.continent, dea.location) a
join ['CovidVaccines'] b
	on a.location=b.location AND a.FirstVaccinationDate=b.date
order by FirstVaccinationDate

-- Ritmo de Vacunacion por País
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	sum(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition BY dea.location Order By dea.date) as TotalVaccines
FROM ['CovidDeaths'] dea
JOIN ['CovidVaccines'] vac
	on dea.location=vac.location AND dea.date=vac.date
where dea.continent is not null
order by 1,2

-- Uso de CTE
WITH PopVsVacc (continet, location,date, population,new_vaccinations, TotalVaccines)
as(
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	sum(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition BY dea.location Order By dea.date) as TotalVaccines
FROM ['CovidDeaths'] dea
JOIN ['CovidVaccines'] vac
	on dea.location=vac.location AND dea.date=vac.date
where dea.continent is not null
)

--Porcentaje de población vacunada a la fecha 
--El porcentaje llega a ser mayor al 100% debido a que a la fecha se han aplicado hasta 2 o 3 dosis por persona 
select *, TotalVaccines/population*100 as PercentegePopVaccinated from PopVsVacc
--WHERE location like '%peru%'

--TEMP Table
DROP TABLE if exists #PercentPopulationVaccinated
Create table #PercentPopulationVaccinated
(Continent nvarchar(255),
location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
TotalVaccines numeric)

Insert into #PercentPopulationVaccinated
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	sum(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition BY dea.location Order By dea.date) as TotalVaccines
FROM ['CovidDeaths'] dea
JOIN ['CovidVaccines'] vac
	on dea.location=vac.location AND dea.date=vac.date
where dea.continent is not null

select *, TotalVaccines/population*100 as PercentegePopVaccinated from #PercentPopulationVaccinated

--Creando un View
CREATE VIEW PercentPopulationVaccinated AS
(select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	sum(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition BY dea.location Order By dea.date) as TotalVaccines
FROM ['CovidDeaths'] dea
JOIN ['CovidVaccines'] vac
	on dea.location=vac.location AND dea.date=vac.date
where dea.continent is not null)
