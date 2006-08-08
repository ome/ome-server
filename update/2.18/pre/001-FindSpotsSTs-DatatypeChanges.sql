-- Changing DataType of the following STs used by FindSpots:
-- FindSpotsInputs
--    Channel:  integer -> string
-- Extent
--    SigmaX, SigmaY, SigmaZ: integer -> float
-- Threshold
--    Threshold: integer -> float
-- The following table.columns will need to be dropped
-- in a DB-compatible way using the delegate:
-- FIND_SPOTS_INPUTS.OLD_CHANNEL
-- EXTENT.OLD_SIGMA_X
-- EXTENT.OLD_SIGMA_Y
-- EXTENT.OLD_SIGMA_Z
-- THRESHOLD.OLD_THRESHOLD
-- This is done by 009-drop_old_columns.eval
-- ----------------------------------------------------------

-- FindSpotsInputs
--    Channel:  integer -> string
alter table FIND_SPOTS_INPUTS rename column CHANNEL to OLD_CHANNEL;
alter table FIND_SPOTS_INPUTS add column CHANNEL text;
update FIND_SPOTS_INPUTS set CHANNEL = OLD_CHANNEL;

update DATA_COLUMNS set SQL_TYPE = 'string'
	from SEMANTIC_ELEMENTS, SEMANTIC_TYPES
	where DATA_COLUMNS.DATA_COLUMN_ID = SEMANTIC_ELEMENTS.DATA_COLUMN_ID
		and SEMANTIC_ELEMENTS.SEMANTIC_TYPE_ID = SEMANTIC_TYPES.SEMANTIC_TYPE_ID
		and SEMANTIC_TYPES.NAME = 'FindSpotsInputs'
		and SEMANTIC_ELEMENTS.NAME='Channel';


-- Extent
--    SigmaX, SigmaY, SigmaZ: integer -> float
alter table EXTENT rename column SIGMA_X to OLD_SIGMA_X;
alter table EXTENT add column SIGMA_X float;
update EXTENT set SIGMA_X = OLD_SIGMA_X;

update DATA_COLUMNS set SQL_TYPE = 'float'
	from SEMANTIC_ELEMENTS, SEMANTIC_TYPES
	where DATA_COLUMNS.DATA_COLUMN_ID = SEMANTIC_ELEMENTS.DATA_COLUMN_ID
		and SEMANTIC_ELEMENTS.SEMANTIC_TYPE_ID = SEMANTIC_TYPES.SEMANTIC_TYPE_ID
		and SEMANTIC_TYPES.NAME = 'Extent'
		and SEMANTIC_ELEMENTS.NAME='SigmaX';


alter table EXTENT rename column SIGMA_Y to OLD_SIGMA_Y;
alter table EXTENT add column SIGMA_Y float;
update EXTENT set SIGMA_Y = OLD_SIGMA_Y;

update DATA_COLUMNS set SQL_TYPE = 'float'
	from SEMANTIC_ELEMENTS, SEMANTIC_TYPES
	where DATA_COLUMNS.DATA_COLUMN_ID = SEMANTIC_ELEMENTS.DATA_COLUMN_ID
		and SEMANTIC_ELEMENTS.SEMANTIC_TYPE_ID = SEMANTIC_TYPES.SEMANTIC_TYPE_ID
		and SEMANTIC_TYPES.NAME = 'Extent'
		and SEMANTIC_ELEMENTS.NAME='SigmaY';


alter table EXTENT rename column SIGMA_Z to OLD_SIGMA_Z;
alter table EXTENT add column SIGMA_Z float;
update EXTENT set SIGMA_Z = OLD_SIGMA_Z;

update DATA_COLUMNS set SQL_TYPE = 'float'
	from SEMANTIC_ELEMENTS, SEMANTIC_TYPES
	where DATA_COLUMNS.DATA_COLUMN_ID = SEMANTIC_ELEMENTS.DATA_COLUMN_ID
		and SEMANTIC_ELEMENTS.SEMANTIC_TYPE_ID = SEMANTIC_TYPES.SEMANTIC_TYPE_ID
		and SEMANTIC_TYPES.NAME = 'Extent'
		and SEMANTIC_ELEMENTS.NAME='SigmaZ';


-- Threshold
--    Threshold: integer -> float
alter table THRESHOLD rename column THRESHOLD to OLD_THRESHOLD;
alter table THRESHOLD add column THRESHOLD float;
update THRESHOLD set THRESHOLD = OLD_THRESHOLD;

update DATA_COLUMNS set SQL_TYPE = 'float'
	from SEMANTIC_ELEMENTS, SEMANTIC_TYPES
	where DATA_COLUMNS.DATA_COLUMN_ID = SEMANTIC_ELEMENTS.DATA_COLUMN_ID
		and SEMANTIC_ELEMENTS.SEMANTIC_TYPE_ID = SEMANTIC_TYPES.SEMANTIC_TYPE_ID
		and SEMANTIC_TYPES.NAME = 'Threshold'
		and SEMANTIC_ELEMENTS.NAME='Threshold';
