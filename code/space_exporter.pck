create or replace package space_exporter is
	--Drop objects used for the data load.
	--P_TYPE can be one of "staging tables", "staging view", "presentation tables", or "all".
	procedure drop_objects(p_type varchar2);

	procedure generate_oracle_file;

	function get_formatted_string(p_string varchar2) return varchar2;
	function get_formatted_date(p_date date) return varchar2;
	function get_formatted_number(p_number number) return varchar2;
end;
/
create or replace package body space_exporter is

c_version constant varchar2(10) := '1.0.0';

--This list is in an order that could be used to create objets.
--The order matters because of foreign key constraints.
--Use the reverse order to drop them.
g_ordered_objects constant sys.odcivarchar2list := sys.odcivarchar2list
(
	'ORGANIZATION',
	'PLATFORM',
	'ORGANIZATION_ORG_TYPE',
	'SITE',
	'SITE_ORG',
	'LAUNCH_VEHICLE_FAMILY',
	'LAUNCH_VEHICLE',
	'LAUNCH_VEHICLE_MANUFACTURER',
	'LAUNCH',
	'LAUNCH_PAYLOAD_ORG',
	'LAUNCH_AGENCY',
	'SATELLITE',
	'SATELLITE_ORG',
	'ENGINE',
	'STAGE',
	'LAUNCH_VEHICLE_STAGE',
	'STAGE_MANUFACTURER',
	'PROPELLENT',
	'ENGINE_PROPELLENT',
	'ENGINE_MANUFACTURER'
);



--==============================================================================
--==============================================================================
function get_formatted_string(p_string varchar2) return varchar2 is
begin
	return '''' || replace(p_string, '''', '''''') || '''';
end;



--==============================================================================
--==============================================================================
function get_formatted_date(p_date date) return varchar2 is
begin
	return '''' || to_char(p_date, 'YYYY-MM-DD hh24:mi:ss') || '''';
end;



--==============================================================================
--==============================================================================
function get_formatted_number(p_number number) return varchar2 is
begin
	if p_number is null then
		return 'null';
	else
		return to_char(p_number);
	end if;
end;



--==============================================================================
--==============================================================================
procedure drop_objects(p_type varchar2) is
	v_objects sys.odcivarchar2list;

	-------------------
	procedure drop_if_exists(p_object_name varchar2, p_object_type varchar2) is
		v_table_view_does_not_exist exception;
		pragma exception_init(v_table_view_does_not_exist, -942);
	begin
		execute immediate 'drop '||p_object_type||' '||p_object_name;
	exception when v_table_view_does_not_exist then
		null;
	when others then
		raise_application_error(-20000, 'Error with this object: '||p_object_name||chr(10)||
			sys.dbms_utility.format_error_stack||sys.dbms_utility.format_error_backtrace);
	end drop_if_exists;

	-------------------
	procedure drop_staging_tables is
	begin
		v_objects := sys.odcivarchar2list(
			'ENGINE_STAGING', 'FAMILY_STAGING', 'LAUNCH_STAGING', 'LAUNCH_VEHICLE_STAGE_STAGING',
			'LAUNCH_VEHICLE_STAGING', 'ORGANIZATION_STAGING', 'PLATFORM_STAGING',
			'SATELLITE_STAGING', 'SITE_STAGING', 'STAGE_STAGING'
		);

		for i in 1 .. v_objects.count loop
			drop_if_exists(v_objects(i), 'table');
		end loop;
	end;

	-------------------
	procedure drop_staging_views is
	begin
		v_objects := sys.odcivarchar2list(
			'ENGINE_STAGING_VIEW', 'LAUNCH_STAGING_VIEW', 'LAUNCH_VEHICLE_STAGING_VIEW',
			'ORGANIZATION_STAGING_VIEW', 'PLATFORM_STAGING_VIEW', 'SATELLITE_STAGING_VIEW',
			'SITE_STAGING_VIEW', 'STAGE_STAGING_VIEW'
		);

		for i in 1 .. v_objects.count loop
			drop_if_exists(v_objects(i), 'view');
		end loop;
	end;

	-------------------
	procedure drop_presentation_tables is
	begin
		for i in reverse 1 .. g_ordered_objects.count loop
			drop_if_exists(g_ordered_objects(i), 'table');
		end loop;
	end;
begin
	if lower(p_type) in ('all', 'staging tables') then
		drop_staging_tables;
	end if;

	if lower(p_type) in ('all', 'staging views') then
		drop_staging_views;
	end if;

	if lower(p_type) in ('all', 'presentation tables') then
		drop_presentation_tables;
	end if;

	if lower(p_type) is null or lower(p_type) not in ('all', 'staging tables', 'staging views', 'presentation tables') then
		raise_application_error(-20000, 'Invalid entry.  Should be one of: all, '||
			'staging tables, staging views, or presentation tables.');
	end if;

end;



--==============================================================================
--==============================================================================
procedure generate_oracle_file is


	---------------------------------------
	--Return formatted metadata, for use in a load script.
	--(This function is mostly from the DBMS_METADATA chapter of the manual.)
	FUNCTION get_metadata
	(
		p_object_type varchar2,
		p_schema varchar2,
		p_table_name varchar2
	) RETURN CLOB IS
	 -- Define local variables.
	 h    NUMBER;   -- handle returned by 'OPEN'
	 th   NUMBER;   -- handle returned by 'ADD_TRANSFORM'
	 doc  CLOB;
	BEGIN
	 -- Specify the object type. 
	 h := DBMS_METADATA.OPEN(p_object_type);

	 -- Use filters to specify the particular object desired.
	 DBMS_METADATA.SET_FILTER(h,'SCHEMA',p_schema);
	 DBMS_METADATA.SET_FILTER(h,'NAME',p_table_name);

	 -- Request that the metadata be transformed into creation DDL.
	 th := dbms_metadata.add_transform(h,'DDL');

	 -- Don't print schema name.
	 DBMS_METADATA.SET_TRANSFORM_PARAM(th, 'EMIT_SCHEMA', false);

	 -- Specify that segment attributes are not to be returned.
	 -- Note that this call uses the TRANSFORM handle, not the OPEN handle.
	 DBMS_METADATA.SET_TRANSFORM_PARAM(th,'SEGMENT_ATTRIBUTES',false);

	 -- Fetch the object.
	 doc := DBMS_METADATA.FETCH_CLOB(h);

	 -- Release resources.
	 DBMS_METADATA.CLOSE(h);

	 RETURN doc;
	END;


	---------------------------------------
	procedure write_header is
		v_handle utl_file.file_type;
	begin
		v_handle := utl_file.fopen('SPACE_OUTPUT_DIR', 'oracle_create_space.sql', 'w');
		utl_file.put_line(v_handle, replace(replace(replace(substr(
		q'[
				-- This file creates the space schema for Oracle databases.
				-- Version #VERSION#, generated on #DATE#.
				-- DO NOT MODIFY THIS FILE.  It is automatically generated.

				-- Session settings.
				-- Don't prompt for any ampersands:
				set define off;
				-- We don't need to see every message.
				set feedback off;
				-- But we do want to see a few specific messages indicating status.
				set serveroutput on
				-- Use the same date format to make file smaller:
				alter session set nls_date_format = 'YYYY-MM-DD HH24:MI:SS';
				-- Use CHAR semantics for UTF8 data.
				alter session set nls_length_semantics='CHAR';
				

				-- Print intro message.
				exec dbms_output.put_line('------------------------------------------------------------------------');
				exec dbms_output.put_line('-- Installing space database version #VERSION#, generated on #DATE#.');
				exec dbms_output.put_line('-- ');
				exec dbms_output.put_line('-- This data is from JSR Launch Vehicle Database, 2017 Dec 28 Edition.');
				exec dbms_output.put_line('-- This file was generated by Jon Heller, jon@jonheller.org.');
				exec dbms_output.put_line('-- The database installs 20 tables and uses about 27MB of space.');
				exec dbms_output.put_line('--');
				exec dbms_output.put_line('-- The installation will run for about a minute and will stop on any');
				exec dbms_output.put_line('-- errors.  You should see a "done" message at the end.');
				exec dbms_output.put_line('------------------------------------------------------------------------');

				-- Stop at the first error.
				whenever sqlerror exit sql.sqlcode;
				]'
		, 2)
		, '				')
		, '#VERSION#', c_version)
		, '#DATE#', to_char(sysdate, 'YYYY-MM-DD')));

		utl_file.fclose(v_handle);
	end write_header;


	---------------------------------------
	procedure write_check_for_existing_data is
		v_handle utl_file.file_type;
		v_in_list varchar2(32767);
	begin
		v_handle := utl_file.fopen('SPACE_OUTPUT_DIR', 'oracle_create_space.sql', 'a');

		--Create an IN-LIST of all relevant tables.
		for i in 1 .. g_ordered_objects.count loop
			v_in_list := v_in_list || ',' || '''' || g_ordered_objects(i) || '''';
		end loop;
		v_in_list := substr(v_in_list, 2);
		v_in_list := '(' || v_in_list || ')';

		--Print PL/SQL block checking for existing tables.
		utl_file.put_line(v_handle, '--------------------------------------------------------------------------------');
		utl_file.put_line(v_handle, '-- Checking for existing tables.');
		utl_file.put_line(v_handle, '--------------------------------------------------------------------------------');
		utl_file.put_line(v_handle, 'exec dbms_output.put_line(''Checking for existing tables...'');');
		utl_file.put_line(v_handle, replace(replace(q'[
			--Raise an error and stop installation if any tables exist.
			declare
				v_tables_already_exist varchar2(32767);
			begin
				select listagg(table_name, ',') within group (order by table_name)
				into v_tables_already_exist
				from all_tables
				where owner = sys_context('userenv', 'CURRENT_SCHEMA')
					and table_name in ]' || v_in_list || q'[
				;

				if v_tables_already_exist is not null then
					raise_application_error(-20000, 'These tables already exist in the schema ' ||
					sys_context('userenv', 'CURRENT_SCHEMA') || ': ' || v_tables_already_exist);
				end if;
			end;
			#SLASH#]'
			, '			'),
			'#SLASH#', '/')
		);

		utl_file.fclose(v_handle);
	end write_check_for_existing_data;


	---------------------------------------
	procedure write_metadata_and_data is
		v_handle utl_file.file_type;
		v_metadata varchar2(32767);
		v_select varchar2(32767);
		type string_table is table of varchar2(32767);
		v_rows string_table;
		v_union_all varchar2(32767);
	begin
		v_handle := utl_file.fopen('SPACE_OUTPUT_DIR', 'oracle_create_space.sql', 'a');

		--Tables:
		for i in 1 .. g_ordered_objects.count loop
			--Table header:
			utl_file.new_line(v_handle);
			utl_file.new_line(v_handle);
			utl_file.put_line(v_handle, '--------------------------------------------------------------------------------');
			utl_file.put_line(v_handle, '-- '||g_ordered_objects(i));
			utl_file.put_line(v_handle, '--------------------------------------------------------------------------------');
			utl_file.new_line(v_handle);
			utl_file.put_line(v_handle, 'exec dbms_output.put_line(''Installing '||g_ordered_objects(i) || '...'');');

			--Metadata for tables:
			v_metadata := get_metadata('TABLE', user, g_ordered_objects(i)) || ';';
			utl_file.put_line(v_handle, replace(v_metadata, chr(10)||'  ', chr(10)));
			utl_file.new_line(v_handle);

			--Metadata for indexes:
			for indexes_to_create in
			(
				select table_owner, index_name
				from user_indexes
				where table_name = g_ordered_objects(i)
					--Primary key and unique keys are created as part of table definition.
					and index_name not like '%PK'
					and index_name not like '%UQ'
				order by index_name
			) loop
				v_metadata := get_metadata('INDEX', indexes_to_create.table_owner, indexes_to_create.index_name) || ';';
				utl_file.put_line(v_handle, replace(v_metadata, chr(10)||'  ', chr(10)));
			end loop;

			--Data:
			--Create SELECT statement that will generate another SELECT statement.
			select
				'select ''select ''||' ||
				listagg
				(
					case
						when data_type = 'VARCHAR2' then 'space_exporter.get_formatted_string('||column_name||')'
						when data_type = 'NUMBER' then 'space_exporter.get_formatted_number('||column_name||')'
						when data_type = 'DATE' then 'space_exporter.get_formatted_date('||column_name||')'
					end,
					'||'',''||'
				) within group (order by column_id) || '||'' from dual''' || chr(10) ||
					' from ' || table_name || ' order by 1'
				select_sql
			into v_select
			from user_tab_columns
			where table_name = g_ordered_objects(i)
			group by table_name;

			--Run the select and get all the data.
			execute immediate v_select
			bulk collect into v_rows;

			--Create the INSERTs.
			for j in 1 .. v_rows.count loop
				--Always start with an INSERT.
				if j = 1 then
					utl_file.put_line(v_handle, 'insert into '||g_ordered_objects(i));
				end if;

				--Add rows to UNION ALL.
				v_union_all := v_union_all || v_rows(j) || ' union all' || chr(10);

				--Package the rows 100 at a time, or for the last row.
				if j = v_rows.count or remainder(j, 100) = 0 then
					--Print the 100 rows and reset.  (Don't print the last " union all".)
					utl_file.put_line(v_handle, substr(v_union_all, 1, length(v_union_all) - 11) || ';');
					v_union_all := null;

					--Print another INSERT, unless it's the last row.
					if j <> v_rows.count then
						utl_file.put_line(v_handle, 'insert into '||g_ordered_objects(i));
					end if;
				end if;
			end loop;

		end loop;

		utl_file.fclose(v_handle);
	end write_metadata_and_data;


	---------------------------------------
	procedure write_move_and_rebuild is
		v_handle utl_file.file_type;
	begin
		v_handle := utl_file.fopen('SPACE_OUTPUT_DIR', 'oracle_create_space.sql', 'a');

		utl_file.new_line(v_handle);
		utl_file.new_line(v_handle);
		utl_file.put_line(v_handle, '--------------------------------------------------------------------------------');
		utl_file.put_line(v_handle, '-- Compress tables and rebuild indexes.');
		utl_file.put_line(v_handle, '--------------------------------------------------------------------------------');
		utl_file.new_line(v_handle);
		utl_file.put_line(v_handle, 'exec dbms_output.put_line(''Compressing tables and rebuilding indexes...'');');
		utl_file.new_line(v_handle);

		--Create MOVE and REBUILD for each table and its indexes.
		for i in 1 .. g_ordered_objects.count loop
			utl_file.put_line(v_handle, 'alter table '||g_ordered_objects(i)||' move compress;');

			for indexes_to_rebuild in
			(
				select index_name
				from all_indexes
				where owner = sys_context('userenv', 'CURRENT_SCHEMA')
					and table_name = g_ordered_objects(i)
				order by 1
			) loop
				utl_file.put_line(v_handle, 'alter index '||indexes_to_rebuild.index_name||' rebuild;');
			end loop;
		end loop;

		utl_file.fclose(v_handle);
	end;


	---------------------------------------
	procedure write_footer is
		v_handle utl_file.file_type;
	begin
		v_handle := utl_file.fopen('SPACE_OUTPUT_DIR', 'oracle_create_space.sql', 'a');

		utl_file.new_line(v_handle);
		utl_file.new_line(v_handle);
		utl_file.new_line(v_handle);
		utl_file.put_line(v_handle, replace(substr(
		q'[
				-- Print intro message.
				exec dbms_output.put_line('------------------------------------------------------------------------');
				exec dbms_output.put_line('-- Done.  The space database was successfully installed.');
				exec dbms_output.put_line('------------------------------------------------------------------------');
				]'
		, 2)
		, '				'));

		utl_file.put_line(v_handle, '--------------------------------------------------------------------------------');
		utl_file.put_line(v_handle, '-- DONE');
		utl_file.put_line(v_handle, '--------------------------------------------------------------------------------');

		utl_file.fclose(v_handle);
	end write_footer;

begin
	write_header;
	write_check_for_existing_data;
	write_metadata_and_data;
	write_move_and_rebuild;
	write_footer;
end;

end;
/
