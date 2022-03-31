---------------------------------------------------------------------------
-- Create and Save Changes Manually
---------------------------------------------------------------------------

--Create a simple example table.
create table test1 as select 1 a from dual;

--Generate a DDL statement to create the preceding table.
select dbms_metadata.get_ddl('TABLE', 'TEST1') from dual;
