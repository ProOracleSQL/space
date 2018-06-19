/*

This is all very experimental, do not use this yet.

This file is meant to download, load, and transform the awesome JSR Launch Vehicle Database into an Oracle database.

*/



--------------------------------------------------------------------------------
--#1: Create ACLs to enable downloading files from the internet.
--From Mark Harrison: https://dba.stackexchange.com/a/115110/3336
--------------------------------------------------------------------------------
begin
    dbms_network_acl_admin.create_acl(
        acl         => 'www',
        description => 'WWW ACL',
        principal   => user,
        is_grant    => true,
        privilege   => 'connect'
    );

    dbms_network_acl_admin.assign_acl(
        acl        => 'www',
        host       => '*',
        lower_port => 80
    );
end;
/

--This step is oddly buggy.  Sometimes you need to delete and recreate ACLs.
/*
begin
	dbms_network_acl_admin.drop_acl('WWW');
end;
/
*/



--------------------------------------------------------------------------------
--#2: Create procedure to download files from the Internet.
--From Tim Hall: https://oracle-base.com/articles/misc/retrieving-html-and-binaries-into-tables-over-http
--------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION get_clob_from_url(p_url  IN  VARCHAR2) RETURN CLOB AS
  l_http_request   UTL_HTTP.req;
  l_http_response  UTL_HTTP.resp;
  l_clob           CLOB;
  l_text           VARCHAR2(32767);
BEGIN
  -- Initialize the CLOB.
  DBMS_LOB.createtemporary(l_clob, FALSE);

  -- Make a HTTP request and get the response.
  l_http_request  := UTL_HTTP.begin_request(p_url);
  l_http_response := UTL_HTTP.get_response(l_http_request);

  -- Copy the response into the CLOB.
  BEGIN
    LOOP
      UTL_HTTP.read_text(l_http_response, l_text, 32766);
      DBMS_LOB.writeappend(l_clob, LENGTH(l_text), l_text);
    END LOOP;
  EXCEPTION
    WHEN UTL_HTTP.end_of_body THEN
      UTL_HTTP.end_response(l_http_response);
  END;

  -- Return the data.
  RETURN l_clob;

EXCEPTION
  WHEN OTHERS THEN
    UTL_HTTP.end_response(l_http_response);
    DBMS_LOB.freetemporary(l_clob);
    RAISE;
END get_clob_from_url;
/



--------------------------------------------------------------------------------
--#3: Create table to hold files.
--------------------------------------------------------------------------------
create table space_files
(
	url            varchar2(4000) not null,
	name           varchar2(100) not null,
	date_retrieved date not null,
	contents       clob not null
);



--------------------------------------------------------------------------------
--#4: Download and store relevant files.
--------------------------------------------------------------------------------
declare
	v_url varchar2(4000);
	v_clob clob;
begin
	v_url := 'http://planet4589.org/space/log/launchlog.txt';
	insert into space_files values(v_url, 'launch_log', sysdate, get_clob_from_url(v_url));
	commit;

	v_url := 'http://planet4589.org/space/log/satcat.txt';
	insert into space_files values(v_url, 'satcat', sysdate, get_clob_from_url(v_url));
	commit;

end;
/



--------------------------------------------------------------------------------
--#5: Create staging tables.
--------------------------------------------------------------------------------

create table launch_staging
(
	line_number           number,
	launch                varchar2(13),
	launch_date           date,
	cospar                varchar2(21),
	payload_name          varchar2(31),
	original_payload_name varchar2(26),
	satcat                varchar2(9),
	vehicle_type          varchar2(23),
	vehicle_serial_number varchar2(16),
	site                  varchar2(33),
	success               varchar2(5),
	reference             varchar2(20)
) compress nologging;

comment on table launch_staging is 'See this webiste for a description of the data: http://planet4589.org/space/log/satcat.html.';


create table satellite_staging
(
	line_number    number not null,
	satcat         varchar2(7),
	cospar         varchar2(23),
	official_name  varchar2(40),
	secondary_name varchar2(24),
	owner_operator varchar2(12),
	launch_date    date,
	current_status varchar2(16),
	status_date    date,
	orbit_date     date,
	orbit_class    varchar2(8),
	orbit_period   number,
	perigee        number,
	apogee         number,
	inclination    number
) compress nologging;

comment on table satellite_staging is 'See this website for a description of the data: http://planet4589.org/space/log/satcat.html';



--------------------------------------------------------------------------------
--#6: Transform files.
--This processes everything in PL/SQL.  For larger data sets it might be better
--to use external tables.  I don't do that to avoid a filesystem dependency.
--------------------------------------------------------------------------------
declare
	---------------------------------------
	--Load launch data.
	procedure load_launch_staging is
		v_launch_log clob;
		v_last_position number := 0;
		v_position number := 0;
		v_line_number number := 0;
		v_line varchar2(32767);
	begin
		--Get file.
		select contents into v_launch_log from space_files where name = 'launch_log';

		--Loop through lines and process them.
		loop
			v_line_number := v_line_number + 1;
			v_last_position := v_position;
			v_position := dbms_lob.instr(lob_loc => v_launch_log, pattern => chr(10), nth => v_line_number);
			exit when v_position = 0; --For testing: or v_line_number >= 500;

			--Process everything after the first two header lines.
			if v_line_number >= 3 then
				v_line := dbms_lob.substr(lob_loc => v_launch_log, amount => v_position - v_last_position - 1, offset => v_last_position + 1);

				begin
					insert into launch_staging
					values(
						v_line_number,
						trim(substr(v_line, 1, 13)),
						--Cleanup and format the date.  Ignore any question marks.
						to_date(replace(trim(substr(v_line, 14, 21)), '?'), 'YYYY Mon DD HH24MI:ss'),
						trim(substr(v_line, 35, 21)),
						trim(substr(v_line, 56, 31)),
						trim(substr(v_line, 87, 26)),
						trim(substr(v_line, 113, 9)),
						trim(substr(v_line, 122, 23)),
						trim(substr(v_line, 145, 16)),
						trim(substr(v_line, 161, 33)),
						trim(substr(v_line, 194, 5)),
						trim(substr(v_line, 199))
					);
				exception when others then
					raise_application_error(-20000, 'Error with this line: '||v_line||chr(10)||
						sys.dbms_utility.format_error_stack||sys.dbms_utility.format_error_backtrace);
				end;
			end if;
		end loop;

		--Commit and compress data.
		commit;
		execute immediate 'alter table launch_staging move';
	end load_launch_staging;

	---------------------------------------
	--Load satellite data.
	procedure load_satellite_staging is
		v_satcat clob;
		v_last_position number := 0;
		v_position number := 0;
		v_line_number number := 0;
		v_line varchar2(32767);
		v_satcat_number varchar2(7);
	begin
		--Get file.
		select contents into v_satcat from space_files where name = 'satcat';

		--Loop through lines and process them.
		loop
			v_line_number := v_line_number + 1;
			v_last_position := v_position;
			v_position := dbms_lob.instr(lob_loc => v_satcat, pattern => chr(10), nth => v_line_number);
			exit when v_position = 0; --TEST or v_line_number >= 5000;

			v_line := dbms_lob.substr(lob_loc => v_satcat, amount => v_position - v_last_position - 1, offset => v_last_position + 1);

			begin
				v_satcat_number := trim(substr(v_line, 1, 7));

				--Special cases for rows that are formatted incorrectly.
				if v_satcat_number = 'S003066' then
						insert into satellite_staging values (v_line_number, 'S003066','1967-123A','Pioneer 8','Pioneer C','NASA',date '1967-12-13','Deep Space',date '1968-01-16',date '1967-12-13','EEO',611979.10,484,-4788696,32.89);
				else
					insert into satellite_staging
					values(
						v_line_number,
						v_satcat_number, --satcat
						trim(substr(v_line, 9, 14)), --cospar
						trim(substr(v_line, 24, 40)), --official_name
						trim(substr(v_line, 65, 24)), --secondary_name
						trim(substr(v_line, 90, 12)), --owner_operator
						case
							when length(replace(trim(substr(v_line, 103, 11)), '?')) = 4 then
								to_date(replace(trim(substr(v_line, 103, 11)), '?') || '0101', 'YYYYMMDD')
							else
								to_date(replace(trim(substr(v_line, 103, 11)), '?'), 'YYYY Mon DD')
						end, --launch_date
						trim(substr(v_line, 115, 16)), --current_status
						--If only the year is given, use January 1 as the date.
						--Ignore '-'.
						case
							when length(replace(trim(substr(v_line, 132, 12)), '?')) = 4 then
								to_date(replace(trim(substr(v_line, 132, 12)), '?') || '0101', 'YYYYMMDD')
							when length(replace(trim(substr(v_line, 132, 12)), '?')) = 8 then
								to_date(replace(trim(substr(v_line, 132, 12)), '?') || '01', 'YYYY MonDD')
							when replace(trim(substr(v_line, 132, 12)), '?') in ('1970s', '1990s') then
								null
							when replace(trim(substr(v_line, 132, 12)), '?') = '-' then
								null
							else
								to_date(replace(trim(substr(v_line, 132, 12)), '?'), 'YYYY Mon DD')
						end, --status_date
						to_date(replace(trim(substr(v_line, 145, 11)), '?'), 'YYYY Mon DD'), --orbit_date
						trim(substr(v_line, 157, 6)), --orbit_class
						to_number(trim(substr(v_line, 164, 11))), --orbit_period
						to_number(trim(substr(v_line, 175, 6))), --perigee
						to_number(trim(substr(v_line, 184, 7))), --apogee
						to_number(trim(substr(v_line, 193, 6))) -- inclination
					);
				end if;
			exception when others then
				raise_application_error(-20000, 'Error with this satellite line: '||v_line||chr(10)||
					sys.dbms_utility.format_error_stack||sys.dbms_utility.format_error_backtrace);
			end;

		end loop;

		--Commit and compress data.
		commit;
		execute immediate 'alter table satellite_staging move';
	end load_satellite_staging;


begin
	--TEMP
	--Takes about 2 minutes to run:
	--load_launch_staging;
	--Takes about 10 minutes to run:
	load_satellite_staging;

	null;
end;
/


--TEST
select * from satellite_staging order by line_Number;
delete from satellite_staging;
commit;



ORA-20000: Error with this satellite line: S005377 1971-063D      Apollo 15 Subsatellite                   Apollo 15 Subsatellite   NASA         1971 Jul 26 Deep Space Attac 1971 Jul 27  1971 Aug  4 EEO      -        -      x -      x -       -
ORA-01722: invalid number
ORA-06512: at line 88
ORA-06512: at line 126
ORA-06512: at line 143
;






