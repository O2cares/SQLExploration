-- Data was injested from Our World in Data website
--This exploration is to make a global analysis of Covid-19 impact on the world 
-- Using a sampling method,focus will be on 18 countries with high population density across 6 continents
-- Africa; Nigeria, South Africa and Egypt
-- Asia; China, India and indonesia
-- Europe; Germany, France and United Kingdom
-- North America; USA, Canada and Mexico
-- South America; Brazil, Argentina and Colombia

select * 
from [dbo].[CovidDeaths]
where continent is not null
order by 2,3,4 asc

select * 
from [dbo].[SampleCovidDeaths]
where continent is not null
order by 2,3,4 asc

--alter table [dbo].[SampleCovidDeaths]
--alter column [total_cases] float

--alter table [dbo].[SampleCovidDeaths]
--alter column [total_deaths] float

--To know the case fatality rate of Covid-19
--What it means: A case fatality rate tells you how severe a disease is. It also measures how effective treatments are, on average.
select continent, location, date, population, total_cases, total_deaths, (total_deaths / total_cases) * 100 AS CaseFatalityRate
from [dbo].[SampleCovidDeaths]
where continent is not null
--where location like 'c%a'
--and continent is not null
order by 4 desc

-- To know how much the disease is spreading, relative to the total population
-- Take the number of Total new cases divided by the number of people who live in the country.
select continent, location, population, new_cases, total_cases/population * 100 AS NewCasesPerPopulation
from [dbo].[SampleCovidDeaths]
where continent is not null
--where location like 'a%'
--and continent is not null
group by continent, location, population, new_cases, total_cases
order by 3 desc

--Considering the Total Cases Reported against Total Deaths Recorded
-- Represened in percentage to show the likelihood of dying if you contract covid. 
select location, date, total_cases, total_deaths,(total_deaths/ total_cases) * 100 AS DeathPercentage
from [dbo].[SampleCovidDeaths]
where location like '%ia'
and continent is not null
order by 1,2

--Cosidering the Total Cases Vs Population
--Indicate the Percentage of the Population that was infected
select location, Population, total_cases, (total_cases / Population) * 100 AS InfectionPercentage
from [dbo].[SampleCovidDeaths]
where continent is not null
order by 1,2

-- Considering Countries whose population is most infected 
-- To show the chances of getting infected if visited 
select location, Population, MAX(total_cases) as MostInfectedCount, 
Max(total_cases)/ Population * 100 AS PopulationInfectedPercentage
from [dbo].[SampleCovidDeaths]
where continent is not null
Group by location, population
order by 3 desc

--Countries with the Highest death count per population
select Location, Max(total_deaths)AS TotalDeathCount, Population
from [dbo].[SampleCovidDeaths]
where continent is not null
Group by location, population
order by 2 desc

-- A quick look at the continent 
-- Continent with the Highest Death Count
select continent, sum(new_deaths) AS TotalDeathCount
from [dbo].[SampleCovidDeaths]
where continent is not null
Group by continent
order by 2 desc

--Global numeric view of daily reported cases
Select date, sum(new_cases)	as TotalNewCases
from [dbo].[SampleCovidDeaths]
where continent is not null
Group by date
order by 1,2

--the global daily death percentage reported 
Select date, 
sum(new_cases)	as TotalNewCases, 
sum(new_deaths) as TotalDeaths,
sum(new_deaths)/NULLIF(sum(new_cases),0)* 100 as DeathPercentage
from [dbo].[SampleCovidDeaths]
where continent is null
and new_cases <> 0
Group by date
order by 1,2

--Global Current Death Percentage
Select 
sum(new_cases)	as TotalNewCases, 
sum(new_deaths) as TotalDeaths,
sum(new_deaths)/NULLIF(sum(new_cases),0)* 100 as DeathPercentage
from [dbo].[SampleCovidDeaths]
where continent is not null
--and new_cases <> 0
--Group by date
order by 1,2

--The Total amount of people in the world that is Vaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
from [dbo].[SampleCovidDeaths] dea
join [dbo].[SampleCovidVaccinations] vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3 

--Daily cummulation of new vaccination dispensed on location based
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(convert(bigint, vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) 
as RollingPeopleVaccinated
from  [dbo].[SampleCovidDeaths] dea
join [dbo].[SampleCovidVaccinations] vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
and vac.new_vaccinations is not null
order by 2,3

-- Using CTE to know the percentage of people vaccinated per population of the country

With PopVsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(convert(bigint, vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) 
as RollingPeopleVaccinated
from [dbo].[SampleCovidDeaths] dea
join [dbo].[SampleCovidVaccinations] vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
and vac.new_vaccinations is not null
)
select *, (RollingPeopleVaccinated/Population) * 100 as PopulationVaccinatedPercentage
from PopVsVac;

--Using Temp Table #PercentofPopulationVaccinated
Drop Table if exists #PercentofPopulationVaccinated
Create Table #PercentofPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccination numeric,
RollingPeopleVaccinated numeric
)

insert into #PercentofPopulationVaccinated
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(convert(bigint, vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) 
as RollingPeopleVaccinated
from [dbo].[SampleCovidDeaths] dea
join [dbo].[SampleCovidVaccinations] vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null

select *, (RollingPeopleVaccinated/Population) * 100 as PopulationVaccinatedPercentage
from #PercentofPopulationVaccinated;

--To have a view of Total Death Count by Continent 
Create view 
PopulationVaccinatedPercentage as
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(convert(bigint, vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) 
as RollingPeopleVaccinated
from [dbo].[SampleCovidDeaths] dea
join [dbo].[SampleCovidVaccinations] vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null

