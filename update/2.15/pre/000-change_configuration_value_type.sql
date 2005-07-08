alter table configuration rename column value to old_value;
alter table configuration add column value text;
update configuration set value = old_value;
