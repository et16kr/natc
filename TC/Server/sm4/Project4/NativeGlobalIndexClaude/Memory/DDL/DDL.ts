TestSuiteDescription  = Native Global Index (memory) - DDL
###############################################################################
dropIndex.tc                            # 삭제와 재생성
alterIndex.tc                           # RENAME / AGING / 이름 / 옵션
alterIndexRebuild.tc                    # REBUILD
alterTableColumn.tc                     # 컬럼 추가·삭제·변경과 키 배치
constraint.tc                           # PK / UK / FK
dropCascade.tc                          # DROP USER / DROP TABLESPACE
addTruncatePartition.tc                 # ADD / TRUNCATE PARTITION
dropPartition.tc                        # DROP PARTITION
splitMergeReplace.tc                    # SPLIT / MERGE / REPLACE PARTITION
coalesceAndBoundary.tc                  # COALESCE 와 파티션 경계값
-------------------------------------------------------------------------------
