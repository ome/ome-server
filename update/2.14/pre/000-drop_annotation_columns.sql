-- These columns are not needed. Module execution timestamps and experimenter
-- references should be used instead.

-- image_annotations
ALTER TABLE image_annotations DROP timestamp CASCADE;
ALTER TABLE image_annotations DROP experimenter CASCADE;

-- dataset_annotations
ALTER TABLE dataset_annotations DROP timestamp CASCADE;
ALTER TABLE dataset_annotations DROP experimenter CASCADE;
