-- Add a column to reference the worker that executed this MEX
ALTER TABLE analysis_workers ADD COLUMN executing_mex INTEGER;
ALTER TABLE analysis_workers ADD COLUMN scheduling_token VARCHAR(64);
ALTER TABLE analysis_chain_executions ADD COLUMN status VARCHAR(16);