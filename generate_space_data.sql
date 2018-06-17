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
	insert into space_files values(v_url, sysdate, get_clob_from_url(v_url));
	commit;
end;
/



--------------------------------------------------------------------------------
--#5: Transform files.
--------------------------------------------------------------------------------


