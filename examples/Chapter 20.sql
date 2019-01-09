---------------------------------------------------------------------------
-- PL/Scope
---------------------------------------------------------------------------

--Generate identifier information.
alter session set plscope_settings='identifiers:all';

create or replace procedure temp_procedure is
   v_count number;
begin
   select count(*)
   into v_count
   from launch;
end;
/


--Identifiers in the procedure.
select
	lpad(' ', (level-1)*3, ' ') || name name,
	type, usage, line, col
from
(
	select *
	from user_identifiers
	where object_name = 'TEMP_PROCEDURE'
) identifiers
start with usage_context_id = 0
connect by prior usage_id = usage_context_id
order siblings by line, col;



---------------------------------------------------------------------------
-- PLSQL_LEXER
---------------------------------------------------------------------------

--Tokenize a simple SQL statement.
select type, to_char(value) value, line_number, column_number
from plsql_lexer.lex('select*from dual');



---------------------------------------------------------------------------
-- ANTLR
---------------------------------------------------------------------------

/*
1. Follow steps on https://www.antlr.org/index.html to download and setup ANTLR.
2. Download files from here: https://github.com/antlr/grammars-v4/tree/master/plsql
3. Copy files PlSqlBaseLexer.java and PlSqlBaseParser.java from Java to top directory.
4. Run: antlr4 PlSqlLexer.g4
5. Run: antlr4 PlSqlParser.g4
6. Run: javac *.java
7. Run: grun PlSql sql_script -gui
8. When prompted, enter this:
BEGIN
   NULL;
END;
/
^Z
*/

--Text output.
--(NOT SHOWN IN BOOK).
(sql_script (unit_statement (anonymous_block BEGIN (seq_of_statements (statement (null_statement NULL)) ;) END ;)) (sql_plus_command /) <EOF>)
;



---------------------------------------------------------------------------
-- DBMS_SQL
---------------------------------------------------------------------------

--Example of finding column name and value.
declare
	v_cursor integer;
	v_result integer;
	v_value  varchar2(4000);
	v_count  number;
	v_cols   dbms_sql.desc_tab4;
begin
	v_cursor := dbms_sql.open_cursor;
	dbms_sql.parse(v_cursor, 'select * from dual', dbms_sql.native);
	dbms_sql.describe_columns3(v_cursor, v_count, v_cols);
	dbms_sql.define_column(v_cursor, 1, v_value, 4000);
	v_result := dbms_sql.execute_and_fetch(v_cursor); 
	dbms_sql.column_value(v_cursor, 1, v_value);
	dbms_sql.close_cursor(v_cursor);
	dbms_output.put_line(v_cols(1).col_name||':'||v_value);
end;
/



---------------------------------------------------------------------------
-- DBMS_XMLGEN
---------------------------------------------------------------------------

--Simple XML result from DBMS_XMLGEN.GETXML.
select xmltype(dbms_xmlgen.getxml('select * from dual')) result
from dual;


--Number of rows in all LAUNCH* tables in SPACE schema.
--Convert XML to columns.
select
	table_name,
	to_number(extractvalue(xml, '/ROWSET/ROW/COUNT')) count
from
(
	--Get results as XML.
	select table_name,
		xmltype(dbms_xmlgen.getxml(
			'select count(*) count from '||table_name
		)) xml
	from all_tables
	where owner = 'SPACE'
		and table_name like 'LAUNCH%'
)
order by table_name;

TABLE_NAME           COUNT
------------------   -----
LAUNCH               70535
LAUNCH_AGENCY        71884
LAUNCH_PAYLOAD_ORG   21214
...



---------------------------------------------------------------------------
-- PL/SQL Common Table Expressions
---------------------------------------------------------------------------

--Number of rows in all LAUNCH* tables in SPACE schema.
with function get_rows(p_table varchar2) return varchar2 is
	v_number number;
begin
	execute immediate 'select count(*) from '||p_table
	into v_number;

	return v_number;
end;
select table_name, get_rows(table_name) count
from all_tables
where owner = 'SPACE'
	and table_name like 'LAUNCH%';
/



---------------------------------------------------------------------------
-- Method4
---------------------------------------------------------------------------

--Method4 dynamic SQL in SQL.
select * from table(method5.method4.dynamic_query(
q'[
	select replace(
		q'!
			select '#TABLE_NAME#' table_name, count(*) count
			from #TABLE_NAME#
		!', '#TABLE_NAME#', table_name) sql_statement
	from all_tables
	where owner = 'SPACE'
		and table_name like 'LAUNCH%'
]'
))
order by table_name;



---------------------------------------------------------------------------
-- Polymorphic Table Functions
---------------------------------------------------------------------------

--Create polymorphic table function package.
create or replace package ptf as
	function describe(p_table in out dbms_tf.table_t)
	return dbms_tf.describe_t;

	function do_nothing(tab in table)
	return table pipelined
	row polymorphic using ptf;
end;
/

create or replace package body ptf as
	function describe(p_table in out dbms_tf.table_t)
	return dbms_tf.describe_t as
	begin
		return null;
	end;
end;
/

--Call polymporhic table function.
select * from ptf.do_nothing(dual);



---------------------------------------------------------------------------
-- Method5
---------------------------------------------------------------------------

select * from table(m5('select * from dual'));
