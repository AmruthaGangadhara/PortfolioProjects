--select * from PortfolioProject1..coviddeaths
--order by 3,4;

--select * from PortfolioProject1..covidvaccinations
--order by 3,4;

select location,date,total_cases,new_cases,total_deaths,population
from coviddeaths

order by 1,2;

select * from coviddeaths 
where continent is not null;


select location,sum(new_cases) TOTAL_NUM	_CASES,
       sum(total_deaths) TOTAL_NUM_DEATHS
from coviddeaths
group by location
order by 2 desc,3 desc;

/*query to see ratio od deaths to cases for each iso_code:

select iso_code,sum(new_cases) TOTAL_NUM_CASES,sum(new_deaths) TOTAL_NUM_DEATHS,
CASE
WHEN SUM(new_cases)=0 then 0
ELSE (sum(new_deaths))/(sum(new_cases))*100
end ratiodeathtocases
from coviddeaths
GROUP BY ISO_CODE*/


/*select iso_code,sum(new_cases) TOTAL_NUM_CASES,sum(new_deaths) TOTAL_NUM_DEATHS,
CASE
WHEN SUM(new_cases)=0 then 0
ELSE (sum(new_deaths))/(sum(new_cases))*100
end ratioDeathtoCases
from coviddeaths
GROUP BY ISO_CODE
ORDER BY ratioDeathtoCases DESC;*/
/*PRK DATA MIGHT BE WRONG*/

/* query to select ratio of death to case and ordering by location and date*/
/* notes: WE CAN OBSERVE THAT, in India, nearly 1 percent of the people infected died. the olther 99% recovered*/
/* shows the likelihood of dyinmg if you contract covid in your country*/
select location,date,total_cases,total_deaths,
case when total_cases=0 then 0
else (total_deaths/total_cases)*100
end DeathPercentage
from coviddeaths
where location like '%INDIA%' and continent!=''
order by 1,2;


/* LETS LOOK AT TOTAL CASES VS POPULATION in India--> what percentage of population has gotten covid*/

select location,date,total_cases,population,
case when population=0 then 0
else (total_cases/population) *100
end RatioCasesToPopulation
from coviddeaths
where location like '%iNDIA%' and continent!=''

order by 1,2;

/* Looking at countries with highest infection rate*/ /*Cyprus is the higheset*/

select location,population,max(total_cases) HighestInfectedCount,COUNT(*) COUNTROWS,
case when population=0 then 0
else (max(total_cases)/population)*100
end PercentPopulationInfected
from coviddeaths
where continent!=''
group by location,population
order by 5 desc;




/*LOOKING AT highest death count per population*/
select location,max(total_deaths) DeathCount 
from coviddeaths
where continent!=''
group by CONTINENT,location 
order by 2 desc;


/*LOOKING AT highest death count per population(ratio)*/
select location,
case when population=0 then 0
else (max(total_deaths)/population)*100
end DeathtoPopulation
from coviddeaths
where continent!=''
group by location,population
order by 2 desc;

/* NOW LETS BREAK THINGS DOWN BY CONTINENT*/
-- see howmany cases and how many deaths have happened--

select continent,max(total_cases) maxCases,max(total_deaths) maxDeaths, max(total_deaths)/max(total_cases)*100 PercentageofDeath
from coviddeaths
where continent!=''
group by continent
order by 4 desc;

/*LOOKING AT highest death count per population(ratio) split by continent*/
select location Continent1,max(total_deaths) DeathCount 
from coviddeaths
where continent=''
group by location
order by 2 desc;

--SAME QUERY AS ABOVE BUT EXCLUDING INCOME GROUPS
select location Continent1,max(total_deaths) DeathCount 
from coviddeaths
where continent='' AND LOCATION NOT IN ('High income','International','Low income','Lower middle income','Upper middle income','World')
group by location
order by 2 desc;




--Number of deaths split by continent -- create view for this
select continent, max(total_deaths) DeathCount
from coviddeaths where continent!=''
group by continent order by 2 desc;

select continent, max(total_deaths) DeathCount,max(Total_cases) TotalCases,
max(total_deaths)/max(Total_cases) * 100 DeathToCases
from coviddeaths where continent!=''
group by continent order by 3 desc;



-- work on date cut
select continent,max(total_deaths) deathcount
from coviddeaths
where continent !=''
group by continent;

--work on date cut
select continent,date,total_cases from coviddeaths
where total_cases in (select ,max(total_cases) from coviddeaths
                   where continent!=''
                   group by continent);


--GLOBAL NUMBERS
--LETS LOOK AT TOTAL NUMBER OF CASES AND DEATH TO CASE RATIO ON EACH DAY, WORLDWIDE

select date,sum(new_cases) Cases,sum(new_deaths) Deaths,
case when sum(new_cases)=0 then 0 
else sum(new_deaths)/sum(new_cases) *100
end DeathToCasesRatio
from coviddeaths
where continent!=''
group by date
order by date;

---numbers across the world

select sum(new_cases) Cases,sum(new_deaths) Deaths,
case when sum(new_cases)=0 then 0 
else sum(new_deaths)/sum(new_cases) *100
end DeathToCasesRatio
from coviddeaths
where continent!='';

--- covidvaccinations table

select *
from coviddeaths dea
join covidvaccinations vac on dea.location=vac.location
and dea.date=vac.date;

select dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations
from coviddeaths dea
join covidvaccinations vac on dea.location=vac.location
and dea.date=vac.date
where dea.continent!=''
order by 2,3; 



select dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations, 
sum(vac.new_vaccinations) over (partition by dea.location) rolling_sum
from coviddeaths dea
join covidvaccinations vac on dea.location=vac.location
and dea.date=vac.date
where dea.continent!=''
order by 2,3; 

select dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations, 
sum(vac.new_vaccinations) over (partition by dea.location order by dea.date) RollingPeopleVaccinated 
from coviddeaths dea
join covidvaccinations vac on dea.location=vac.location
and dea.date=vac.date
where dea.continent!=''
order by 2,3; 


--use cte
 
with PopvsVac (continent,location,date,population,new_vaccinations,rolling_vaccination)
as 
( select dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations, 
sum(vac.new_vaccinations) over (partition by dea.location order by dea.date) rolling_vaccination 
from coviddeaths dea
join covidvaccinations vac on dea.location=vac.location
and dea.date=vac.date
where dea.continent!='')
--order by 2,3)
select *,(rolling_vaccination/population) percentageofpeopvaccinated from PopvsVac;

----Creating views to use for visualizations for later usage


create view PercentagePopulationVaccinated
as
select dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations, 
sum(vac.new_vaccinations) over (partition by dea.location order by dea.date) RollingPeopleVaccinated 
from coviddeaths dea
join covidvaccinations vac on dea.location=vac.location
and dea.date=vac.date
where dea.continent!='';
--order by 2,3; 


select * from PercentagePopulationVaccinated;











