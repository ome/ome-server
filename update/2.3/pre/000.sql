alter table image_pixels rename column pixels_id to image_server_id;
update data_columns set column_name='IMAGE_SERVER_ID' where
	data_columns.column_name='PIXELS_ID' and
	data_columns.data_table_id=data_tables.data_table_id and
	data_tables.table_name='IMAGE_PIXELS';
update semantic_elements set name='ImageServerID' where
	semantic_elements.name='PixelsID' and
	semantic_elements.semantic_type_id=semantic_types.semantic_type_id and
	semantic_types.name='Pixels';
