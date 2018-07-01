/*

This is all very experimental, do not use this yet.

This file loads and transforms data from the awesome JSR Launch Vehicle Database sdb.tar.gz file into an Oracle database.

TODO:
1. Finish loading files into _staging tables, especially the LAUNCH_STAGING.
2. Transform _staging tables into final tables.
3. Verify data integrity, maybe cleanup tables.
4. Create final presentation tables.
5. Create exports of presentation tables into easy-to-load scripts.
6. Host those exports on different sites.
7. What is "TA" orbit class?


Notes for future refreshes:
1. You can probably remove or change this condition on SATELLITE_STAGING_VIEW: where jsr_to_date(launch_date) < date '2017-09-07'
2. Add some fields if the are populated with more data.  For example, I excluded launch.range because it was almost empty.
3. References were excluded, they are too messy.
4. Payload investigator names are not included.


Notes of JSR issues:

Orgs: LTV Electronic Systems Division is out of alignment and has a weird "b" in one column.
Orgs: Thales Alenia Space/Cannes (TAS-F) is the only one in ORG_CLASS "F".  Should it be "B" for business instead?
orgs.html: Should "(MET)" be listed as "meteorological"
orgs.html: It might help to explain some letters, like CC (control center?), and what PL stands for.
Family: it doesn't list all the family letters.  Are B, C, and L all "missile"s?
LV: The ICBM-T2 manufacturer is listed as "Minuteman".  Should it be "OATK" (Orbital ATK) instead?
LV: The ICBM-T2 manufacturer is listed as "Minuteman".  Should it be "OATK" (Orbital ATK) instead?
LV: Should BLDT launch vehicle's manufacturer be LARCN instead of BLDT?  BLDT is not in Org.  Based on: https://ntrs.nasa.gov/archive/nasa/casi.ntrs.nasa.gov/19740023231.pdf
Orgs (and LV): Is there a missing Org for CMIK?  It's listed in LV but not ORG. http://www.astronautix.com/c/cmik.html
Engines: "Xylidiene/Triethylamine" is too large and spills into the MASS field.
Engines: "9KS1660" has a comma instead of a period for the thrust.
Engines: There are a few double questions marks.
Engine: Should ROCKL (not in Orgs) be RLABN (Rocket Lab in New Zealand)?
Engine: Should ANSAR (not in Orgs) be ANSAL (Ansar Allah (Houthi) Revolutionary Committee Forces)?
Stages: Should "AJ10-11B" be "AJ10-118"?  I can't find "AJ10-11B" in Engines.
Stages: Should "GEM-63" be excluded, or also added to Engines?  Looks like it's not being used yet: http://www.northropgrumman.com/Capabilities/GEM/Pages/default.aspx 
Stages: "Corporal Type 1" has a comman instead of a period for the length.
Stages: Should "LS-A Booster" be "LS-A booster" to match the Engines file?  (That will make a difference to case-sensitive databases.)
Stages: Should ANSAR (not in Orgs) be ANSAL (Ansar Allah (Houthi) Revolutionary Committee Forces)?
LV_Stages: Should "Titan II SLV", stage F, have multiplicity of "1" instead of "F"?  It's the only non-numeric value.
LV_Stages: There are some duplicate rows: Ariane 42L/42L/F/Ariane Fairing, Atlas V 411//F/Fairing, Minotaur IV//F/Fairing
LV_Stages: The fairings and recovery vehicles in here don't match values in Stages.  Should these values be added to stages, or recorded separately somehow?
Refs: "AWST960401-28" has a duplicate entry.
Refs: "www.lapan.go.id" has a duplicate entry.
Sites: There are two empty rows with only "#" for the site name.
Sites: Should "NKAZ" be removed?  It's listed as the type "TGT", which I assume is target.  But that category is not listed on sites.html, and it's not used in any launch.
Sites: These parent codes look to be typos or case differences: "BLORIG" ==> "BLOR","DDR" ==> "DD","Luna" ==> "LUNA","NRC" ==> "NRCC","OTRAG" ==> "OTRG","ROCKL" ==> "RLABN","SCALED" ==> "SCAL","Yemen" ==> "YE"
Platforms: Is B-52H missing from the file?
Platforms: Should "DDG 174" be "DDG-174"?  That will match launches and the platform name.
Platforms: Shift "MiG31D-72" UCODE one character to the right, it's not aligned properly.
all: For "2014-S19", should the Platform be "INS-OPV" instead of "INS"?  "INS" doesn't exist in platforms, but it's in the short name for "INS-OPV".
launchcols.html: Minor typos: ifno --> if no, sucess --> success, assessements --> assessments, fo --> of, Addtional --> Additional
launchcols.html and all: Descriptions are missing for some launch code categories.  Here are my guesses:  'H' -> 'sounding rocket', 'R' -> 'ballistic missile test', 'X' -> 'lunar return', 'Y' -> 'suborbital spaceplane'.
launchcols.html and all: What are the launch statuses "D" and "E"?  I'm guessing something like "destroyed before launch"?
all: Some of the payload groups look weird: "-                 MLV-1","-                 MLV-2","-                 MLV-3","-                 MLV-4","-                 MLV-5","-                 MLV-6","-                 MLV-8","-                 MLV-9","-       CYGNUS"
all: The payload groups "AFSPC-X" and "NROL-X ..." are formatted differently than others.  Should "AFSPC-X" be "AFSPC/", and should "NROL-X" be "NRO/"?
all: The variant for Falcon 9 FT does not exist in LV.  Should the "FT" be changed to "FT 3", "FT 3/4", etc?  Or should "FT" be added to LV?
all: Should the launch "Soyuz-2-1A"/"Volga" be "Soyuz-2-1V"/"Volga"?
all: For 2017-002, should "Kuaizhou-1A" be "Kuaizhou"?  Or should "Kuaizhou-1A" be added to LV?
all: "Vernon" should be "VERNON" to match case of Sites.
all: Change "LC31/ShPU-12" to "LC31/ShPU-12" to match the case in sites.  (Note the lowercase "u".)
all: Change "GTSP-4" to "GTsP-4" to match the case in sites.
all: What is launch pad "RW13"?  It doesn't exist in sites.
all: Payload group "91SMW" should probably be "91MW".  "91SMW" does not exist in Orgs.
satcat.txt - There are lots of duplicate owner-operators, like "NRO/NRO".  Should the second value be different?
satcat.txt - S043190 and S043190 are empty.
satcat.txt: The payload organizations "COMDE" should be "COMDEV", and "SURRE" should be "SURREY".
orbits.html - Add "VHEO" ("Very High"?), it's used in satcat.txt.
orrbits.html - What is "TA" orbit class?  It appears a few times in satcat.txt.

*/


--------------------------------------------------------------------------------
--#1: Manually download data.
--------------------------------------------------------------------------------

--#0A: Download and unzip this file in C:\space: http://www.planet4589.org/space/lvdb/sdb.tar.gz

--#0B: Download this file and put it in C:\space\sdb.tar: http://planet4589.org/space/log/satcat.txt



--------------------------------------------------------------------------------
--#2: Create directories.  You may also need to grant permission on the folder.
--  This is usually the ora_dba group on windows, or the oracle users on Unix.
--------------------------------------------------------------------------------

create or replace directory sdb as 'C:\space\sdb.tar';
create or replace directory sdb_sdb as 'C:\space\sdb.tar\sdb\';



--------------------------------------------------------------------------------
--#3. Auto-manually generate external files to load the file.
-- This is a semi-automated process because the files are not 100% formatted correctly.
--------------------------------------------------------------------------------
create or replace function get_external_table_ddl(
	p_table_name varchar2,
	p_directory varchar2,
	p_file_name varchar2
) return varchar2 is
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

	v_template varchar2(32767) := q'[
create table $$TABLE_NAME$$
(
$$TABLE_COLUMNS$$
)
organization external
(
	type oracle_loader
	default directory $$DIRECTORY$$
	access parameters
	(
		records delimited by x'0A' characterset 'UTF8'
		readsize 1048576
		skip $$SKIP_NUMBER$$
		fields ldrtrim
		missing field values are null
		reject rows with all null fields
		(
$$LOADER_COLUMNS$$
		)
	)
	location ('$$FILE_NAME$$')
)
reject limit unlimited
/]';

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

		--Sometimes it's TPOS instad of TBCOL:
		if v_byte_start_positions(v_byte_start_positions.count) is null then
			v_byte_start_positions(v_byte_start_positions.count) := regexp_substr(v_format_description, 'TPOS[0-9]*\s*=\s*([0-9]*)', 1, i, '', 1);
		end if;
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
	return replace(replace(replace(replace(replace(replace(v_template
		,'$$TABLE_NAME$$', p_table_name)
		,'$$TABLE_COLUMNS$$', substr(v_column_sql, 3))
		,'$$DIRECTORY$$', p_directory)
		,'$$SKIP_NUMBER$$', v_skip_count)
		,'$$LOADER_COLUMNS$$', substr(v_loader_fields, 3))
		,'$$FILE_NAME$$', p_file_name);		
end get_external_table_ddl;
/




--------------------------------------------------------------------------------
--#4. Create external tables.
--------------------------------------------------------------------------------

select get_external_table_ddl('organization_staging', 'sdb_sdb', 'Orgs') from dual;
select get_external_table_ddl('family_staging', 'sdb_sdb', 'Family') from dual;
select get_external_table_ddl('launch_vehicle_staging', 'sdb_sdb', 'LV') from dual;
select get_external_table_ddl('engine_staging', 'sdb_sdb', 'Engines') from dual;
select get_external_table_ddl('stage_staging', 'sdb_sdb', 'stages') from dual;
select get_external_table_ddl('launch_vehicle_stage_staging', 'sdb_sdb', 'LV_Stages') from dual;
--Commented out - not clean enough to use.
--select get_external_table_ddl('reference_staging', 'sdb_sdb', 'Refs') from dual;
select get_external_table_ddl('site_staging', 'sdb_sdb', 'Sites') from dual;
select get_external_table_ddl('platform_staging', 'sdb_sdb', 'Platforms') from dual;
select get_external_table_ddl('launch_staging', 'sdb', 'lvtemplate') from dual;
--(satellite_staging does not have a template.)

/*
Directions for manually checking results:
1. Check the first row (to ensure that the SKIP was correct)
2. Check each column (to ensure the widths are correct)
3. Check that there is no .BAD file in the directory (to ensure nothing broke SQL*Loader and couldn't even load)
4. Check the row count against the file line count
*/


--Auto-generated:
create table organization_staging
(
	Code     varchar2(9),
	UCode    varchar2(9),
	StateCode varchar2(7),
	Type     varchar2(17),
	Class    varchar2(2),
	TStart   varchar2(13),
	TStop    varchar2(13),
	ShortName varchar2(18),
	Name     varchar2(81),
	Location varchar2(53),
	Longitude varchar2(13),
	Latitude varchar2(11),
	Error    varchar2(8),
	Parent   varchar2(13),
	ShortEName varchar2(17),
	EName    varchar2(61),
	UName    varchar2(230)
)
organization external
(
	type oracle_loader
	default directory sdb_sdb
	access parameters
	(
		records delimited by x'0A' characterset 'UTF8'
		readsize 1048576
		skip 59
		fields ldrtrim
		missing field values are null
		reject rows with all null fields
		(
			Code     (1:9)  char(9),
			UCode    (10:18)  char(9),
			StateCode (19:25)  char(7),
			Type     (26:42)  char(17),
			Class    (43:44)  char(2),
			TStart   (45:57)  char(13),
			TStop    (58:70)  char(13),
			ShortName (71:88)  char(18),
			Name     (89:169)  char(81),
			Location (170:222)  char(53),
			Longitude (223:235)  char(13),
			Latitude (236:246)  char(11),
			Error    (247:254)  char(8),
			Parent   (255:267)  char(13),
			ShortEName (268:284)  char(17),
			EName    (285:345)  char(61),
			UName    (346:575)  char(230)
		)
	)
	location ('Orgs')
)
reject limit unlimited
/

create table family_staging
(
	Family   varchar2(21),
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
		skip 12
		fields ldrtrim
		missing field values are null
		reject rows with all null fields
		(
			Family   (1:21)  char(21),
			Class (22:22)  char(1)
		)
	)
	location ('Family')
)
reject limit unlimited
/

create table launch_vehicle_staging
(
	LV_Name  varchar2(33),
	LV_Family varchar2(21),
	LV_SFamily varchar2(21),
	LV_Manufacturer varchar2(21),
	LV_Variant varchar2(11),
	LV_Alias varchar2(20),
	LV_Min_Stage varchar2(4),
	LV_Max_Stage varchar2(2),
	Length varchar2(6),
	Diameter varchar2(6),
	Launch_Mass varchar2(9),
	LEO_Capacity varchar2(9),
	GTO_Capacity varchar2(9),
	TO_Thrust varchar2(9),
	Class varchar2(2),
	Apogee varchar2(7),
	Range  varchar2(6)
)
organization external
(
	type oracle_loader
	default directory sdb_sdb
	access parameters
	(
		records delimited by x'0A' characterset 'UTF8'
		readsize 1048576
		skip 58
		fields ldrtrim
		missing field values are null
		reject rows with all null fields
		(
			LV_Name  (1:33)  char(33),
			LV_Family (34:54)  char(21),
			LV_SFamily (55:75)  char(21),
			LV_Manufacturer (76:96)  char(21),
			LV_Variant (97:107)  char(11),
			LV_Alias (108:127)  char(20),
			LV_Min_Stage (128:131)  char(4),
			LV_Max_Stage (132:133)  char(2),
			Length (134:139)  char(6),
			Diameter (140:145)  char(6),
			Launch_Mass (146:154)  char(9),
			LEO_Capacity (155:163)  char(9),
			GTO_Capacity (164:172)  char(9),
			TO_Thrust (173:181)  char(9),
			Class (182:183)  char(2),
			Apogee (184:190)  char(7),
			Range  (191:196)  char(6)
		)
	)
	location ('LV')
)
reject limit unlimited
/

--WARNING: Column "Date" manually renamed to "first_launch_date" to avoid Oracle keyword.
create table engine_staging
(
	Engine_Name varchar2(21),
	Engine_Manufacturer varchar2(21),
	Engine_Family varchar2(21),
	Engine_Alt_Name varchar2(13),
	Oxidizer varchar2(11),
	Fuel varchar2(21),
	Mass varchar2(11),
	Impulse varchar2(9),
	Thrust varchar2(11),
	Specific_Impulse varchar2(7),
	Duration varchar2(7),
	Chambers varchar2(4),
	first_launch_date varchar2(13),
	Usage varchar2(20)
)
organization external
(
	type oracle_loader
	default directory sdb_sdb
	access parameters
	(
		records delimited by x'0A' characterset 'UTF8'
		readsize 1048576
		skip 49
		fields ldrtrim
		missing field values are null
		reject rows with all null fields
		(
			Engine_Name (1:21)  char(21),
			Engine_Manufacturer (22:42)  char(21),
			Engine_Family (43:63)  char(21),
			Engine_Alt_Name (64:76)  char(13),
			Oxidizer (77:87)  char(11),
			Fuel (88:108)  char(21),
			Mass (109:119)  char(11),
			Impulse (120:128)  char(9),
			Thrust (129:139)  char(11),
			Specific_Impulse (140:146)  char(7),
			Duration (147:153)  char(7),
			Chambers (154:157)  char(4),
			first_launch_date (158:170)  char(13),
			Usage (171:190)  char(20)
		)
	)
	location ('Engines')
)
reject limit unlimited
/

--WARNING: Some comments on the right-hand side are dropped, but I don't think that matters.
create table launch_vehicle_stage_staging
(
	LV_Mnemonic varchar2(34),
	LV_Variant varchar2(11),
	Stage_No varchar2(3),
	Stage_Name varchar2(21),
	Qualifier varchar2(2),
	Dummy    varchar2(2),
	Multiplicity varchar2(3),
	Stage_Impulse varchar2(10),
	Stage_Apogee varchar2(7),
	Stage_Perigee varchar2(6)
)
organization external
(
	type oracle_loader
	default directory sdb_sdb
	access parameters
	(
		records delimited by x'0A' characterset 'UTF8'
		readsize 1048576
		skip 37
		fields ldrtrim
		missing field values are null
		reject rows with all null fields
		(
			LV_Mnemonic (1:34)  char(34),
			LV_Variant (35:45)  char(11),
			Stage_No (46:48)  char(3),
			Stage_Name (49:69)  char(21),
			Qualifier (70:71)  char(2),
			Dummy    (72:73)  char(2),
			Multiplicity (74:76)  char(3),
			Stage_Impulse (77:86)  char(10),
			Stage_Apogee (87:93)  char(7),
			Stage_Perigee (94:99)  char(6)
		)
	)
	location ('LV_Stages')
)
reject limit unlimited
/

--WARNING: This file was manually adjusted.
create table stage_staging
(
	Stage_Name varchar2(21),
	Stage_Family varchar2(21),
	Stage_Manufacturer varchar2(21),
	Stage_Alt_Name varchar2(21),
	Length varchar2(6),
	Diameter varchar2(6),
	--Launch_Mass varchar2(7),
	--Dry_Mass varchar2(11),
	--Launch_Mass (97:103)  char(7),
	--Dry_Mass (104:114)  char(11),
	Launch_Mass varchar2(8),
	Dry_Mass varchar2(10),
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

/*
--WARNING: This works, but the file format has "#" comments that don't work well.
--Commented out - not clean enough to use yet.
create table reference_staging
(
	Cite        varchar2(21),
	Reference   varchar2(120)
)
organization external
(
	type oracle_loader
	default directory sdb_sdb
	access parameters
	(
		records delimited by x'0A' characterset 'UTF8'
		readsize 1048576
		skip 12
		fields ldrtrim
		missing field values are null
		reject rows with all null fields
		(
			Cite     (1:21)  char(21),
			Reference (22:141)  char(120)
		)
	)
	location ('Refs')
)
reject limit unlimited
/
*/

--WARNING: Two of the columns had to be manually resized.
create table site_staging
(
	Site    varchar2(9),
	Code     varchar2(13),
	Ucode   varchar2(13),
	Type    varchar2(5),
	StateCode varchar2(9),
	TStart   varchar2(13),
	TStop   varchar2(13),
	ShortName   varchar2(18),
	Name varchar2(81),
	Location  varchar2(53),
	Longitude varchar2(13),
	Latitude varchar2(11),
	Error varchar2(7),
	Parent  varchar2(13),
	--ShortEName   varchar2(18),
	--EName varchar2(60),
	--ShortEName   (272:289)  char(18),
	--EName (290:349)  char(60),
	ShortEName   varchar2(17),
	EName varchar2(61),
	UName varchar2(15)
)
organization external
(
	type oracle_loader
	default directory sdb_sdb
	access parameters
	(
		records delimited by x'0A' characterset 'UTF8'
		readsize 1048576
		skip 59
		fields ldrtrim
		missing field values are null
		reject rows with all null fields
		(
			Site    (1:9)  char(9),
			Code     (10:22)  char(13),
			Ucode   (23:35)  char(13),
			Type    (36:40)  char(5),
			StateCode (41:49)  char(9),
			TStart   (50:62)  char(13),
			TStop   (63:75)  char(13),
			ShortName   (76:93)  char(18),
			Name (94:174)  char(81),
			Location  (175:227)  char(53),
			Longitude (228:240)  char(13),
			Latitude (241:251)  char(11),
			Error (252:258)  char(7),
			Parent  (259:271)  char(13),
			ShortEName   (272:288)  char(17),
			EName (289:349)  char(61),
			UName (350:364)  char(15)
		)
	)
	location ('Sites')
)
reject limit unlimited
/

create table platform_staging
(
	Code   varchar2(11),
	Ucode     varchar2(12),
	StateCode   varchar2(8),
	Type    varchar2(17),
	Class    varchar2(2),
	TStart   varchar2(13),
	TStop   varchar2(13),
	ShortName   varchar2(18),
	Name varchar2(81),
	Location  varchar2(41),
	Longitude varchar2(13),
	Latitude varchar2(10),
	Error varchar2(20),
	Parent  varchar2(13),
	ShortEName   varchar2(17),
	EName varchar2(61)
)
organization external
(
	type oracle_loader
	default directory sdb_sdb
	access parameters
	(
		records delimited by x'0A' characterset 'UTF8'
		readsize 1048576
		skip 56
		fields ldrtrim
		missing field values are null
		reject rows with all null fields
		(
			Code   (1:11)  char(11),
			Ucode     (12:23)  char(12),
			StateCode   (24:31)  char(8),
			Type    (32:48)  char(17),
			Class    (49:50)  char(2),
			TStart   (51:63)  char(13),
			TStop   (64:76)  char(13),
			ShortName   (77:94)  char(18),
			Name (95:175)  char(81),
			Location  (176:216)  char(41),
			Longitude (217:229)  char(13),
			Latitude (230:239)  char(10),
			Error (240:259)  char(20),
			Parent  (260:272)  char(13),
			ShortEName   (273:289)  char(17),
			EName (290:350)  char(61)
		)
	)
	location ('Platforms')
)
reject limit unlimited
/

--WARNING: Had to change the filename to "all", and change "group" to "payload_group", change skip to 0, and had to add FlightCode.
--TODO: There are some problems with the fields at the end.
create table launch_staging
(
	Launch_Tag varchar2(15),
	Launch_JD varchar2(11),
	Launch_Date varchar2(21),
	LV_Type  varchar2(25),
	Variant  varchar2(7),
	Flight_ID varchar2(21),
	Flight   varchar2(25),
	Mission  varchar2(25),
	FlightCode varchar2(25),
	Platform varchar2(10),
	Launch_Site varchar2(9),
	Launch_Pad varchar2(17),
	Apogee   varchar2(7),
	Apoflag  varchar2(2),
	Range    varchar2(5),
	RangeFlag varchar2(2),
	Dest     varchar2(13),
	Agency   varchar2(13),
	Launch_Code varchar2(5),
	Payload_Group    varchar2(25),
	Category varchar2(25),
	LTCite   varchar2(21),
	Cite     varchar2(21),
	Notes    varchar2(32)
)
organization external
(
	type oracle_loader
	default directory sdb
	access parameters
	(
		records delimited by x'0A' characterset 'UTF8'
		readsize 1048576
		skip 0
		fields ldrtrim
		missing field values are null
		reject rows with all null fields
		(
			Launch_Tag (1:15)  char(15),
			Launch_JD (16:26)  char(11),
			Launch_Date (27:47)  char(21),
			LV_Type  (48:72)  char(25),
			Variant  (73:79)  char(7),
			Flight_ID (80:100)  char(21),
			Flight   (101:125)  char(25),
			Mission  (126:150)  char(25),
			FlightCode (151:175) char(25),
			Platform (176:185)  char(10),
			Launch_Site (186:194)  char(9),
			Launch_Pad (195:211)  char(17),
			Apogee   (212:218)  char(7),
			Apoflag  (219:220)  char(2),
			Range    (221:225)  char(5),
			RangeFlag (226:227)  char(2),
			Dest     (228:240)  char(13),
			Agency   (241:253)  char(13),
			Launch_Code (254:258)  char(5),
			Payload_Group    (259:283)  char(25),
			Category (284:308)  char(25),
			LTCite   (309:329)  char(21),
			Cite     (330:350)  char(21),
			Notes    (351:382)  char(32)
		)
	)
	location ('all')
)
reject limit unlimited
/

--WARNING: This file is completely manual.  The "numbers" column will need to be split.
create table satellite_staging
(
	satcat         varchar(8),
	cospar         varchar(15),
	official_name  varchar(41),
	secondary_name varchar(25),
	owner_operator varchar(13),
	launch_date    varchar(12),
	current_status varchar(17),
	status_date    varchar(13),
	orbit_date     varchar(12),
	orbit_class    varchar(8),
	--Poorly formatted values for orbit_period, perigee, apogee, and inclination.
	numbers        varchar(100)
)
organization external
(
	type oracle_loader
	default directory sdb
	access parameters
	(
		records delimited by x'0A' characterset 'UTF8'
		readsize 1048576
		skip 0
		fields ldrtrim
		missing field values are null
		reject rows with all null fields
		(
			satcat         (1:8) char(8),
			cospar         (9:23) char(15),
			official_name  (24:63) char(41),
			secondary_name (65:94) char(25),
			owner_operator (90:106) char(13),
			launch_date    (103:118) char(12),
			current_status (115:134) char(17),
			status_date    (132:147) char(13),
			orbit_date     (145:159) char(12),
			orbit_class    (157:167) char(8),
			numbers        (165:267) char(100)
		)
	)
	location ('satcat.txt')
)
reject limit unlimited
/
comment on table satellite_staging is 'See this website for a description of the data: http://planet4589.org/space/log/satcat.html';

--------------------------------------------------------------------------------
--#5. Create helper functions for conversions.
--------------------------------------------------------------------------------

create or replace function jsr_to_date(p_date_string in varchar2) return date is
/*
	Purpose: Safely convert the JSR dates to a real date.
*/
	v_date_string varchar2(32767);
begin
	--Remove whitespace as beginning and end, dashes (which are used in place of null), question marks, "*"s, "s"s.
	v_date_string := p_date_string;
	v_date_string := replace(v_date_string, '-');
	v_date_string := replace(v_date_string, '?');
	v_date_string := replace(v_date_string, '*');
	v_date_string := trim(v_date_string);
	v_date_string := trim('s' from v_date_string);

	--Return NULL if NULL.
	if v_date_string is null then
		return null;
	elsif length(v_date_string) in (3,4) then
		return to_date(v_date_string || ' 01 01', 'YYYY MM DD');
	elsif length(v_date_string) = 8 then
		return to_date(v_date_string || '01', 'YYYY Mon DD');
	elsif length(v_date_string) in (10, 11) then
		--Change 00 to 01.
		if substr(v_date_string, 10) in ('0', '00') then
			return to_date(substr(v_date_string, 1, 9) || '01', 'YYYY Mon DD');
		else
			return to_date(v_date_string, 'YYYY Mon DD');
		end if;
	--Quarter.
	elsif length(v_date_string) = 7 and lower(v_date_string) like '%q%' then
		return to_date(substr(v_date_string, 1, 4) || ' ' ||
			case substr(v_date_string, 7, 1)
				when 1 then '01'
				when 2 then '04'
				when 3 then '07'
				when 4 then '10'
			end
			, 'YYYY MM');
	elsif length(v_date_string) >= 12 then
		return to_date(v_date_string, 'YYYY Mon DD HH24MI:SS');
	else
		raise_application_error(-20000, 'Unexpected format for this date string: ' || p_date_string);
	end if;

exception when others then
	raise_application_error(-20000, 'Unexpected format for this date string: ' || p_date_string);
end jsr_to_date;
/


create or replace function get_nt_from_list
(
	p_list in varchar2,
	p_delimiter in varchar2
) return sys.odcivarchar2list is
/*
	Purpose: Split a list of strings into a nested table of string.
*/
	v_index number := 0;
	v_item varchar2(32767);
	v_results sys.odcivarchar2list := sys.odcivarchar2list();
begin
	--Split.
	loop
		v_index := v_index + 1;
		v_item := regexp_substr(p_list, '[^' || p_delimiter || ']+', 1, v_index);
		exit when v_item is null;
		v_results.extend;
		v_results(v_results.count) := v_item;		
	end loop;

	return v_results;
end;
/



--------------------------------------------------------------------------------
--#6. Create staging views that will do much of the trimming, converting, and decoding.
--------------------------------------------------------------------------------

--Organization.
create or replace force view organization_staging_view as
--Decode codes and re-arrange columns.
select
	org_code,
	org_name,
	org_type,
	case
		when org_class is null then null
		when org_class = 'A' then 'academic/non-profit'
		when org_class = 'B' then 'business'
		when org_class = 'C' then 'civilian'
		when org_class = 'D' then 'defense'
		when org_class = 'E' then 'engine/motor manufacturer'
		when org_class = 'F' then 'business' --This seems like a mistake.
		when org_class = 'O' then 'generic organization'
		else 'ERROR - Unexpected value "'||org_class||'"'
	end org_class,
	parent_org_code,
	org_state_code,
	org_location,
	org_start_date,
	org_stop_date,
	org_utf8_name
from
(
	--Convert dates, numbers, and nulls.
	select
		org_code,
		decode(parent_org_code, '-', null, parent_org_code) parent_org_code,
		org_state_code,
		decode(org_type, '-', null, org_type) org_type,
		org_class,
		jsr_to_date(org_start_date) org_start_date,
		jsr_to_date(org_stop_date) org_stop_date,
		org_location,
		org_name,
		org_utf8_name
	from
	(
		--Trim and project relevant columns.
		select
			trim(code) org_code,
			trim(parent) parent_org_code,
			trim(statecode) org_state_code,
			trim(type) org_type,
			trim(class) org_class,
			trim(tstart) org_start_date,
			trim(tstop) org_stop_date,
			trim(location) org_location,
			coalesce(replace(trim(shortename),'-'), replace(trim(ename),'-'), replace(trim(name),'-')) org_name,
			trim(uname) org_utf8_name
		from organization_staging
		order by code
	) trim_and_project
) convert;


--Family.
create or replace view launch_vehicle_family_stagng_v as
--Remove a few extra rows.
select lv_family_code, lv_family_class
from
(
	--Decode.
	select
		family lv_family_code,
		case
			--Regular conversions:
			when class = 'A' then 'astronaut suborbital'
			--I'm not sure about B, C, and L.
			when class in ('B', 'C', 'L', 'M') then 'missile'
			when class = 'O' then 'orbital family'
			when class = 'R' then 'sounding rocket'
			when class = 'S' then 'intermediate stage 1'
			when class = 'T' then 'test rocket'
			when class = 'U' then 'orbital'
			when class = 'V' then 'missile test rocket'
			when class = 'W' then 'weather (small)'
			when class = 'X' then 'deleted'
			else 'ERROR - Unexpected value "'||class||'"'
		end lv_family_class
	from
	(
		--Trim and project relevant columns.
		select
			trim(family) family,
			trim(class) class
		from family_staging
	) trim_and_project
) decoded
where not
(
	--A few changes to make the class a 1-to-1 mapping.
	--I'm not 100% sure about this, but the idea is that if a rocket becomes
	--part of a higher class, then it always belongs there.
	--
	--BB5 is "sounding rocket", not "intermediate stage 1"
	--Star48 is "orbital", not "test rocket"
	--Zefiro is "intermediate stage 1", not "test rocket"
	--STS is "orbital family" not "orbital"  (what is the difference?)
	(lv_family_code = 'BB5' and lv_family_class = 'intermediate stage 1') or
	(lv_family_code = 'Star48' and lv_family_class = 'test rocket') or
	(lv_family_code = 'Zefiro' and lv_family_class = 'test rocket') or
	(lv_family_code = 'STS' and lv_family_class = 'orbital')
);


--Launch Vehicle Staging
create or replace force view launch_vehicle_staging_view as
--Decode codes and re-arrange columns.
select
	lv_name,
	lv_variant,
	case
		when lv_class is null then null
		when lv_class = 'A' then 'endoatmospheric rocket'
		when lv_class = 'Q' then 'endoatmospheric research test vehicle'
		when lv_class = 'T' then 'endoatmoshpheric test/research'
		when lv_class = 'W' then 'endoatmospheric weather rocket <80 km'
		when lv_class = 'Y' then 'exoatmospheric weather rocket'

		when lv_class = 'B' then 'tactical ballistic missile'
		when lv_class = 'C' then 'cruise missile'
		when lv_class = 'M' then 'missile'

		when lv_class = 'D' then 'deep space launch vehicle'
		when lv_class = 'O' then 'orbital launch vehicle'

		when lv_class = 'R' then 'research rocket'
		when lv_class = 'V' then 'rocket test vehicle'
		when lv_class = 'X' then 'big test rocket'

		else 'ERROR - Unexpected value "'||lv_class||'"'
	end lv_class,
	lv_family_code,
	lv_manufacturer_org_codes,
	lv_alias,
	min_stage,
	max_stage,
	length,
	diameter,
	launch_mass,
	leo_capacity,
	gto_capacity,
	take_off_thrust,
	apogee,
	range
from
(
	--Convert dates, numbers, and nulls.
	select
		lv_name,
		lv_family_code,
		replace(nullif(lv_manufacturer_org_codes, '-'), '?') lv_manufacturer_org_codes,
		nullif(lv_variant, '-') lv_variant,
		lv_alias,
		to_number(min_stage) min_stage,
		to_number(max_stage) max_stage,
		nullif(replace(length, '?'), '-') length,
		nullif(replace(diameter, '?'), '-') diameter,
		nullif(replace(launch_mass, '?'), '-') launch_mass,
		nullif(replace(leo_capacity, '?'), '-') leo_capacity,
		nullif(replace(gto_capacity, '?'), '-') gto_capacity,
		nullif(replace(take_off_thrust, '?'), '-') take_off_thrust,
		lv_class,
		nullif(replace(apogee, '?'), '-') apogee,
		nullif(replace(range, '?'), '-') range
	from
	(
		--Trim and project relevant columns.
		select
			trim(lv_name) lv_name,
			trim(lv_family) lv_family_code,
			--LV_SFAMILY is not used for now.
			trim(lv_manufacturer) lv_manufacturer_org_codes,
			trim(lv_variant) lv_variant,
			trim(lv_alias) lv_alias,
			trim(lv_min_stage) min_stage,
			trim(lv_max_stage) max_stage,
			trim(length) length,
			trim(diameter) diameter,
			trim(launch_mass) launch_mass,
			trim(leo_capacity) leo_capacity,
			trim(gto_capacity) gto_capacity,
			trim(to_thrust) take_off_thrust,
			trim(class) lv_class,
			trim(apogee) apogee,
			trim(range) range
		from launch_vehicle_staging
		order by lv_name, lv_variant
	) trim_and_project
) convert
order by lv_name;


--Engine
create or replace view engine_staging_view as
--Fix some codes and re-arrange columns.
select
	engine_name,
	engine_family,
	engine_alt_name,
	first_launch_year,
	usage,
	mass,
	impulse,
	thrust,
	specific_impulse,
	duration,
	chambers,
	--Fix some codes not in Orgs.
	case
		when engine_manufacturer_code_list = 'ROCKL' then 'RLABN'
		when engine_manufacturer_code_list = 'ANSAR' then 'ANSAL'
		else engine_manufacturer_code_list
	end engine_manufacturer_code_list,
	oxidizer_list,
	fuel_list
from
(
	--Convert dates, numbers, and nulls.
	select
		engine_name,
		replace(engine_manufacturer_code_list, '?') engine_manufacturer_code_list,
		nullif(engine_family, '-') engine_family,
		nullif(engine_alt_name, '-') engine_alt_name,
		replace(nullif(nullif(oxidizer_list, '-'), 'UNK'), '?') oxidizer_list,
		replace(nullif(nullif(fuel_list, '-'), 'UNK'), '?') fuel_list,
		to_number(replace(nullif(mass, '-'), '?')) mass,
		to_number(replace(nullif(impulse, '-'), '?')) impulse,
		to_number(trim('s' from replace(replace(nullif(nullif(thrust, '-'), 'UNK'), '?'), ',', '.'))) thrust,
		to_number(trim('s' from replace(nullif(specific_impulse, '-'), '?'))) specific_impulse,
		to_number(replace(nullif(duration, '-'), '?')) duration,
		to_number(replace(nullif(chambers, '-'), '?')) chambers,
		extract(year from jsr_to_date(nullif(first_launch_year, '-'))) first_launch_year,
		nullif(usage, '-') usage
	from
	(
		--Trim and project relevant columns.
		select
			trim(engine_name) engine_name,
			trim(engine_manufacturer) engine_manufacturer_code_list,
			trim(engine_family) engine_family,
			trim(engine_alt_name) engine_alt_name,
			trim(oxidizer) oxidizer_list,
			trim(
				--Weird case where column spills over into next column.
				case when fuel like '%Xylidiene/Triethylam%' then 'Xylidiene/Triethylamine' else fuel end
			) fuel_list,
			trim(
				--Weird case where column spills over into next column.
				case when mass like '%ine      -%' then '-' else mass end
			) mass,
			trim(replace(impulse, '?')) impulse,
			case when
				trim(thrust) = '92.0E-3' then '.092' else trim(thrust)
			end thrust,
			trim(specific_impulse) specific_impulse,
			trim(duration) duration,
			trim(chambers) chambers,
			trim(first_launch_date) first_launch_year,
			trim(usage) usage
		from engine_staging
		order by engine_name
	) trim_and_project
) convert;


--Stage
create or replace view stage_staging_view as
--Decode some mistakes and re-arrange columns.
select
	stage_name,
	stage_family,
	stage_alt_name,
	length,
	diameter,
	launch_mass,
	dry_mass,
	thrust,
	duration,
	case
		--Looks like a typo?
		when engine_name = 'AJ10-11B' then 'AJ10-118'
		--Case sensitivity issue?
		when engine_name = 'LS-A Booster' then 'LS-A booster'
		else engine_name
	end engine_name,
	engine_count,
	--Looks like there are some typos?
	case
		when stage_name = 'Badr-1' and stage_manufacturer_code_list = 'ANSAR' then 'ANSAL'
		when stage_name = 'Grad' and stage_manufacturer_code_list = 'ANSAR' then 'ANSAL'
		else stage_manufacturer_code_list
	end stage_manufacturer_code_list
from
(
	--Convert dates, numbers, and nulls.
	select
		nullif(stage_name, '-') stage_name,
		nullif(stage_family, 'Unknown') stage_family,
		replace(nullif(stage_manufacturer_code_list, '-'), '?') stage_manufacturer_code_list,
		nullif(stage_alt_name, '-') stage_alt_name,
		to_number(replace(replace(nullif(length, '-'), '?'), ',', '.')) length,
		to_number(replace(nullif(diameter, '-'), '?')) diameter,
		to_number(replace(nullif(launch_mass, '-'), '?')) launch_mass,
		to_number(replace(nullif(dry_mass, '-'), '?')) dry_mass,
		to_number(trim('s' from replace(nullif(thrust, '-'), '?'))) thrust,
		to_number(replace(nullif(duration, '-'), '?')) duration,
		nullif(engine, '-') engine_name,
		to_number(replace(nullif(engine_count, '-'), '?')) engine_count
	from
	(
		--Trim and project relevant columns.
		select
			trim(stage_name) stage_name,
			trim(stage_family) stage_family,
			trim(stage_manufacturer) stage_manufacturer_code_list,
			trim(stage_alt_name) stage_alt_name,
			trim(length) length,
			trim(diameter) diameter,
			trim(launch_mass) launch_mass,
			trim(dry_mass) dry_mass,
			trim(thrust) thrust,
			trim(duration) duration,
			trim(engine) engine,
			trim(neng) engine_count
		from stage_staging
		order by stage_name
	) trim_and_project
) convert
where
	--These stages aren't needed.
	stage_name is not null
	and stage_name <> '?'
	--These stages don't fully exist yet.
	and stage_name not in ('GEM-63')
	--These stages aren't used yet and don't match anything in Engines
	and stage_name not in ('Sidewinder 1C', 'TU-903')
order by stage_name;


--Launch Vehicle Stage
create or replace view launch_vehicle_stage_stng_view as
--Convert and decode.
select distinct
	lv_name,
	lv_variant,
	stage_no,
	stage_name,
	case when dummy = 'd' then 1 else 0 end is_dummy,
	to_number(case when multiplicity = 'F' then '1' else multiplicity end) multiplicity,
	to_number(stage_impulse) stage_impulse,
	to_number(stage_apogee) stage_apogee,
	to_number(stage_perigee) stage_perigee
from
(
	--Project and trim.
	select
		lv_mnemonic lv_name,
		nullif(lv_variant, '-') lv_variant,
		trim(stage_no) stage_no,
		stage_name,
		nullif(dummy, '-') dummy,
		trim(multiplicity) multiplicity,
		nullif(trim(stage_impulse), '-') stage_impulse,
		replace(trim(stage_apogee), '?') stage_apogee,
		replace(trim(stage_perigee), '?') stage_perigee
	from launch_vehicle_stage_staging
	where lv_mnemonic not in ('?', 'Unknown')
)
order by lv_name, stage_name;


--Reference.
--Commented out - not clean enough to use yet.
/*
--
--Remove the categories from the citations.
create or replace view reference_staging_view as
select citation, reference, reference_category
from
(
	--References with last category.
	select
		citation, reference,
		last_value(reference_category) ignore nulls over (order by line_number rows between unbounded preceding and current row) reference_category
	from
	(
		--Decode some broken category names, remove comments.
		select
			line_number,
			case
				when reference_category = 'New, and cryptic (s' then 'New, and cryptic'
				when reference_category = 'Personal communicat' then 'Personal communications'
				when reference_category = 'Journals and Book S' then 'Journals and Book Series'
				else reference_category
			end reference_category,
			citation,
			reference
		from
		(
			--References with trimmed category field.
			select
				rownum line_number,
				cite citation,
				reference,
				case when cite like '# %' then replace(cite, '# ') else null end reference_category
			from reference_staging
		) trim
		where citation <> '#'
	) decode
) reference_with_category
where citation not like '#%'
order by 1,2;
*/


--Site
create or replace view site_staging_view as
--Decode
select
	row_number() over (order by site_name, site_code) site_id,
	site_name, site_code, site_ucode,
	case
		when site_type is null then null
		when site_type = 'LS' then 'launch site'
		when site_type = 'LP' then 'launch point'
		when site_type = 'LC' then 'launch cruise'
		when site_type = 'LZ' then 'launch zone'
		else 'ERROR - Unexpected value "'||site_type||'"'
	end site_type,
	state_org_code, start_date, stop_date, site_short_name, site_full_name,
	site_location, longitude, latitude, degrees_uncertainty, parent_org_code_list
from
(
	--Project and convert relevant columns
	select
		site site_name,
		code site_code,
		nullif(ucode, '-') site_ucode,
		type site_type,
		statecode state_org_code,
		jsr_to_date(trim(':' from (nullif(tstart, '-')))) start_date,
		jsr_to_date(nullif(nullif(tstop, '-'), '*')) stop_date,
		shortname site_short_name,
		name site_full_name,
		nullif(location, '-') site_location,
		to_number(nullif(trim(longitude), '-')) longitude,
		to_number(nullif(trim(latitude), '-')) latitude,
		to_number(error) degrees_uncertainty,
		replace(nullif(parent, '-'), '?') parent_org_code_list
	from site_staging
	--Ignore empty rows
	where site <> '#'
		--Ignore TGT, which excludes NKAZ (OGCh target area, Novaya Kazanka, Kazakhstan),
		--which doens't show up in ALL anyway.
		and not (site = 'NKAZ' and type = 'TGT')
	order by site
) convert_and_project
order by 1,2;


--Platform
create or replace view platform_staging_view as
--Decode
select
	--Fix some typos and alignment issues.
	case
		when platform_code = 'DDG 174' then 'DDG-174'
		when platform_code = 'MiG31D-72 M' then 'MiG31D-72'
		else platform_code
	end platform_code,
	case
		when platform_ucode = 'DDG 174' then 'DDG-174'
		when platform_ucode = 'iG31D-72' then 'MiG31D-72'
		else platform_ucode
	end platform_ucode,
	platform_state_org_code,
	platform_type,
	case
		when platform_class is null then null
		when platform_class = 'A' then 'amateur/academic'
		when platform_class = 'B' then 'business'
		when platform_class = 'C' then 'civilian'
		when platform_class = 'D' then 'defense'
		else 'ERROR - Unexpected value "'||platform_class||'"'
	end platform_class,
	platform_shortname,
	platform_name,
	platform_parent_org_code
from
(
	--Project relevant columns.
	select
		code platform_code,
		ucode platform_ucode,
		statecode platform_state_org_code,
		type platform_type,
		class platform_class,
		shortname platform_shortname,
		name platform_name, 
		parent platform_parent_org_code
	from platform_staging
)
--Missing row:
union all
select 'B-52H', 'B-52H', 'US', 'AIR', 'defense', 'AIR   B-52H', 'B-52 Stratofortress', 'USAF'
from dual
where not exists (select * from platform_staging where code = 'B-52H')
order by 1,2;


--Launch
--
--Convert and decode columns.
create or replace view launch_staging_view as
select
	row_number() over (order by launch_tag) launch_id,
	launch_tag,
	jsr_to_date(launch_date) launch_date,
	case
		--Fix typos.
		when launch_tag = '2016-026' then 'Soyuz-2-1V'
		when launch_tag = '2017-002' then 'Kuaizhou'
		else lv_type
	end lv_type,
	case
		--Weird typo or missing staging data.
		--This is the most popular rocket, but there are so many versions.
		when lv_type = 'Falcon 9' and variant = 'FT' then 'FT5'
		else variant
	end variant,
	flight_id,
	flight,
	mission,
	flightcode,
	--Fix platform typos
	case
		when platform_code = 'INS' then 'INS-OPV'
		else platform_code
	end  platform_code,
	case
		--Recursive lookups using the SITE_UCODE.
		when launch_site = 'NIIP-5' then 'GIK-5'
		when launch_site = 'NIIP-53' then 'GIK-1'
		when launch_site = 'GNIIPV' then 'GIK-1'
		when launch_site = 'USC' then 'KASC'
		when launch_site = 'GTsMP-4' then 'GTsP-4'
		when launch_site = 'SDSC' then 'SHAR'
		when launch_site = 'GIP-53' then 'GNIIP'
		when launch_site = 'GTSP-4' then 'GTsP-4'
		when launch_site = 'SPFL' and launch_pad = 'LC47' then 'CCA'
		--Case.
		when launch_site = 'Vernon' then 'VERNON'
		else launch_site
	end launch_site,
	case
		--These look like typos
		when launch_pad = 'LC31/ShPU-12' then 'LC31/ShPu-12'
		when launch_pad = 'RW13     -> MFWA' then null
		--Remove the destinations.
		else trim(regexp_replace(launch_pad, '->.*', null))
	end launch_pad,
	apogee,
	range,
	agency_org_code_list,
	--Split into category and status
	case
		when substr(launch_code, 1, 1) = 'O' then 'orbital'
		when substr(launch_code, 1, 1) = 'M' then 'miltary missile'
		when substr(launch_code, 1, 1) = 'T' then 'test rocket'
		when substr(launch_code, 1, 1) = 'A' then 'atmospheric rocket'
		when substr(launch_code, 1, 1) = 'S' then 'suborbital rocket'
		when substr(launch_code, 1, 1) = 'D' then 'deep space'
		--These are my guesses
		when substr(launch_code, 1, 1) = 'H' then 'sounding rocket'
		when substr(launch_code, 1, 1) = 'R' then 'ballistic missile test'
		when substr(launch_code, 1, 1) = 'X' then 'lunar return'
		when substr(launch_code, 1, 1) = 'Y' then 'suborbital spaceplane'
		when substr(launch_code, 1, 1) = '-' then null
		else 'ERROR - Unexpected value "'||substr(launch_code, 1, 1)||'"'
	end launch_category,
	case
		when substr(launch_code, 2, 1) = 'S' then 'success'
		when substr(launch_code, 2, 1) = 'F' then 'failure'
		when substr(launch_code, 2, 1) = 'U' then 'unknown'
		--My guesses:
		when substr(launch_code, 2, 1) in ('E', 'D') then 'destroyed before launch'
		else 'ERROR - Unexpected value "'||substr(launch_code, 2, 1)||'"'
	end launch_status,
	--Split into payload_org_list, payload_principle_investigators
	case
		when payload_group is null then null
		when payload_group like 'AFSPC%' then 'AFSPC/'
		when payload_group like 'NROL%' then 'NRO/'
		--Get everything before the last slash
		else regexp_replace(payload_group, '(.*)/(.*)', '\1')
	end payload_group,
	case
		when payload_group is null then null
		when payload_group like 'AFSPC%' then 'AFSPC/'
		when payload_group like 'NROL%' then 'NRO/'
		--Get everything after the last slash
		else regexp_replace(payload_group, '(.*)/(.*)', '\2')
	end payload_investigators,
	category_list flight_type,
	--Combine the citations for simplicity.
	case
		when ltcite is not null and cite is not null then ltcite || '/' || cite
		else ltcite || cite
	end cite_list
from
(
	--Project and cleanup relevant columns
	select
		launch_tag,
		launch_jd,
		launch_date,
		lv_type,
		replace(nullif(variant, '-'), '?') variant,
		replace(nullif(flight_id, '-'), '?') flight_id,
		replace(nullif(flight, '-'), '?') flight,
		nullif(mission, '-') mission,
		nullif(flightcode, '-') flightcode,
		replace(nullif(trim(platform), '-'), '?') platform_code,
		trim(replace(launch_site, '?')) launch_site,
		replace(nullif(launch_pad, '-'), '?') launch_pad,
		nullif(trim(apogee), '-') apogee,
		nullif(trim(range), '-') range,
		--Value is not fully supported in JSR yet.
		--replace(replace(replace(nullif(dest, '-'), '?'), '('), ')') dest,
		replace(agency, '?') agency_org_code_list,
		launch_code,
		case
			--Looks like a formatting problem.
			when payload_group like '-       %' then null
			else replace(nullif(payload_group, '-'), '?')
		end payload_group,
		category category_list,
		nullif(ltcite, '-') ltcite,
		nullif(cite, '-') cite
	from launch_staging
	order by launch_tag
)
--Exclude unknonw debris.
where (flight is null or flight <> 'Entry for unknown debris')
order by launch_id;


--Satellite.
--
create or replace view satellite_staging_view as
--Decode and convert.
select
	substr(satcat, 2) norad,
	case
		when regexp_like(cospar, '^[0-9][0-9][0-9][0-9]') then regexp_replace(trim(cospar), '[A-Z]', null)
		when regexp_like(cospar, '^[0-9][0-9] ') then
			'19' ||
			--Greek letter replacements.
			replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(
			replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(
				--Remove number at end.
				regexp_replace(cospar, ' [0-9]*$')
			, 'Alpha', 'ALP')
			, 'Beta', 'BET')
			, 'Gamma', 'GAM')
			, 'Delta', 'DEL')
			, 'Epsilon', 'EPS')
			, 'Zeta', 'ZET')
			, 'Iota', 'IOT')
			, 'Kappa', 'KAP')
			, 'Lambda', 'LAM')
			, 'Theta', 'THE')
			, 'Mu', 'MU')
			, 'Nu', 'NU')
			, 'Xi', 'XI')
			, 'Omicron', 'OMI')
			, 'Rho', 'RHO')
			, 'Sigma', 'SIG')
			, 'Tau', 'TAU')
			, 'Pi', 'PI')
			, 'Omega', 'OME')
			, 'Psi', 'PSI')
			, 'Eta', 'ETA')
			, 'Upsilon', 'UPS')
			, 'Phi', 'PHI')
			, 'Chi', 'CHI')
		else cospar
	end sat_launch_tag,
	cospar,
	official_name,
	secondary_name,
	jsr_to_date(launch_date) launch_date,
	current_status,
	jsr_to_date(status_date) status_date,
	jsr_to_date(orbit_date) orbit_date,
	to_number(regexp_substr(numbers, '[-0-9.]+', 1, 1)) orbit_period,
	to_number(regexp_substr(numbers, '[-0-9.]+', 1, 2)) perigee,
	to_number(regexp_substr(numbers, '[-0-9.]+', 1, 3)) apogee,
	to_number(regexp_substr(numbers, '[-0-9.]+', 1, 4)) inclination,
	orbit_class,
	owner_operator_org_code_list
from
(
	--Project and cleanup relevant columns
	select
		satcat,
		cospar,
		replace(nullif(official_name, '-'), '?') official_name,
		replace(nullif(secondary_name, '-'), '?') secondary_name,
		launch_date,
		current_status,
		status_date,
		orbit_date,
		replace(replace(numbers, '-'), 'x') numbers,
		orbit_class,
		replace(owner_operator, '?') owner_operator_org_code_list
	from satellite_staging
	--Ignore some empty rows:
	where cospar is not null
	order by satcat
)
--Ignore satellite data that is later than the latest launch data.
where jsr_to_date(launch_date) < date '2017-09-07'
order by satcat;



--------------------------------------------------------------------------------
--#7. Create presentation tables.
--------------------------------------------------------------------------------


--ORGANIZATION
create table organization compress as
select org_code, org_name, org_class, parent_org_code, org_state_code, org_location, org_start_date, org_stop_date, org_utf8_name
from organization_staging_view
order by 1,2;

insert into organization(org_code, org_name, org_class, parent_org_code, org_state_code, org_location, org_start_date, org_stop_date, org_utf8_name)
values ('CMIK', 'Choson MIK', 'defense', 'KPA', 'KP', 'Pyongyang', null, null, 'Choson MIK');
commit;

alter table organization add constraint organization_pk primary key (org_code);


--ORGANIZATION_ORG_TYPE (bridge table)
create table organization_org_type compress as
select org_code, org_types.org_type
from organization_staging_view
join
(
	--Mapping of ORG_TYPE list to readable org_type values.
	select
		org_type org_type_list,
		case
			when column_value = null then null
			when column_value = 'AP' then 'astronomical polity'
			when column_value = 'CC' then 'control center'
			when column_value = 'CY' then 'country'
			when column_value = 'E' then 'engine/motor manufacturer'
			when column_value = 'IGO' then 'intergovernmental organization'
			when column_value = 'LA' then 'launch agency'
			when column_value = 'LS' then 'launch site'
			when column_value = 'LV' then 'launch vehicle manufacturer'
			when column_value = 'MET' then 'meteorological'
			when column_value = 'O' then 'organization'
			when column_value = 'PL' then 'satellite manufacturer'
			when column_value = 'S' then 'school'
			else 'ERROR - Unexpected value "'||column_value||'"'
		end org_type
	from
	(
		--Mapping of org_type list to individual values.
		select org_type, column_value
		from
		(
			--Get distinct org_types (we don't want to cross-join them all).
			select distinct org_type
			from organization_staging_view
		), get_nt_from_list(org_type, '/')
	)
	order by 1,2
) org_types
	on organization_staging_view.org_type = org_types.org_type_list
order by 1,2;

create unique index organization_org_type_idx on organization_org_type(org_code, org_type) compress 1;
alter table organization_org_type add constraint organization_org_fk foreign key (org_code) references organization(org_code);


--LAUNCH_VEHICLE_FAMILY
create table launch_vehicle_family compress as
select lv_family_code, lv_family_class
from launch_vehicle_family_stagng_v
order by 1, 2;

alter table launch_vehicle_family add constraint launch_vehicle_family_pk primary key (lv_family_code);


--LAUNCH_VEHICLE
create table launch_vehicle compress as
select
	row_number() over (order by lv_name, lv_variant) lv_id,
	lv_name, lv_variant, lv_class, lv_family_code, lv_alias, min_stage, max_stage,
	length, diameter, launch_mass, leo_capacity, gto_capacity, take_off_thrust,
	apogee, range
from launch_vehicle_staging_view
order by 1,2;

alter table launch_vehicle add constraint launch_vehicle_pk primary key (lv_id);
alter table launch_vehicle add constraint launch_vehicle_uj unique (lv_name, lv_variant);
alter table launch_vehicle add constraint launch_vehicle_family_fk foreign key (lv_family_code) references launch_vehicle_family(lv_family_code);
create index launch_vehicle_idx1 on launch_vehicle(lv_family_code);


--LAUNCH_VEHICLE_MANUFACTURER (bridge_table)
create table launch_vehicle_manufacturer compress as
select
	lv_id,
	case
		--A few weird cases:
		--#1: The ICBM-T2 manufacturer is listed as "Minuteman".
		--Should it be "OATK" (Orbital ATK) instead?
		--#2: Should BLDT launch vehicle's manufacturer be LARCN instead of BLDT?  BLDT is not in Org.
		--Based on: https://ntrs.nasa.gov/archive/nasa/casi.ntrs.nasa.gov/19740023231.pdf
		when org_codes.column_value = 'Minuteman' then 'OATK'
		when org_codes.column_value = 'BLDT' then 'LARCN'
		else org_codes.column_value
	end lv_manufacturer_org_code
from launch_vehicle
join launch_vehicle_staging_view
	on launch_vehicle.lv_name = launch_vehicle_staging_view.lv_name
	and nvl(launch_vehicle.lv_variant, 'none') = nvl(launch_vehicle_staging_view.lv_variant, 'none')
join
(
	--Mapping of org code lists to individual values.
	select lv_manufacturer_org_codes, column_value
	from
	(
		--Get distinct org_types (we don't want to cross-join them all).
		select distinct lv_manufacturer_org_codes
		from launch_vehicle_staging_view
	), get_nt_from_list(lv_manufacturer_org_codes, '/')
	order by 1,2
) org_codes
	on launch_vehicle_staging_view.lv_manufacturer_org_codes = org_codes.lv_manufacturer_org_codes
order by 1,2;

alter table launch_vehicle_manufacturer add constraint launch_vehicle_man_org_pk primary key (lv_id, lv_manufacturer_org_code);
alter table launch_vehicle_manufacturer add constraint launch_vehicle_man_org_fk foreign key (lv_manufacturer_org_code) references organization(org_code);
create index launch_vehicle_manufacturer_idx1 on launch_vehicle_manufacturer(lv_manufacturer_org_code);


--PROPELLENT
create table propellent compress as
select
	row_number() over (order by propellent_name) propellent_id,
	propellent_name
from
(
	select distinct column_value propellent_name
	from
	(
		--All chemicals
		select oxidizer_list propellent_list
		from engine_staging_view
		union
		select fuel_list propellent_list
		from engine_staging_view
	)
	cross join get_nt_from_list(propellent_list, '/')
)
order by propellent_name;

alter table propellent add constraint propellent_pk primary key (propellent_id);
alter table propellent add constraint propellent_uk unique (propellent_name);


--ENGINE
create table engine compress as
select
	row_number() over (order by engine_name, engine_family, engine_alt_name, first_launch_year, usage) engine_id,
	engine_name,
	engine_family,
	engine_alt_name,
	first_launch_year,
	usage,
	mass,
	impulse,
	thrust,
	specific_impulse,
	duration,
	chambers chamber_count
from engine_staging_view
order by engine_id;

alter table engine add constraint engine_pk primary key (engine_id);


--ENGINE_PROPELLENT (bridge table)
create table engine_propellent compress as
--Propellents
with propellent_list_and_id as
(
	--Propellent lists with propellent_ids.
	select propellent_list, propellent_id
	from
	(
		--Propellent lists expanded.
		select propellent_list, column_value propellent_name
		from
		(
			--All propellent lists.
			select oxidizer_list propellent_list
			from engine_staging_view
			union
			select fuel_list propellent_list
			from engine_staging_view
		)
		cross join get_nt_from_list(propellent_list, '/')
	) propellent_lists
	join propellent
		on propellent_lists.propellent_name = propellent.propellent_name
),
--Engines
engines as
(
	select
		dense_rank() over (order by engine_name, engine_family, engine_alt_name, first_launch_year, usage) engine_id,
		oxidizer_list,
		fuel_list
	from engine_staging_view
)
--Oxidizers
select engine_id, propellent_id, 'oxidizer' oxidizer_or_fuel
from engines
join propellent_list_and_id
	on engines.oxidizer_list = propellent_list_and_id.propellent_list
union all
--Fuels
select engine_id, propellent_id, 'fuel' oxidizer_or_fuel
from engines
join propellent_list_and_id
	on engines.fuel_list = propellent_list_and_id.propellent_list
order by 1,2,3;

alter table engine_propellent add constraint engine_propellent_pk primary key (engine_id, propellent_id, oxidizer_or_fuel);
alter table engine_propellent add constraint engine_propellent_engine_fk foreign key (engine_id) references engine(engine_id);
alter table engine_propellent add constraint engine_propellent_prop_fk foreign key (propellent_id) references propellent(propellent_id);
create index engine_propellent_idx1 on engine_propellent(propellent_id);


--ENGINE_MANUFACTURER (bridge table)
create table engine_manufacturer compress as
select engine_id, column_value manufacturer_org_code
from
(
	select
		dense_rank() over (order by engine_name, engine_family, engine_alt_name, first_launch_year, usage) engine_id,
		engine_manufacturer_code_list
	from engine_staging_view
) engines
cross join get_nt_from_list(engine_manufacturer_code_list, '/')
order by 1,2;

alter table engine_manufacturer add constraint engine_manufacturer_pk primary key (engine_id, manufacturer_org_code);
alter table engine_manufacturer add constraint engine_manufacturer_engine_fk foreign key (engine_id) references engine(engine_id);
alter table engine_manufacturer add constraint engine_manufacturer_manuf_fk foreign key (manufacturer_org_code) references organization(org_code);
create index engine_manufacturer_idx1 on engine_manufacturer(manufacturer_org_code);


--STAGE
create table stage compress as
select stage_name, stage_family, stage_alt_name, length, diameter, launch_mass, dry_mass,
	stage_staging_view.thrust, stage_staging_view.duration, engine_id, engine_count
from stage_staging_view
left join engine
	on stage_staging_view.engine_name = engine.engine_name
--Manually adjust some joins, based on names.
--When it's still ambiguous, choose the engine with either more complete numbers or higher numbers.
--(On the assumption that the the engine actually used would have more information and higher values.)
where not
(
	(stage_name = '11S86'           and usage = 'Blok D-1') or
	(stage_name = '11S861'          and usage = 'Blok D-1') or
	(stage_name = '11S861-01'       and usage = 'Blok D-1') or
	(stage_name = '11S861-03'       and usage = 'Blok D-1') or
	(stage_name = '17S40'           and usage = 'Blok DM') or
	(stage_name = 'Arcas'           and first_launch_year is null) or
	(stage_name = 'Blok DM-SL'      and usage = 'Blok D-1') or
	(stage_name = 'Blok DM-SLB'     and usage = 'Blok D-1') or
	(stage_name = 'Blok DM1'        and usage = 'Blok D-1') or
	(stage_name = 'Blok DM3'        and usage = 'Blok D-1') or
	(stage_name = 'Blok DM4'        and usage = 'Blok D-1') or
	(stage_name = 'CZ-4 Stage 3'    and usage = 'CZ-4B (3)') or
	(stage_name = 'CZ-4B Stage 3'   and usage = 'CZ-4B (3)') or
	(stage_name = 'Dragon V2'       and usage = 'Dragon') or
	(stage_name = 'FB-1 Stage 2'    and usage = 'CZ-2 Stage 2 vernier') or
	(stage_name = 'Frangible Arcas' and impulse is null) or
	(stage_name = 'GEM-60'          and first_launch_year = 2002) or
	(stage_name = 'H-II SSB'        and first_launch_year is null) or
	(stage_name = 'Hydac'           and engine_alt_name = 'H-28') or
	(stage_name = 'Improved Orion'  and first_launch_year is null) or
	(stage_name = 'M-34'            and usage = 'M-V [3]') or
	(stage_name = 'RT-23 St 3'      and usage is null) or
	(stage_name = 'SDC Viper'       and engine_alt_name is null) or
	(stage_name = 'Star 48B'        and usage = 'STS PAM-D') or
	(stage_name = 'Star 48B AKM'    and usage = 'STS PAM-D') or
	(stage_name = 'Taurion'         and first_launch_year is null) or
	(stage_name = 'X-15'            and engine_alt_name is null)
)
order by stage_name;

alter table stage add constraint stage_pk primary key (stage_name);
alter table stage add constraint stage_engine_fk foreign key (engine_id) references engine(engine_id);
create index stage_idx1 on stage(engine_id);


--STAGE_MANUFACTURER (bridge table)
create table stage_manufacturer compress as
select stage_name, column_value manufacturer_org_code
from stage_staging_view
cross join get_nt_from_list(stage_manufacturer_code_list, '/')
order by 1,2;

alter table stage_manufacturer add constraint stage_manufacturer_pk primary key (stage_name, manufacturer_org_code);
alter table stage_manufacturer add constraint stage_manufacturer_stage_fk foreign key (stage_name) references stage(stage_name);
alter table stage_manufacturer add constraint stage_manufacturer_manuf_fk foreign key (manufacturer_org_code) references organization(org_code);
create index stage_manufacturer_idx1 on stage_manufacturer(manufacturer_org_code);


--LAUNCH_VEHICLE_STAGE (bridge table plus other columns)
create table launch_vehicle_stage compress as
select
	(
		select lv_id
		from launch_vehicle
		where launch_vehicle.lv_name = launch_vehicle_stage_stng_view.lv_name
			and nvl(launch_vehicle.lv_variant, 'none') = nvl(launch_vehicle_stage_stng_view.lv_variant, 'none')
	) lv_id,
	--Should I use the stage_id here instead?
	(
		select stage_name
		from stage
		where stage.stage_name = launch_vehicle_stage_stng_view.stage_name
	) stage_name,
	stage_no, is_dummy, multiplicity, stage_impulse, stage_apogee, stage_perigee
from launch_vehicle_stage_stng_view
--Ignore fairings and payloads
where stage_no not in ('F', 'P')
order by lv_id, stage_name;

alter table launch_vehicle_stage add constraint launch_vehicle_stage_pk primary key (lv_id, stage_name, stage_no);
alter table launch_vehicle_stage add constraint launch_vehicle_stage_fk1 foreign key (lv_id) references launch_vehicle(lv_id);
alter table launch_vehicle_stage add constraint launch_vehicle_stage_fk2 foreign key (stage_name) references stage(stage_name);
create index launch_vehicle_stage_idx1 on launch_vehicle_stage(lv_id);
create index launch_vehicle_stage_idx2 on launch_vehicle_stage(stage_name);


--REFERENCE.
--Commented out - data is not clean enough yet.
/*
create table reference compress as
--Use distinct to avoid two duplicates:  "AWST960401-28" and "www.lapan.go.id".
select distinct citation, reference, reference_category
from reference_staging_view
order by 1,2;

alter table reference add constraint reference_pk primary key (citation);
*/


--SITE
create table site compress as
select
	site_id,
	site_name,
	site_code,
	site_type,
	state_org_code,
	start_date,
	stop_date,
	site_short_name,
	site_full_name,
	site_location,
	longitude,
	latitude,
	degrees_uncertainty
from site_staging_view
order by 1,2;

alter table site add constraint site_pk primary key (site_id);
alter table site add constraint site_organization_fk foreign key (state_org_code) references organization(org_code);
create index site_idx on site(state_org_code);


--SITE_ORGANIZATION (bridge table)
create table site_organization compress as
--Fix some mistakes
select
	site_id,
	case
		when org_code = 'BLORIG' then 'BLOR'
		when org_code = 'DDR' then 'DD'
		when org_code = 'Luna' then 'LUNA'
		when org_code = 'NRC' then 'NRCC'
		when org_code = 'OTRAG' then 'OTRG'
		when org_code = 'ROCKL' then 'RLABN'
		when org_code = 'SCALED' then 'SCAL'
		when org_code = 'Yemen' then 'YE'
		else org_code			
	end org_code
from
(
	--Split the codes
	select site_id, column_value org_code
	from site_staging_view
	cross join get_nt_from_list(parent_org_code_list, '/')
) codes
order by 1,2;

alter table site_organization add constraint site_organization_pk primary key (site_id, org_code);
alter table site_organization add constraint site_org_site_fk foreign key(site_id) references site(site_id);
alter table site_organization add constraint site_org_org_fk foreign key(org_code) references organization(org_code);


--PLATFORM
create table platform compress as
select
	platform_code,
	platform_ucode,
	platform_state_org_code,
	platform_type,
	platform_class,
	platform_shortname platform_short_name,
	platform_name,
	platform_parent_org_code
from platform_staging_view
order by 1,2;

alter table platform add constraint platform_pk primary key (platform_code);
alter table platform add constraint platform_state_fk foreign key (platform_state_org_code) references organization(org_code);
alter table platform add constraint platform_parent_fk foreign key (platform_parent_org_code) references organization(org_code);
create index platform_idx1 on platform(platform_state_org_code);
create index platform_idx2 on platform(platform_parent_org_code);


--LAUNCH:
create table launch compress as
select
	launch_id,
	launch_tag,
	launch_date,
	launch_category,
	launch_status,
	(
		select lv_id
		from launch_vehicle
		where launch_vehicle.lv_name = launch_staging_view.lv_type
			and nvl(launch_vehicle.lv_variant, 'none') = nvl(launch_staging_view.variant, 'none')
	) lv_id,
	flight_id flight_id1,
	flight flight_id2,
	mission,
	flightcode,
	flight_type,
	(
		select site_id
		from site
		where site.site_name = launch_staging_view.launch_site
			and nvl(site.site_code, 'none') = nvl(launch_staging_view.launch_pad, 'none')
	) site_id,
	platform_code,
	apogee
	--Column is not populated often enough to be worth including:
	--range
from launch_staging_view
--Order by launch_category.  (I don't want Wehrmacht launches to show up first, even if they were the first.)
order by
	case
		when launch_category = 'orbital'                then 1
		when launch_category = 'deep space'             then 2
		when launch_category = 'lunar return'           then 3
		when launch_category = 'suborbital spaceplane'  then 4
		when launch_category = 'suborbital rocket'      then 5
		when launch_category = 'atmospheric rocket'     then 6
		when launch_category = 'sounding rocket'        then 7
		when launch_category = 'test rocket'            then 8
		when launch_category = 'ballistic missile test' then 9
		when launch_category = 'miltary missile'        then 10
		else 999999
	end,
	launch_tag
;

alter table launch add constraint launch_pk primary key(launch_id);
alter table launch add constraint launch_lv_fk foreign key(lv_id) references launch_vehicle(lv_id); 
alter table launch add constraint launch_site_fk foreign key(site_id) references site(site_id);
alter table launch add constraint launch_platform_fk foreign key(platform_code) references platform(platform_code);
create index launch_idx1 on launch(lv_id);
create index launch_idx2 on launch(site_id);
create index launch_idx3 on launch(platform_code);
create index launch_idx4 on launch(launch_tag);


--LAUNCH_AGENCY (bridge table)
create table launch_agency compress as
select launch_id, column_value agency_org_code
from launch_staging_view
cross join get_nt_from_list(agency_org_code_list, '/')
order by 1,2;

alter table launch_agency add constraint launch_agency_pk primary key (launch_id, agency_org_code);
alter table launch_agency add constraint launch_agency_launch_fk foreign key (launch_id) references launch(launch_id);
alter table launch_agency add constraint launch_agency_org_fk foreign key (agency_org_code) references organization(org_code);


--LAUNCH_PAYLOAD_ORG (bridge table)
create table launch_payload_org compress as
select
	launch_id,
	case
		when column_value = '91SMW' then '91MW'
		else column_value
	end payload_org_code
from launch_staging_view
cross join get_nt_from_list(payload_group, '/')
order by 1,2;

alter table launch_payload_org add constraint launch_payload_org_pk primary key (launch_id, payload_org_code);
alter table launch_payload_org add constraint launch_payload_org_launch_fk foreign key (launch_id) references launch(launch_id);
alter table launch_payload_org add constraint launch_payload_org_org_fk foreign key (payload_org_code) references organization(org_code);


--Satellite
create table satellite compress as
select
	--Remote S to make it a real norad satellite catalog identifier.
	norad,
	cospar,
	official_name,
	secondary_name,
	(
		select launch_id
		from launch
		where launch.launch_tag = satellite_staging_view.sat_launch_tag
	) launch_id,
	current_status,
	status_date,
	orbit_date,
	orbit_period,
	perigee,
	apogee,
	inclination,
	case
		when orbit_class is null then null
		when orbit_class = 'ATM' then 'Atmospheric'
		when orbit_class = 'TAO' then 'Trans-Atm.'
		when orbit_class = 'SO' then 'Suborbital'
		when orbit_class = 'LEO/E' then 'Equatorial'
		when orbit_class = 'LEO/I' then 'Intermediate'
		when orbit_class = 'LEO/P' then 'Polar'
		when orbit_class = 'LEO/S' then 'Sun-Synch'
		when orbit_class = 'LEO/R' then 'Retrograde'
		when orbit_class = 'MEO' then 'Medium'
		when orbit_class = 'HEO' then 'Highly Ellip'
		when orbit_class = 'HEO/M' then 'Molniya'
		when orbit_class = 'GTO' then 'GEO Transfer'
		when orbit_class = 'GEO/S' then 'Stationary'
		when orbit_class = 'GEO/I' then 'Inclined GEO'
		when orbit_class = 'GEO/T' then 'Synchronous'
		when orbit_class = 'GEO/D' then 'Drift GEO'
		when orbit_class = 'GEO/SI' then 'Inclined GEO'
		when orbit_class = 'GEO/DR' then 'Drift GEO'
		when orbit_class = 'GEO/ID' then 'Inclined Drift'
		when orbit_class = 'GEO/NS' then 'Near-synch'
		when orbit_class = 'DSO' then 'Deep Space'
		when orbit_class = 'DHEO' then 'Deep Eccentric'
		when orbit_class = 'CLO' then 'Cislunar'
		when orbit_class = 'EEO' then 'Earth Escape'
		when orbit_class = 'HCO' then 'Heliocentric'
		when orbit_class = 'PCO' then 'Planetocentric'
		when orbit_class = 'PEO' then 'Planetary escape trajectory'
		when orbit_class = 'SSE' then 'Solar System Escape'
		when orbit_class = 'VHEO' then 'Very High'
		else 'ERROR - Unexpected value "'||orbit_class||'"'
	end orbit_class
from satellite_staging_view
order by norad;

alter table satellite add constraint satellite_pk primary key (norad);
alter table satellite add constraint satellite_fk foreign key(launch_id) references launch(launch_id);
create index satellite_idx1 on satellite(launch_id);


--SATELLITE_ORG
create table satellite_org compress as
select distinct
	norad,
	case
		when column_value = 'COMDE' then 'COMDEV'
		when column_value = 'SURRE' then 'SURREY'
		else column_value
	end owner_operator_org_code
from satellite_staging_view
cross join get_nt_from_list(owner_operator_org_code_list, '/')
order by norad, owner_operator_org_code;

alter table satellite_org add constraint satellite_org_pk primary key(norad, owner_operator_org_code);
alter table satellite_org add constraint satellite_org_sat_fk foreign key(norad) references satellite(norad);
alter table satellite_org add constraint satellite_org_org_fk foreign key(owner_operator_org_code) references organization(org_code);



--------------------------------------------------------------------------------
--#8. Validate staging data and views.
--------------------------------------------------------------------------------

--The validation statements are setup so that returning zero rows means success.
begin
	--TODO:
	null;
end;
/

--Missing LV_IDs.  This should return no rows.
select launch_staging_view.*
from launch
join launch_staging_view
	on launch.launch_id = launch_staging_view.launch_id
where lv_id is null;

--Do all launches have a valid site?
select * from launch where site_id is null order by launch_id;

--Do all the satellites have a valid launch_id?  (With the exception of "Unknown Oko debris".
select * from satellite where launch_id is null;
