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
triggerRowMovement.tc                   # 트리거 × row movement · 분화 레이아웃 (리뷰 §2, 신규 N12)
-------------------------------------------------------------------------------
