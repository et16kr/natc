TestSuiteDescription  = Native Global Index (memory) - DDL
###############################################################################
createIndex.tc                          # 글로벌 인덱스 생성
createIndexError.tc                     # 거부되어야 하는 조합
createTableFromSchema.tc                # FROM TABLE SCHEMA 로 인덱스 복제 (J05)
indexBudget.tc                          # 인덱스 비트 예산 경계 (ERR-314AC)
dropIndex.tc                            # 삭제와 재생성
alterIndex.tc                           # RENAME / AGING / 이름 / 옵션
alterIndexRebuild.tc                    # REBUILD
alterTableColumn.tc                     # 컬럼 추가·삭제·변경과 키 배치
constraint.tc                           # PK / UK / FK
dropCascade.tc                          # DROP USER / DROP TABLESPACE
allIndexAndTablespace.tc                # ALL INDEX / TBS OFFLINE-ONLINE
diskPartitionedTable.tc                 # 디스크 파티션드는 종전 그대로
-------------------------------------------------------------------------------
