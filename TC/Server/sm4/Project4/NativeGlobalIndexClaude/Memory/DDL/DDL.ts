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
replicationReject.tc                    # 복제 DDL 게이트 (단일 인스턴스)
unsupportedRtree.tc                     # 공간 글로벌 인덱스 형식 거절
-------------------------------------------------------------------------------
replacePartitionLocalColumns.tc         # atomic table/local-index column ID rollback
