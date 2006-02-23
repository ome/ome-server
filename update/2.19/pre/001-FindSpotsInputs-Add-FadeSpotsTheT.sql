-- Datatype changes to the following ST used by FindSpots:
-- FindSpotsInputs
--	Added integer SE "FadeSpotsTheT", which if not null specifies a timepoint
--	to use to define spots.  All other timepoints will then use this mask to define
--	their spots.
-- ----------------------------------------------------------

-- FindSpotsInputs
--    Adding integer SE FadeSpotsTheT in column FIND_SPOTS_INPUTS.FADE_SPOTS_THE_T
alter table FIND_SPOTS_INPUTS add column FADE_SPOTS_THE_T integer;

-- Add an entry to data columns
insert into DATA_COLUMNS (COLUMN_NAME,DATA_TABLE_ID,SQL_TYPE) values
	('FADE_SPOTS_THE_T',
	(select DATA_TABLE_ID from DATA_COLUMNS, SEMANTIC_ELEMENTS, SEMANTIC_TYPES
		where DATA_COLUMNS.DATA_COLUMN_ID = SEMANTIC_ELEMENTS.DATA_COLUMN_ID
		and SEMANTIC_ELEMENTS.SEMANTIC_TYPE_ID = SEMANTIC_TYPES.SEMANTIC_TYPE_ID
		and SEMANTIC_TYPES.NAME = 'FindSpotsInputs'
		and SEMANTIC_ELEMENTS.NAME='Channel'),
	'integer');
	
-- Add an entry to Semantic Elements
insert into SEMANTIC_ELEMENTS (NAME,DATA_COLUMN_ID,SEMANTIC_TYPE_ID,DESCRIPTION) values
	('FadeSpotsTheT',
	(select DATA_COLUMNS.DATA_COLUMN_ID from DATA_COLUMNS, DATA_TABLES
		where DATA_COLUMNS.COLUMN_NAME = 'FADE_SPOTS_THE_T'
		and DATA_COLUMNS.DATA_TABLE_ID = DATA_TABLES.DATA_TABLE_ID
		and DATA_TABLES.TABLE_NAME = 'FIND_SPOTS_INPUTS'),
	(select SEMANTIC_TYPE_ID from SEMANTIC_TYPES where name = 'FindSpotsInputs'),
	'If this is not NULL, it specifies the timepoint to use when generating a mask for finding spots.
All other timepoints will then use this mask for finding spots.  This allows looking at bleaching or
signal recovery (i.e. FRAP) in regions defined at the specified timepoint.');
