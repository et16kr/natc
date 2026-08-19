TestSuiteDescription  = Native Global Index (disk) - PROJ-1624 port, batch 1 (basic)
###############################################################################
select.tc                               # SELECT / 호스트 변수 / FOR UPDATE
insert_range.tc                         # RANGE INSERT
insert_hash.tc                          # HASH INSERT
insert_list.tc                          # LIST INSERT
insert_part_range.tc                    # RANGE 파티션 지정 append INSERT
insert_part_list.tc                     # LIST 파티션 지정 append INSERT
update_range.tc                         # RANGE UPDATE (로우 이동 유/무)
update_hash.tc                          # HASH UPDATE (로우 이동 유/무)
update_list.tc                          # LIST UPDATE (로우 이동 유/무)
delete_range.tc                         # RANGE DELETE
delete_hash.tc                          # HASH DELETE
delete_list.tc                          # LIST DELETE
move_range.tc                           # RANGE -> HASH MOVE
move_hash.tc                            # HASH -> HASH MOVE
move_list.tc                            # LIST -> HASH MOVE
null_value.tc                           # NULL 키
-------------------------------------------------------------------------------
