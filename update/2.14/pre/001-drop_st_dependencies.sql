-- remove semantic type references to legacy columns from image_annotations
DELETE FROM semantic_elements WHERE semantic_type_id = (SELECT semantic_type_id FROM semantic_types WHERE name = 'ImageAnnotation') AND name IN ('Timestamp', 'Experimenter');

-- remove semantic type references to legacy columns from dataset_annotations
DELETE FROM semantic_elements WHERE semantic_type_id = (SELECT semantic_type_id FROM semantic_types WHERE name = 'DatasetAnnotation') AND name IN ('Timestamp', 'Experimenter');

-- cleanup now orphaned data columns
DELETE FROM data_columns WHERE data_column_id NOT IN (SELECT data_column_id FROM semantic_elements);
