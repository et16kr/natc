# Admin and tool lane

Planned coverage:

1. DROP USER and DROP TABLESPACE cascade remove native metadata and storage.
2. iSQL DESC reports native global indexes without hidden-table artifacts.
3. aexport/export/import preserve native DDL and data.
4. backup and restore preserve Disk segments and rebuild Memory trees.
5. APRE atomic array insert maintains every global index.

Executable cases require isolated privileges, approved file cleanup, fixed tool
versions, and reviewed output normalization. State: `EnvironmentBlocked`.
