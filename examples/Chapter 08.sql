---------------------------------------------------------------------------
-- INSERT
---------------------------------------------------------------------------

insert all
into propellant values (-1, 'antimatter')
into propellant values (-2, 'dilithium crystals')
select * from dual;






select * from dba_tables where owner = 'SPACE';

select * from platform;

select * from propellent;

insert all
	into propellent(propellent_id, propellent_name) values (-1, 'antimatter')
	into propellent values (-2, 'dilithium crystals')
select * from dual;

rollback;

create sequence test_sequence minvalue -99999 start with -99999;

insert all
	into propellent(propellent_id, propellent_name) values (test_sequence.nextval, 'antimatter')
	into propellent values (test_sequence.nextval, 'dilithium crystals')
select * from dual;

rollback;
select * from propellent order by propellent_id;
