TestSuiteDescription  = Native Global Index (disk) - DDL
###############################################################################
diskPartitionedTable.tc                 # 디스크 파티션드는 종전 그대로 (섹터마다 프로퍼티 못박음)
replacePartitionRemap.tc                # REPLACE PARTITION 리매핑 == 리빌드 (GR-10/J14, 신규 N1)
# ★ convertFromLegacy.tc 는 아직 걸지 않는다 (보류)
#   전환 뒤 판별자는 네이티브인데 SYS_INDICES_.INDEX_TABLE_ID 가 0 이 아니다.
#   기대값으로 굳히면 의심되는 카탈로그 불일치를 동결한다 -- 제품 판정 뒤에 연다.
-------------------------------------------------------------------------------
