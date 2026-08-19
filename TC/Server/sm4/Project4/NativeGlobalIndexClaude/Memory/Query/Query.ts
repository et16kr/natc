TestSuiteDescription  = Native Global Index (memory) - Query
###############################################################################
scanAndLock.tc                          # 스캔 결과 정합 · 파티션 지정 · 잠금
preservedOrder.tc                       # 정렬 순서 보존
joinAndFilter.tc                        # 조인 · 서브쿼리 · 상수 필터
hostVariable.tc                         # 호스트 변수와 prepare/execute
tableLock.tc                            # 테이블 잠금
optimizerSelection.tc                    # 무힌트·로컬·네이티브·풀 비교 (Codex 흡수)
pruningCardinality.tc                    # 프루닝 기수 0/1/다수/전체 (Codex 흡수, J19b 축)
statisticsContinuity.tc                  # 통계 수집 전후 (Codex 흡수)
joinSubqueryView.tc                      # 조인·서브쿼리·뷰 (Codex 흡수)
-------------------------------------------------------------------------------
