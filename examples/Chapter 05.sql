---------------------------------------------------------------------------
-- Operating Systems and Supporting Programs
---------------------------------------------------------------------------

--Drop the test tables if they already exist.
--drop table test1;
--drop table test2;

create table test1 as select 1 a from dual;
create table test2 pctfree 0 as select 1 a from dual;
select dbms_metadata.get_ddl('TABLE', 'TEST1') from dual;
select dbms_metadata.get_ddl('TABLE', 'TEST2') from dual;



---------------------------------------------------------------------------
-- When we should not use SQL*Plus
---------------------------------------------------------------------------

--Run this statement in SQL*Plus and an IDE.
select * from v$sql where rownum = 1;
