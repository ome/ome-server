-- Remove our records of Path & BitsPerPixel from the Pixels ST
-- postgresql v < 7.3 doesn't allow column removals from tables, so we're gonna leave the table IMAGE_PIXELS alone. 

BEGIN;
delete from data_columns where (semantic_elements.name='Path' or semantic_elements.name='BitsPerPixel') and semantic_elements.semantic_type_id=semantic_types.semantic_type_id and ( semantic_types.name='Pixels' or semantic_types.name='PixelsPlane' ) and data_columns.data_column_id=semantic_elements.data_column_id;
delete from semantic_elements where (semantic_elements.name='Path' or semantic_elements.name='BitsPerPixel') and semantic_elements.semantic_type_id=semantic_types.semantic_type_id and ( semantic_types.name='Pixels' or semantic_types.name='PixelsPlane' );
END;
