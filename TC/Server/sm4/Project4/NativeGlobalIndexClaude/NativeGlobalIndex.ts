TestSuiteDescription  = Native Global Index
###############################################################################
#
# ★ Port1624 서브트리는 없어졌다 -- 203 실행 단위가 매체·영역으로
#   재분배됐다(Disk/ 아래 여덟 영역 + Tool/). 원본 경로는 MANIFEST 가
#   보존한다.
#
#   ★ 재분배가 옛 순서 제약을 없애지는 못한다. 이식분 넷이 절대 카탈로그
#     id 를 기대값에 담고 있고(__SYS_PART_IDX_ID_<n> · TABLE_ID · 파티션
#     서수), 그 값은 "인스턴스가 지금까지 만든 객체 수" 의 함수다. 그래서
#     이식분이 많은 Disk/ 를 Memory/ 보다 **먼저** 둔다 -- 종전 Port1624 가
#     첫째였던 것과 같은 이유다.
#
#     항구적 수리는 그 넷이 절대 id 대신 자기 객체로 범위를 좁힌 값을
#     찍게 다시 쓰는 것이다(BUG-35460 이 그렇게 고쳐졌다). 그때 이 순서
#     제약이 풀린다.
#
Disk/Disk.ts                            # 디스크 — 로깅 있음, 로그로 복구 (이식분 다수)
Memory/Memory.ts                        # 메모리 — 로깅 없음, 재기동 시 리빌드
Tool/Tool.ts                            # 유틸리티 접점 (제안 — §계획 3.1 의 Tool 결정 대기)
#
# ★ Replication/Replication.ts 는 여기 없다 -- **의도다** (2026-08-21 결정).
#   그 레인은 db1/db2 두 인스턴스를 짓고 띄우고 내리므로, 기본 실행에
#   넣으면 매 실행마다 그 비용과 실패 가능성을 진다. 그래서 빼 두고,
#   대신 그 사실과 실행 방법을 여기 적는다 -- 그러지 않으면 케이스들이
#   전체 실행에서 조용히 빠진다 (§계획 9.4 결함 ①).
#
#   이 레인은 따로 돌린다:
#
#       cd $ATC_HOME/TC/Server/sm4/Project4/NativeGlobalIndexClaude
#       atsclnt Replication/Replication.ts
#
#   지금 5 케이스다 -- initialize / globalPkRowMovement /
#   ddlSyncPropertyMismatch / replicationReject / finalize. 넷째는
#   2026-08-21 에 Memory/DDL 에서 이관했다: 복제 매니저가 살아 있는
#   인스턴스를 요구하는데 [DEFAULT] 블록에는 복제 포트가 없고, 그것은
#   [NGI_SERVER1] 처럼 복제 전용 서버 블록에만 있기 때문이다. 근거는
#   그 파일 머리에 있다.
-------------------------------------------------------------------------------
