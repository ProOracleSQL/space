---------------------------------------------------------------------------
-- Create a PL/SQL Playground
---------------------------------------------------------------------------

--PL/SQL block with nested procedure and functions.
declare
	v_declare_variables_first number;

	function some_function return number is
		procedure some_procedure is
		begin
			null;
		end some_procedure;
	begin
		some_procedure;
		return 1;
	end some_function;
begin
	v_declare_variables_first := some_function;
	dbms_output.put_line('Output: '||v_declare_variables_first);
end;
/

Output: 1
