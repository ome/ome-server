alter table image_pixels rename column image_server_id to old_image_server_id;
alter table image_pixels add column image_server_id bigint;
update image_pixels set image_server_id = old_image_server_id;

update data_columns set sql_type='bigint' where
	data_columns.column_name='IMAGE_SERVER_ID' and
	data_columns.data_table_id=data_tables.data_table_id and
	data_tables.table_name='IMAGE_PIXELS';
