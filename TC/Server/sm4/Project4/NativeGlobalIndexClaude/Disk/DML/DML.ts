TestSuiteDescription  = Native Global Index (disk) - DML
###############################################################################
#
# 디스크 DML. 메모리와 갈리는 것이 여기 온다 -- row movement 의 순서
# 불변식(DELETE -> INSERT)은 메모리에서 키 삽입 미룸 때문에 **우연히**
# 통과하고 디스크에서만 ERR-11058 로 드러난다.
#
multiTableRowMovement.tc                # 멀티테이블 UPDATE 의 row movement (O-8, 신규 N8)
-------------------------------------------------------------------------------
