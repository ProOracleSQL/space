---------------------------------------------------------------------------
-- 
---------------------------------------------------------------------------


/*
 *  _______        _       +------------------+
 * |__   __|      | |      |doesn't have to be+-------+ 
 *    | | _____  _| |_     +------------------+       |
 *    | |/ _ \ \/ / __|                               |
 *    | |  __/>  <| |_     +------+                   |
 *    |_|\___/_/\_\\__|    |boring+<------------------+
 *                         +------+
*/






SQL> select 1 from dual;

         1
----------
         1

SQL> /*a*/

         1
----------
         1


;

select * from dual;

/* Text
	select * from dual;
	/
	/
*/


declare
	v_test varchar2(100) := '
	/
	';
begin
	null;
end;
/



SQL> declare
  2     v_test varchar2(100) := '
  3     /
ERROR:
ORA-01756: quoted string not properly terminated


SQL>    ';
SP2-0042: unknown command "'" - rest of line ignored.
SQL> begin
  2     null;
  3  end;
  4  /

PL/SQL procedure successfully completed.

SQL>

