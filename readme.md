Space v0.0.1
============

This reopsitory contains the schema used in the book Pro Oracle SQL Development.

THIS IS STILL EXPERIMENTAL!  This probably won't be usable until sometime in July 2018.


Examples
--------

Count the number of launches per category:

	select launch_category, count(*)
	from launch
	group by launch_category
	order by count(*) desc;


How to Install
--------------

If you cannot use an existing schema, create a separate schema to contain the database.

For example:

	create user space identified by "enterAPasswordHere" quota unlimited on users;

Download the file oracle_create_space.sql, CD to the directory with that file, start SQL*Plus, and run these commands:

	> alter session set current_schema = <whichever schema you want>;
	> @oracle_create_space.sql


Schema Diagram
--------------

TODO.

For now, here's a simple text description of the tables, roughly ordered by their importance and their relationships.

	LAUNCH
		LAUNCH_PAYLOAD_ORG
		LAUNCH_AGENCY

	SATELLITE
		SATELLITE_ORG

	ORGANIZATION
		ORGANIZATION_ORG_TYPE

	PLATFORM

	SITE
		SITE_ORG

	LAUNCH_VEHICLE
		LAUNCH_VEHICLE_MANUFACTURER
		LAUNCH_VEHICLE_FAMILY

	STAGE
		STAGE_MANUFACTURER

	PROPELLENT

	ENGINE
		ENGINE_MANUFACTURER
		ENGINE_PROPELLENT

	LAUNCH_VEHICLE_STAGE


License
-------

This sample database is licensed under the LGPLv3.
