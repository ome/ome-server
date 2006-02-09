-- Rename timing columns based on what has historically been written to them.
-- These changes coincide with updates to the code that writes to these columns.
ALTER TABLE module_executions RENAME COLUMN total_time TO x_time;
ALTER TABLE module_executions RENAME COLUMN attribute_db_time TO r_time;
ALTER TABLE module_executions RENAME COLUMN attribute_create_time TO w_time;
ALTER TABLE module_executions RENAME COLUMN attribute_sort_time TO t_time;
