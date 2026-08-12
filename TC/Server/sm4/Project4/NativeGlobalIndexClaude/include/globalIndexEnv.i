###########################################################################
# Native Global Index - environment helpers
#
# 네이티브 글로벌 인덱스는 프로퍼티로 게이트된다.
# 이름은 MEM_GLOBAL_INDEX_ENABLE 로 확정됐다(idpDescResource.cpp).
#
# ★ 이 프로퍼티는 비영속이다. ALTER SYSTEM 으로 바꾼 값은 재기동하면
#   파일 값(기본 0)으로 돌아간다. 그래서 각 케이스가 자기 PREPARE 에서
#   켜야 하고, FINALIZE 에서 꺼서 다음 케이스에 새지 않게 해야 한다.
###########################################################################

#
# 네이티브 글로벌 인덱스 생성을 허용한다.
#
DEF ENABLE_GLOBAL_INDEX()
{
  alter system set MEM_GLOBAL_INDEX_ENABLE = 1;
}

#
# 네이티브 글로벌 인덱스 생성을 막는다(기존 동작).
# off 상태에서 메모리 파티션드 테이블의 non-partitioned index는
# 기존과 동일하게 거부되어야 한다.
#
DEF DISABLE_GLOBAL_INDEX()
{
  alter system set MEM_GLOBAL_INDEX_ENABLE = 0;
}

#
# 현재 설정 확인.
#
DEF SHOW_GLOBAL_INDEX_PROPERTY()
{
  select name, value1 from v$property where name = 'MEM_GLOBAL_INDEX_ENABLE';
}
