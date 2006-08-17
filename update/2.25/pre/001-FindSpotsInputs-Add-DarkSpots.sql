-- Datatype changes to the following ST used by FindSpots:
-- FindSpotsInputs
--	Added integer SE "DarkSpots", which if true makes FindSpots look for spots
--	darker than the background
-- ----------------------------------------------------------

-- FindSpotsInputs
--    Adding boolean SE DarkSpots in column FIND_SPOTS_INPUTS.DARK_SPOTS
alter table FIND_SPOTS_INPUTS add column DARK_SPOTS boolean;

-- Add an entry to data columns
insert into DATA_COLUMNS (COLUMN_NAME,DATA_TABLE_ID,SQL_TYPE) values
	('DARK_SPOTS',
	(select DATA_TABLE_ID from DATA_COLUMNS, SEMANTIC_ELEMENTS, SEMANTIC_TYPES
		where DATA_COLUMNS.DATA_COLUMN_ID = SEMANTIC_ELEMENTS.DATA_COLUMN_ID
		and SEMANTIC_ELEMENTS.SEMANTIC_TYPE_ID = SEMANTIC_TYPES.SEMANTIC_TYPE_ID
		and SEMANTIC_TYPES.NAME = 'FindSpotsInputs'
		and SEMANTIC_ELEMENTS.NAME='Channel'),
	'boolean');
	
-- Add an entry to Semantic Elements
insert into SEMANTIC_ELEMENTS (NAME,DATA_COLUMN_ID,SEMANTIC_TYPE_ID,DESCRIPTION) values
	('DarkSpots',
	(select DATA_COLUMNS.DATA_COLUMN_ID from DATA_COLUMNS, DATA_TABLES
		where DATA_COLUMNS.COLUMN_NAME = 'DARK_SPOTS'
		and DATA_COLUMNS.DATA_TABLE_ID = DATA_TABLES.DATA_TABLE_ID
		and DATA_TABLES.TABLE_NAME = 'FIND_SPOTS_INPUTS'),
	(select SEMANTIC_TYPE_ID from SEMANTIC_TYPES where name = 'FindSpotsInputs'),
	'False (default) sets FindSpots to look for spots lighter than the background
	(e.g. Fluorescence labeled proteins). If this parameter is set to True, spots
	are assumed to be darker than background (e.g. Nucleii in HandE stained images).');
