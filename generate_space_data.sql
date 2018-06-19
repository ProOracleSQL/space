/*

This is all very experimental, do not use this yet.

This file loads and transforms data from the awesome JSR Launch Vehicle Database sdb.tar.gz file into an Oracle database.

*/


--------------------------------------------------------------------------------
--#1: Create directories.  You may also need to grant permission on the folder.
--  This is usually the ora_dba group on windows, or the oracle users on Unix.
--------------------------------------------------------------------------------

create or replace directory sdb as 'C:\space\sdb.tar';
create or replace directory sdb_sdb as 'C:\space\sdb.tar\sdb\';



--------------------------------------------------------------------------------
--#2. Auto-manually generate external files to load the file.
-- This is a semi-automated process because the files are not 100% formatted correctly.
--------------------------------------------------------------------------------
create or replace function get_external_table_partial_ddl(p_directory varchar2, p_file_name varchar2) return varchar2 is
	v_clob clob;
	v_end_position number;
	v_format_description varchar2(32767);
	v_skip_count number;
	v_width_in_bytes number;
	v_number_of_fields number;


	type string_table is table of varchar2(32767);
	type number_table is table of number;
	v_column_names string_table := string_table();
	v_display_format string_table := string_table();
	v_byte_start_positions number_table := number_table();

	v_column_sql varchar2(32767);
	v_loader_fields varchar2(32767);
begin
	--Read the CLOB.
	v_clob := dbms_xslprocessor.read2clob(flocation => upper(p_directory), fname => p_file_name);

	--Get everything up until the first END.
	v_end_position := dbms_lob.instr(v_clob, chr(10)||'END');

	--Ensure there was a format description found.
	if v_end_position = 0 then
		raise_application_error(-20000, 'Could not find format description.');
	end if;

	v_format_description := dbms_lob.substr(v_clob, v_end_position, 1);
	v_skip_count := regexp_count(v_format_description, chr(10)) + 2;

	v_width_in_bytes := to_number(regexp_substr(v_format_description, 'NAXIS1\s*=\s*([0-9]+)', 1, 1, '', 1));
	v_number_of_fields := to_number(regexp_substr(v_format_description, 'TFIELDS\s*=\s*([0-9]+)', 1, 1, '', 1));

	--Populate arrays of the values.
	for i in 1 .. v_number_of_fields loop
		v_column_names.extend;
		v_display_format.extend;
		v_byte_start_positions.extend;

		v_column_names(v_column_names.count) := regexp_substr(v_format_description, 'TTYPE[0-9]*\s*=\s*''([^'']*)''', 1, i, '', 1);
		v_display_format(v_display_format.count) := regexp_substr(v_format_description, 'TDISP[0-9]*\s*=\s*''([^'']*)''', 1, i, '', 1);
		v_byte_start_positions(v_byte_start_positions.count) := regexp_substr(v_format_description, 'TBCOL[0-9]*\s*=\s*([0-9]*)', 1, i, '', 1);
	end loop;

	--Create a list of columns.
	for i in 1 .. v_number_of_fields loop
		v_column_sql := v_column_sql || ',' || chr(10) || '	' || v_column_names(i) ||
			' varchar2(' ||
			case
				when i = v_number_of_fields then (v_width_in_bytes - v_byte_start_positions(i) + 1)
				else (v_byte_start_positions(i+1) - v_byte_start_positions(i))
			end || ')';

		v_loader_fields := v_loader_fields || ',' || chr(10) || '			' || v_column_names(i) || ' (' ||
			v_byte_start_positions(i) || ':' ||
			case
				when i = v_number_of_fields then (v_width_in_bytes)
				else v_byte_start_positions(i+1) - 1
			end || ')' || ' ' ||
			' char(' ||
			case
				when i = v_number_of_fields then (v_width_in_bytes - v_byte_start_positions(i) + 1)
				else (v_byte_start_positions(i+1) - v_byte_start_positions(i))
			end || ')';
	end loop;

	--Return the table columns and the SQL Loader columns.
	return
		substr(v_column_sql, 3) || chr(10) || chr(10) ||
		'		skip ' || v_skip_count || chr(10) || chr(10) ||
		substr(v_loader_fields, 3);
end get_external_table_partial_ddl;
/






--------------------------------------------------------------------------------
--#3. Create external tables.
--------------------------------------------------------------------------------

select get_external_table_partial_ddl('sdb_sdb', 'Orgs') from dual;


select get_external_table_partial_ddl('sdb_sdb', 'stages') from dual;

/*
organization
family
vehicle
engine
stage
vehicle_stage
reference
site
platform
launch
*/


Explanations of the data files

    1.0: Organizations

    1.1: Families

    1.2: Designations

    1.3: The launch vehicle list

    1.4: The launch vehicle stages list

    1.5: The stages database

    1.6: The engines database

    1.7: The launch sites database

    1.8: The list of launch time references

    1.9. Explanation of columns in the launch list data files

The launch vehicle data files

    LAUNCH LIST SORTED BY FAMILY [70780 launches]
    LAUNCH LIST SORTED BY DES [70780 launches]
    LV [Launch Vehicles]
    LV_Stages [Launch Vehicle Stages]
    Stages [Data on each stage]
    Family [List of Stage Families]
    Sites [List of launch sites] and Platforms [List of launch platforms, esp. marine and air]
    Refs [List of references for launch times] 




drop table stages_staging;

--WARNING: This file was manually adjusted.
create table stages_staging
(
	Stage_Name varchar2(21),
	Stage_Family varchar2(21),
	Stage_Manufacturer varchar2(21),
	Stage_Alt_Name varchar2(21),
	Length varchar2(6),
	Diameter varchar2(6),
	Launch_Mass varchar2(8), --8, not 7
	Dry_Mass varchar2(10), --10, not 11
	Thrust varchar2(9),
	Duration varchar2(7),
	Engine varchar2(19),
	NEng varchar2(3),
	Class varchar2(1)
)
organization external
(
	type oracle_loader
	default directory sdb_sdb
	access parameters
	(
		records delimited by x'0A' characterset 'UTF8'
		readsize 1048576
		skip 47
		fields ldrtrim
		missing field values are null
		reject rows with all null fields
		(
			Stage_Name (1:21)  char(21),
			Stage_Family (22:42)  char(21),
			Stage_Manufacturer (43:63)  char(21),
			Stage_Alt_Name (64:84)  char(21),
			Length (85:90)  char(6),
			Diameter (91:96)  char(6),
			Launch_Mass (97:104)  char(8),
			Dry_Mass (105:114)  char(10),
			Thrust (115:123)  char(9),
			Duration (124:130)  char(7),
			Engine (131:149)  char(19),
			NEng (150:152)  char(3),
			Class (153:153)  char(1)
		)
	)
	location ('Stages')
)
reject limit unlimited
/


select * from stages_staging;


select * from launch_all_staging;















