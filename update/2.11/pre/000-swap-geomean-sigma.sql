update plane_statistics
	set sigma=geomean, geomean=sigma
	where plane_statistics.module_execution_id = module_executions.module_execution_id
	and module_executions.module_id = modules.module_id
	and modules.name = 'Plane statistics (image server)';
update stack_statistics
	set sigma=geomean, geomean=sigma
	where stack_statistics.module_execution_id = module_executions.module_execution_id
	and module_executions.module_id = modules.module_id
	and modules.name = 'Stack statistics (image server)';
