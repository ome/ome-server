alter table original_files rename column file_id to old_file_id;
alter table original_files add column file_id bigint;
update original_files set file_id = old_file_id;

update data_columns set sql_type='bigint' where
	data_columns.column_name='FILE_ID' and
	data_columns.data_table_id=data_tables.data_table_id and
	data_tables.table_name='ORIGINAL_FILES';
