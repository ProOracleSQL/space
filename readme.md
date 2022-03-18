Pro Oracle SQL Development Source Code
======================================

See the examples directory for the source code used in Pro Oracle SQL Development (https://www.apress.com/9781484245163).

For example, to count the number of launches per category:

	select launch_category, count(*)
	from launch
	group by launch_category
	order by count(*) desc;

If you have any questions or problems please contact Jon Heller at jon@jonheller.org.


SpaceDB v2.0.4
==============

SpaceDB is a data set that contains all orbital and suborbital launches, all satellites, and related information.  It's based on data from the JSR Launch Vehicle Database, 2017 Dec 28 Edition.

SpaceDB provides a data set that is:

1. **Simple** - The data can be easily loaded into an Oracle database.  And it can be easily understood.  There are 20 tables but almost all of the tables and columns are obvious and do not require a lot of domain knowledge.
2. **Small** - The entire data set can be downloaded in a 3 megabyte zip file.  You can install this data set on almost any system without going over your disk quota.
3. **Interesting** - I assume that most people who use a database have at least some appreciation for space flight.
4. **Real** - The data is not imaginary.  If you spend time querying this data you will also learn something about the real world.

This data set was created for Pro Oracle SQL Development (https://www.apress.com/9781484245163), because I'm tired of boring `EMPLOYEE` tables.  But this data set does not depend on anything in the book, and it can be installed on any Oracle database.


How to Install
--------------

**Oracle Instructions:**

1. Download and unzip oracle_create_space.sql.zip.
2. CD into the directory with that file.
3. Set the command line to work with a UTF8 file.  In Windows this should work:

		C:\space> set NLS_LANG=American_America.UTF8

	In Unix this should work:

		export NLS_LANG=American_America.UTF8

4. Start SQL\*Plus as a user who can either create another schema or can load tables and data into their own schema.
5. If you need to create a schema to hold the data, run commands like the ones below. (You may need to change "users" to "data" or some other tablespace name, depending on your configuration.)

		SQL> create user space identified by "enterPasswordHere#1" quota unlimited on users;
		SQL> alter session set current_schema = space;

6. Run this command to install the tables and data.  It should only take a minute.

		SQL> @oracle_create_space.sql

**Postgres Instructions:**

1. Download and unzip csv_files.zip.
2. Download postgres_create_space.sql.
3. Modify postgres_create_space.sql to reference the correct directory that contains the CSV files.
4. Start psql and run this command:

		postgres=# \i postgres_create_space.sql


**Other Database (Partial) Instructions:**

1. Download and unzip csv_files.zip.
2. Load each of the 20 CSV files.


Schema Description
------------------

Below is a simple text description of the tables, roughly ordered by their importance and their relationships.  The most interesting data can be found in the `LAUNCH` and `SATELLITE` tables, which are easily joined by the column `LAUNCH_ID`.

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

	PROPELLANT

	ENGINE
		ENGINE_MANUFACTURER
		ENGINE_PROPELLANT

	LAUNCH_VEHICLE_STAGE


License
-------

The code to load the data was created by Jon Heller and is licensed under the LGPLv3.
The data itself was created by Jonathan McDowell and is licensed under the Creative Commons CC-BY.


Acknowledgements
----------------

Special thanks to the following people:

    Michael Rosenblum, the technical reviewer who helped find and fix many errors.
    Jonathan Gennick, Jill Balzano, and everyone else at Apress for helping me create this book.
    Jonathan McDowell for creating the JSR Launch Vehicle Database.
    Lisa, Elliott, and Oliver, who encouraged me and patiently waited for me to finish this project.
