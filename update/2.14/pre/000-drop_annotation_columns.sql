-- These columns are not needed. Module execution timestamps and experimenter
-- references should be used instead.

-- remove columns from image_annotations
ALTER TABLE image_annotations DROP timestamp CASCADE;
ALTER TABLE image_annotations DROP experimenter CASCADE;
DELETE FROM semantic_elements WHERE semantic_type_id = (SELECT semantic_type_id FROM semantic_types WHERE name = 'ImageAnnotation') AND name IN ('Timestamp', 'Experimenter');

-- remove columns from dataset_annotations
ALTER TABLE dataset_annotations DROP timestamp CASCADE;
ALTER TABLE dataset_annotations DROP experimenter CASCADE;
DELETE FROM semantic_elements WHERE semantic_type_id = (SELECT semantic_type_id FROM semantic_types WHERE name = 'DatasetAnnotation') AND name IN ('Timestamp', 'Experimenter');

-- cleanup now orphaned data columns
DELETE FROM data_columns WHERE data_column_id NOT IN (SELECT data_column_id FROM semantic_elements);
