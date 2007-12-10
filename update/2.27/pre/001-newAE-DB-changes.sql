ALTER TABLE analysis_chain_executions ADD COLUMN task INTEGER;
ALTER TABLE analysis_chain_executions ADD COLUMN results_reuse BOOLEAN;
UPDATE analysis_chain_executions SET results_reuse=false;

ALTER TABLE analysis_chain_executions ADD COLUMN additional_jobs BOOLEAN DEFAULT FALSE;

ALTER TABLE tasks ADD COLUMN visible BOOLEAN DEFAULT true;
ALTER TABLE tasks DROP CONSTRAINT tasks_session_id_fkey;

ALTER TABLE analysis_chain_nodes ADD COLUMN dependence CHAR(1);

-- the purpose of the analysis_workers table has changed from the old DAE
-- in the new DAE the table is *not* edited by users/scripts but by the AE
-- when workers register/unregister
DELETE FROM analysis_workers;