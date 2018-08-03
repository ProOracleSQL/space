---------------------------------------------------------------------------
-- 4.1.3
---------------------------------------------------------------------------

--This is unusual, but valid syntax:
select
	-.5,
	1.0e+10,
	5e-2,
	2f,
	3.5D
from dual;


--This syntax is valid, but is ambiguous according to the syntax diagrams in the manual.
--Is the first value "1" "-" "1", or is it scientific notation without the optional "E"?
select
	1-1,
	1e-1
from dual;
