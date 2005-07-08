BEGIN;
ALTER TABLE module_executions ADD COLUMN group_id integer
REFERENCES groups DEFERRABLE INITIALLY DEFERRED;
COMMIT;
BEGIN;
UPDATE module_executions SET group_id = experimenters.group_id
WHERE experimenters.attribute_id = module_executions.experimenter_id;
COMMIT;
