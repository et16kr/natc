TestSuiteDescription  = Native Global Index (memory) - DML
###############################################################################
insert.tc                               # 삽입
updateInPlace.tc                        # 제자리 갱신과 유령 키 (P0-1)
updateDelete.tc                         # 갱신과 삭제
isolation.tc                            # 격리 수준별 스캔·DML (P0-5)
rowMovement.tc                          # 파티션 간 로우 이동
dpathInsert.tc                          # direct-path(append) 적재
nullValue.tc                            # NULL 키
-------------------------------------------------------------------------------
