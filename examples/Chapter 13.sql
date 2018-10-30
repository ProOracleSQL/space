---------------------------------------------------------------------------
-- Write Beautiful SQL Statements
---------------------------------------------------------------------------


--My preferred SQL programming style.
--Organizations with the most orbital and deep space launches.
select organization.org_name, count(*) launch_count
from launch
join launch_agency
	on launch.launch_id = launch_agency.launch_id
join organization
	on launch_agency.agency_org_code = organization.org_code
where launch_category in ('deep space', 'orbital')
group by agency_org_code, org_name
order by count(*) desc;


--Traditional SQL programming style.
--Organizations with the most orbital and deep space launches.
SELECT o.org_name, COUNT(*) launch_count
  FROM launch l, launch_agency la, organization o
 WHERE l.launch_id = la.launch_id
   AND la.agency_org_code = o.org_code
   AND l.launch_category IN ('deep space', 'orbital')
 GROUP BY la.agency_org_code, o.org_name
 ORDER BY COUNT(*) DESC;



---------------------------------------------------------------------------
-- Avoid Unnecessary Aliases
---------------------------------------------------------------------------

--Without alias.
select launch.launch_date from launch;

--With alias.
select l.launch_date from launch l;



---------------------------------------------------------------------------
-- Prefixes
---------------------------------------------------------------------------

--Four ways to run the same query.
select launch_date from launch;
select launch.launch_date from launch;
select launch.launch_date from space.launch;
select space.launch.launch_date from space.launch;


--Default to the SPACE schema.
alter session set current_schema=space;


--Abbreviated.  (This code does not work.)
select * from lnch;

--Not abbreviated.
select * from launch;



---------------------------------------------------------------------------
-- Use Tabs for Left Alignment
---------------------------------------------------------------------------


--Left-aligned.
select *
from dual;

--Right-aligned with spaces.
SELECT *
  FROM dual;



---------------------------------------------------------------------------
-- Avoid Code Formatters
---------------------------------------------------------------------------

--Use space to highlight what's important.
select
	a,b,c,d,e,f,g,h,i,j,k,l,m,
	n+1 n,
	o,p,q,r,s,t,u,v,w,x,y,z
from some_table;
