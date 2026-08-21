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

#
# ★ 새로 쓴 케이스가 절대 카탈로그 id 를 밀 수 있다 -- **영역 안의 맨 뒤로는
#   부족하다.** Catalog/ 는 Create/ 보다 먼저 돌고, Create/ 의 이식분 넷이
#   `__SYS_PART_IDX_ID_<n>` 을 기대값에 담고 있다. 실측: Catalog.ts 끝에
#   케이스 하나를 붙였더니 그 넷이 +2 만큼 밀려 붉어졌다(2026-08-21).
#   객체를 만드는 새 케이스는 **여기**, 모든 영역 뒤에 붙인다.
#
Catalog/memberDirectory.tc              # memberNo 디렉터리 — 발급 · DROPPED · 수동 회수 (신규)

pdtDesign_FINALIZE.sql                  # 전제 정리 -- PDT_TBS/2/3

Recovery/Recovery.ts                    # 재기동·복구 — clean 이 DB 를 지우므로 **맨 뒤**
-------------------------------------------------------------------------------
