TestSuiteDescription  = Native Global Index (disk) - PROJ-1624 port
###############################################################################
basic/basic.ts                          # 1차 배치 - 생성 / DML / 유니크 / 기본 플랜
pdt/pdt.ts                              # 2차 배치 - PROJ-1624-QC/PDT 전량 (121)
design/design.ts                        # 3차 배치 - 공식 design/ 16 (플랜/선택도/조인/잠금)
bugs/bugs.ts                            # 4차 배치 - 공식 bugs/ 6
tool/tool.ts                            # 4차 배치 - 공식 tool/isql + tool/atomic 2
-------------------------------------------------------------------------------
