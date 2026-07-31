DEF DESC_INDEX( @aName )
{
  desc "$GIT_@{aName}";

  NODISPLAY ON;
  drop table "$_TEMP";
  create table "$_TEMP" as select * from "$GIT_@{aName}";
  update "$_TEMP" set "$GIT_OID" = 0, "$GIT_RID" = 0;
  NODISPLAY OFF;
  select * from "$_TEMP";
  NODISPLAY ON;
  drop table "$_TEMP";
  NODISPLAY OFF;
}
