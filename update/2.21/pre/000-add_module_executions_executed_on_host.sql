-- Add a column to reference the worker that executed this MEX
ALTER TABLE module_executions ADD COLUMN executed_by_worker INTEGER;
-- Add a reference constraint to the column.
ALTER TABLE module_executions ADD CONSTRAINT 
    "OME::ModuleExecution.executed_by_worker->OME::Analysis::Engine::Worker"
	FOREIGN KEY (executed_by_worker) REFERENCES analysis_workers (worker_id)
	DEFERRABLE INITIALLY DEFERRED;
