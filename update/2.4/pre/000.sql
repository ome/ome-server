--   This table was originally misdefined with a typo. semantic_type_id was 
-- referencing module_execution. No code ever used this table. Since it's empty, 
-- the easiest way to fix it is drop and create.

DROP TABLE semantic_type_outputs;
CREATE SEQUENCE semantic_type_output_seq;
CREATE TABLE semantic_type_outputs (
       semantic_type_output_id  INTEGER DEFAULT NEXTVAL('semantic_type_output_seq')
                                PRIMARY KEY NOT NULL,
       module_execution_id      INTEGER REFERENCES module_executions
                                DEFERRABLE INITIALLY DEFERRED NOT NULL,
       semantic_type_id         INTEGER REFERENCES semantic_types
                                DEFERRABLE INITIALLY DEFERRED NOT NULL
);
