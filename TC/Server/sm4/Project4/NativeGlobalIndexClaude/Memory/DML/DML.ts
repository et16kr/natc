TestSuiteDescription  = Native Global Index (memory) - DML
###############################################################################
insert.tc                               # INSERT
updateDelete.tc                         # UPDATE / DELETE
updateInPlace.tc                        # 제자리 갱신
rowMovement.tc                          # row movement
dpathInsert.tc                          # direct-path(append) 삽입
nullValue.tc                            # 키 컬럼의 NULL
variableColumn.tc                       # variable 길이 키 컬럼
manyGlobalIndexes.tc                     # 인덱스 8 개를 한 DML 로 (Codex 흡수)
nvarcharKey.tc                          # NVARCHAR 키와 얇은 키 타입들 (신규 N3)
mergeInto.tc                            # MERGE INTO — 갱신·삽입·row movement (신규)
# ★ triggerRowMovement.tc 는 아직 걸지 않는다 (보류)
#   D 절이 그린인데 겨눈 분화 조건에 닿았는지 확인되지 않았다.
#   닿지 않았다면 그 그린은 아무것도 뜻하지 않는다 -- 조건 확인 뒤에 연다.
-------------------------------------------------------------------------------
