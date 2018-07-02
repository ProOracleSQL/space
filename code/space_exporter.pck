create or replace package space_exporter is
	--Drop objects used for the data load.
	--P_TYPE can be one of "staging tables", "staging view", "presentation tables", or "all".
	procedure drop_objects(p_type varchar2);

	procedure generate_oracle_file;
end;
/
create or replace package body space_exporter is

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


--------------------------------------------------------------------------------
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



--------------------------------------------------------------------------------
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
		v_string varchar2(32767) := q'[


		]';
	begin
		v_handle := utl_file.fopen('SPACE_OUTPUT_DIR', 'oracle_create_space.sql', 'w');
		utl_file.put_line(v_handle, replace(substr(
		q'[
				-- This file creates the space schema for Oracle databases.');
				-- DO NOT MODIFY THIS FILE.  It is automatically generated.');

				-- #1: Session settings.
				alter session set nls_timestamp_format = 'YYYY-MM-DD HH24MISS';
				]'
		, 2)
		, '				'));

		  utl_file.fclose(v_handle);
	end write_header;

	---------------------------------------
	procedure write_metadata is
		v_handle utl_file.file_type;
		v_clob clob;
	begin
		v_handle := utl_file.fopen('SPACE_OUTPUT_DIR', 'oracle_create_space.sql', 'a');

		for i in 1 .. g_ordered_objects.count loop
			v_clob := get_metadata('TABLE', user, g_ordered_objects(i)) || ';';
			utl_file.put_line(v_handle, v_clob);
		end loop;


		utl_file.fclose(v_handle);
	end write_metadata;

	---------------------------------------
	procedure write_data is
	begin
		null;
	end write_data;

	---------------------------------------
	procedure write_footer is
	begin
		null;
	end write_footer;

begin
	write_header;
	write_metadata;
	write_data;
	write_footer;
end;


end;
/
