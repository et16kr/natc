TestSuiteDescription  = Native Global Index - Disk partitioned table
###############################################################################
#
# PROJ-1624 이식분이 이 트리로 재분배됐다(종전 Port1624/ 서브트리).
# 원본 경로는 각 케이스의 첫 주석과 MANIFEST 가 보존한다.
#
# ★ 프롤로그가 이 파일 맨 앞에 있다. 이식분 다수가 PDT_TBS/2/3 테이블스페이스
#   위에서 돌고, 그 전제는 **영역보다 위**에 있어야 한다 -- 영역 안에 두면
#   그 영역보다 먼저 도는 영역이 전제 없이 돌아 ERR-1102A 로 무너진다(실측).
#

Bugs/Bugs.ts                            # Bugs — 자기 전제(pdtBug 짝)를 안에 갖는다

pdtDesign_INITIALIZE.sql                # PDT_TBS / TBS2 / TBS3 생성 -- 이식분의 전제

Catalog/Catalog.ts                      # Catalog
Create/Create.ts                        # Create
DDL/DDL.ts                              # DDL
DML/DML.ts                              # DML
Query/Query.ts                          # Query
Transaction/Transaction.ts              # Transaction
Boundary/Boundary.ts                    # Boundary

pdtDesign_FINALIZE.sql                  # 전제 정리 -- PDT_TBS/2/3
-------------------------------------------------------------------------------
