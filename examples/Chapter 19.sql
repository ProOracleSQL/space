---------------------------------------------------------------------------
-- MODEL
---------------------------------------------------------------------------

--Cellular automata with MODEL.
select listagg(value, '') within group (order by cell) line
from
(
	--Apply cellular automata rules with MODEL.
	select generation, cell, value from
	(
		--Empty table of data.
		select generation, cell,
			--Seed the first generation with a "#" in the center.
			case
				when generation = 0 and cell = floor(240/2) then '#'
				else ' '
			end value
		from
		(select level-1 generation from dual connect by level <= 120)
		,(select level-1 cell from dual connect by level <= 240)
	)
	model
	dimension by (generation, cell)
	measures (value)
	rules
	(
		--Comment out rules to set them to ' '.
		--Interesting patterns: 18 (00010010) 110 (01101110)
		value[generation >= 1, ANY] = case
				value[CV()-1, CV()-1] ||
				value[CV()-1, CV()  ] ||
				value[CV()-1, CV()+1]
			--when '###' then '#'
			when '## ' then '#'
			when '# #' then '#'
			--when '#  ' then '#'
			when ' ##' then '#'
			when ' # ' then '#'
			when '  #' then '#'
			--when '   ' then '#'
			else ' ' end
	)
)
group by generation
order by generation;
