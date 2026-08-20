--###########################################################################
--# 크래시 후 redo 재적용 -- 커밋된 글로벌 인덱스 키가 살아남는가 (디스크).
--#
--# 출처: 없음. 새로 쓴 것이다 (커버리지 §10.2 의 첫 축).
--#
--# WHY THIS LANE, AND WHY THIS FIRST
--#   이 프로젝트는 글로벌 인덱스를 위해 redo 로그 여섯 종을 새로 만들었다:
--#     SDR_SDN_GIDX_INSERT_UNIQUE_KEY   SDR_SDN_GIDX_INSERT_DUP_KEY
--#     SDR_SDN_GIDX_DELETE_KEY_WITH_NTA SDR_SDN_GIDX_FREE_KEYS
--#     SDR_SDN_GIDX_COMPACT_INDEX_PAGE  SDR_SDN_GIDX_KEY_STAMPING
--#   그리고 언두 핸들러 셋(sdnUpdate.h). 오늘까지 그 아홉을 재는 케이스가
--#   스위트에 하나도 없었다 -- 삭제될 그물이 단언 310 으로 지고 있었다.
--#
--#   `--+SYSTEM server kill;` 은 정상 종료가 아니라 **크래시**다. 뒤이은
--#   `server start` 는 로그를 재적용해서 올라온다. 그래서 이 케이스가
--#   보는 것은 "재기동해도 되네" 가 아니라 **redo 가 인덱스를 옳게
--#   되살렸는가** 다.
--#
--#   ★ `clean` 을 쓰지 않는다. 그것은 destroydb+createdb 라 로그를 지운다 --
--#     지우면 잴 것이 없어진다. 같은 레인의 restartCatalogSurvival.sql 은
--#     반대로 `clean` 이 필요한 케이스라 서로 다른 것을 잰다.
--#
--# WHAT IT MEASURES
--#   A  커밋된 키가 크래시를 건넌다 (redo)
--#   B  트리와 힙이 재기동 뒤에도 일치한다
--#   C  파티션을 가로지르는 유일성이 재기동 뒤에도 선다
--#   D  판별자와 멤버 수가 재기동 뒤에도 그대로다 (멤버 집합 재구성)
--#
--# ★ 이 레인은 TC_GUIDE 의 Hard Stops("server restart") 밖이다. 따르는
--#   계약이 다르며, 그 사실을 여기 적는다(계획 §3.3).
--###########################################################################

--+SECTOR; PREPARATION

--+SKIP BEGIN;
DROP TABLE NGD_RDO;
--+SKIP END;

ALTER SYSTEM SET DISK_GLOBAL_INDEX_ENABLE = 1;
SELECT NAME, VALUE1 FROM V$PROPERTY WHERE NAME = 'DISK_GLOBAL_INDEX_ENABLE';

CREATE TABLE NGD_RDO ( P INTEGER, K INTEGER, V VARCHAR(16) )
PARTITION BY RANGE ( P )
(
    PARTITION P1 VALUES LESS THAN ( 10 ),
    PARTITION P2 VALUES LESS THAN ( 20 ),
    PARTITION PD VALUES DEFAULT
) TABLESPACE SYS_TBS_DISK_DATA;

CREATE UNIQUE INDEX NGD_RDO_G ON NGD_RDO ( K );

-- 전제 -- 네이티브 글로벌인가(판별자 101). 아니면 아래는 로컬을 재는 것이 된다.
SELECT COUNT(*) AS IS_NATIVE_GLOBAL
  FROM SYSTEM_.SYS_PART_INDICES_ P, SYSTEM_.SYS_INDICES_ I
 WHERE P.INDEX_ID = I.INDEX_ID
   AND P.PARTITION_TYPE = 101
   AND I.INDEX_NAME = 'NGD_RDO_G';

--+SECTOR; WORKLOAD -- redo 여섯 종을 밟는 일감

-- 유일 키 삽입 (INSERT_UNIQUE_KEY)
INSERT INTO NGD_RDO SELECT LEVEL,      100 + LEVEL, 'A' FROM DUAL CONNECT BY LEVEL <= 9;
INSERT INTO NGD_RDO SELECT LEVEL + 10, 200 + LEVEL, 'B' FROM DUAL CONNECT BY LEVEL <= 9;
INSERT INTO NGD_RDO SELECT LEVEL + 20, 300 + LEVEL, 'C' FROM DUAL CONNECT BY LEVEL <= 9;
COMMIT;

-- 키 삭제 (DELETE_KEY_WITH_NTA) + 페이지 회수(FREE_KEYS) 유도
DELETE FROM NGD_RDO WHERE K BETWEEN 105 AND 109;
COMMIT;

-- 파티션을 넘는 갱신 -- 삭제+삽입으로 갈린다
ALTER TABLE NGD_RDO ENABLE ROW MOVEMENT;
UPDATE NGD_RDO SET P = 15 WHERE K = 101;
COMMIT;

-- 크래시 직전의 상태를 전사에 남긴다. 재기동 뒤 이 값과 같아야 한다.
SELECT /*+ INDEX( NGD_RDO, NGD_RDO_G ) */ COUNT(*)          AS BEFORE_TREE     FROM NGD_RDO;
SELECT COUNT(*)                                             AS BEFORE_HEAP     FROM NGD_RDO;
SELECT /*+ INDEX( NGD_RDO, NGD_RDO_G ) */ COUNT(DISTINCT K) AS BEFORE_DISTINCT FROM NGD_RDO;
SELECT /*+ INDEX( NGD_RDO, NGD_RDO_G ) */ K, P, V FROM NGD_RDO ORDER BY K;
SELECT MEMBER_COUNT        AS BEFORE_MEMBERS FROM V$DISK_BTREE_HEADER WHERE INDEX_NAME = 'NGD_RDO_G';
SELECT ACTIVE_MEMBER_COUNT AS BEFORE_ACTIVE  FROM V$DISK_BTREE_HEADER WHERE INDEX_NAME = 'NGD_RDO_G';

--+SECTOR; CRASH -- 정상 종료가 아니라 죽인다

--+SYSTEM server kill;
--+SYSTEM server start;

-- clean 을 안 썼으므로 세션 설정만 새로 잡으면 된다(DB 는 그대로다).
SET LINESIZE 200;

--+SECTOR; A -- 커밋된 키가 redo 로 되살아났는가

SELECT /*+ INDEX( NGD_RDO, NGD_RDO_G ) */ COUNT(*)          AS AFTER_TREE     FROM NGD_RDO;
SELECT COUNT(*)                                             AS AFTER_HEAP     FROM NGD_RDO;
SELECT /*+ INDEX( NGD_RDO, NGD_RDO_G ) */ COUNT(DISTINCT K) AS AFTER_DISTINCT FROM NGD_RDO;

--+SECTOR; B -- 값까지 같은가. 순서도 파티션을 가로질러 보존되는가

SELECT /*+ INDEX( NGD_RDO, NGD_RDO_G ) */ K, P, V FROM NGD_RDO ORDER BY K;

-- 지웠던 키는 여전히 없어야 한다 (DELETE_KEY_WITH_NTA 가 redo 됐는가)
SELECT /*+ INDEX( NGD_RDO, NGD_RDO_G ) */ COUNT(*) AS DELETED_STILL_GONE
  FROM NGD_RDO WHERE K BETWEEN 105 AND 109;

-- 옮긴 행은 한 행이어야 한다
SELECT /*+ INDEX( NGD_RDO, NGD_RDO_G ) */ COUNT(*) AS MOVED_ROWS FROM NGD_RDO WHERE K = 101;
SELECT /*+ INDEX( NGD_RDO, NGD_RDO_G ) */ P, K, V  FROM NGD_RDO WHERE K = 101;

--+SECTOR; C -- 유일성이 재기동을 건넜는가

-- 다른 파티션에 같은 키 -- 트리가 하나이므로 실패해야 한다.
INSERT INTO NGD_RDO VALUES ( 25, 102, 'DUP-AFTER' );
SELECT /*+ INDEX( NGD_RDO, NGD_RDO_G ) */ COUNT(*) AS AFTER_DUP_TOTAL FROM NGD_RDO;

--+SECTOR; D -- 판별자와 멤버 집합이 재구성됐는가

SELECT COUNT(*) AS IS_NATIVE_AFTER_RESTART
  FROM SYSTEM_.SYS_PART_INDICES_ P, SYSTEM_.SYS_INDICES_ I
 WHERE P.INDEX_ID = I.INDEX_ID
   AND P.PARTITION_TYPE = 101
   AND I.INDEX_NAME = 'NGD_RDO_G';

SELECT MEMBER_COUNT        AS AFTER_MEMBERS FROM V$DISK_BTREE_HEADER WHERE INDEX_NAME = 'NGD_RDO_G';
SELECT ACTIVE_MEMBER_COUNT AS AFTER_ACTIVE  FROM V$DISK_BTREE_HEADER WHERE INDEX_NAME = 'NGD_RDO_G';
SELECT COUNT(*) AS MEMBER_ROWS FROM X$DISK_BTREE_GLOBAL_MEMBER WHERE INDEX_NAME = 'NGD_RDO_G';

--+SECTOR; E -- 재기동 뒤에도 계속 쓸 수 있는가

INSERT INTO NGD_RDO VALUES ( 5, 901, 'AFTER-RST' );
COMMIT;
SELECT /*+ INDEX( NGD_RDO, NGD_RDO_G ) */ P, K, V  FROM NGD_RDO WHERE K = 901;
SELECT /*+ INDEX( NGD_RDO, NGD_RDO_G ) */ COUNT(*) AS FINAL_TREE FROM NGD_RDO;
SELECT COUNT(*)                                    AS FINAL_HEAP FROM NGD_RDO;

--+SECTOR; FINALIZATION

DROP TABLE NGD_RDO;
