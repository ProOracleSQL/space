---------------------------------------------------------------------------
-- REDO
---------------------------------------------------------------------------

--Cumulative redo data genearated by this session, in megabytes.
select to_char(round(value/1024/1024, 1), '999,990.0') mb
from v$mystat
join v$statname
	on v$mystat.statistic# = v$statname.statistic#
where v$statname.name = 'redo size';

--Create an empty table.  +0.0 megabytes.
create table launch_redo as
select * from launch where 1=0;

--Insert data.  +7.0 megabytes.
insert into launch_redo select * from launch;
commit;

--Delete data.  +24.6 megabytes.
delete from launch_redo;

--Rollback the delete.  +21.5 megabytes.
rollback;


--Direct-path insert.  +0.0 megabytes.
alter table launch_redo nologging;
insert /*+ append */ into launch_redo select * from launch;
commit;

--Truncate new table.  +0.1 megabytes.
--truncate table launch_redo;



---------------------------------------------------------------------------
-- UNDO
---------------------------------------------------------------------------

--Cumulative undo genearated by this session, in megabytes.
select to_char(round(value/1024/1024, 1), '999,990.0') mb
from v$mystat
join v$statname
	on v$mystat.statistic# = v$statname.statistic#
where v$statname.name = 'undo change vector size';


--Test case to measure undo.
--Create an empty table.  +0.0 megabytes.
create table launch_undo as
select * from launch where 1=0;

--Insert data.  +0.3 megabytes.
insert into launch_undo select * from launch;
commit;

--Delete data.  +13.9 megabytes.
delete from launch_undo;

--Rollback the delete.  +0.0 megabytes.
rollback;

--Direct-path insert.  +0.0 megabytes.
alter table launch_undo nologging;
insert /*+ append */ into launch_undo select * from launch;
commit;

--Truncate new table.  +0.1 megabytes.
--truncate table launch_undo;


--System Change Number (SCN) example.
select norad_id, ora_rowscn
from satellite
order by norad_id
fetch first 3 rows only;



---------------------------------------------------------------------------
-- Storage Structures
---------------------------------------------------------------------------

--Who is blocking a session.
select final_blocking_session, v$session.*
from v$session
where final_blocking_session is not null
order by v$session.final_blocking_session;


--Purge recycle bin
purge user_recyclebin;
purge dba_recyclebin;


--Add data file.
alter tablespace my_tablespace add datafile 'C:\APP\...\FILE_X.DBF'
size 100m
autoextend on
next 100m
maxsize unlimited;



---------------------------------------------------------------------------
-- Cache
---------------------------------------------------------------------------

--Buffer cache hit ratio.
select 1 - (physical_reads / (consistent_gets + db_block_gets)) ratio
from (select name, value from v$sysstat)
pivot
(
	sum(value)
	for (name) in
	(
		'physical reads cache' physical_reads,
		'consistent gets from cache' consistent_gets,
		'db block gets from cache' db_block_gets
	)
);