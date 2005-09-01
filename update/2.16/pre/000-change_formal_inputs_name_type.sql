ALTER TABLE formal_inputs RENAME COLUMN name TO old_name;
ALTER TABLE formal_inputs ADD COLUMN name text;
UPDATE formal_inputs SET name = old_name;

ALTER TABLE formal_outputs RENAME COLUMN name TO old_name;
ALTER TABLE formal_outputs ADD COLUMN name text;
UPDATE formal_outputs SET name = old_name;