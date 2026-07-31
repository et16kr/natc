DEF SELECT_META()
{
select u.user_name, t.table_name, t.table_type, t.hidden, b.name tbs_name 
from system_.sys_tables_ t, system_.sys_users_ u, v$tablespaces b
where t.table_name like '$%' and t.user_id = u.user_id and t.tbs_id = b.id
order by t.table_id;

select t.table_name, c.column_order, c.column_name, d.type_name, c.is_nullable
from system_.sys_tables_ t, system_.sys_columns_ c, v$datatype d
where t.table_name like '$%' and t.table_id = c.table_id and c.data_type = d.data_type
order by t.table_id, c.column_order;

select u.user_name, i.index_name, i.index_type, i.is_unique, b.name tbs_name, i.is_partitioned
from system_.sys_indices_ i, system_.sys_users_ u, v$tablespaces b
where i.index_name like '$%' and i.user_id = u.user_id and i.tbs_id = b.id
order by i.index_id;

select i.index_name, j.index_col_order, c.column_name, j.sort_order
from system_.sys_indices_ i, system_.sys_index_columns_ j, system_.sys_columns_ c
where i.index_name like '$%' and i.index_id = j.index_id and j.column_id = c.column_id
order by i.index_id, j.index_col_order;
}

DEF DROP_BACKUP_META()
{
NODISPLAY ON;
SKIP BEGIN;
for $sBackup in
    "sys_tables_"
    "sys_columns_"
    "sys_indices_"
    "sys_index_columns_"
    "sys_constraints_"
    "sys_constraint_columns_"
{
    drop table ${sBackup}backup;
}
SKIP END;
NODISPLAY OFF;
}

DEF CREATE_BACKUP_META()
{
CALL DROP_BACKUP_META();    

NODISPLAY ON;
for $sBackup in
    "sys_tables_"
    "sys_columns_"
    "sys_indices_"
    "sys_index_columns_"
    "sys_constraints_"
    "sys_constraint_columns_"
{
    create table ${sBackup}backup as select * from system_.${sBackup} limit 1;
    delete from ${sBackup}backup;
}

for $sBackup in
    "sys_tables_"
    "sys_columns_"
    "sys_indices_"
    "sys_index_columns_"
    "sys_constraints_"
    "sys_constraint_columns_"
{
    insert into ${sBackup}backup select * from system_.${sBackup};
}
NODISPLAY OFF;

}

DEF COMPARE_META()
{
select table_name from (
    select * from system_.sys_tables_ minus select * from sys_tables_backup
)
order by table_name;
select table_name from (
    select * from sys_tables_backup minus select * from system_.sys_tables_
)
order by table_name;
    
select column_name from (
    select * from system_.sys_columns_ minus select * from sys_columns_backup
)
order by column_name;
select column_name from (
    select * from sys_columns_backup minus select * from system_.sys_columns_
)
order by column_name;

select index_name from (
    select * from system_.sys_indices_ minus select * from sys_indices_backup
)
order by index_name;
select index_name from (
    select * from sys_indices_backup minus select * from system_.sys_indices_
)
order by index_name;

select c.column_name index_column_name from (
    select * from system_.sys_index_columns_ minus select * from sys_index_columns_backup
) v1, system_.sys_columns_ c
where v1.column_id = c.column_id
order by c.column_id;
select c.column_name index_column_name from (
    select * from sys_index_columns_backup minus select * from system_.sys_index_columns_
) v1, system_.sys_columns_ c
where v1.column_id = c.column_id
order by c.column_id;

select constraint_name from (
    select * from system_.sys_constraints_ minus select * from sys_constraints_backup
)
order by constraint_name;
select constraint_name from (
    select * from sys_constraints_backup minus select * from system_.sys_constraints_
)
order by constraint_name;

select c.column_name constraint_column_name from (
    select * from system_.sys_constraint_columns_ minus select * from sys_constraint_columns_backup
) v1, system_.sys_columns_ c
where v1.column_id = c.column_id
order by c.column_id;
select c.column_name constraint_column_name from (
    select * from sys_constraint_columns_backup minus select * from system_.sys_constraint_columns_
) v1, system_.sys_columns_ c
where v1.column_id = c.column_id
order by c.column_id;

CALL DROP_BACKUP_META();
}
