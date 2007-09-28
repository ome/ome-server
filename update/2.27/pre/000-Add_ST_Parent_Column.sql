-- Add a column to reference the worker that executed this MEX
ALTER TABLE semantic_types ADD COLUMN parent INTEGER;