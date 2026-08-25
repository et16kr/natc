--###########################################################################
--# TestCase Description = 크래시 뒤 재기동이 멤버 집합을 스스로 되맞추는가
--#                        (디스크). V5 A-3 이 crash matrix 의 성공 기준을
--#                        "수동 복구"에서 "자동 수렴"으로 뒤집은 그 계약.
--# Project ID           = Native Global Index
--#
--# 출처                 = 없음. **새로 쓴 것**이다. 오늘 이 계약을 재는 것은
--#                        삭제될 하네스(`disk-crash-check.sh` RC 절)뿐이었다.
--#
--# ★★ 무엇을 주장하는가
--#
--#   글로벌 인덱스의 트리는 하나인데 로우는 파티션마다 흩어져 있다. 그래서
--#   어느 키가 어느 파티션의 것인지를 **멤버 디렉터리**가 들고, 재기동은
--#   파티션 헤더의 역링크로 그것을 다시 모은다. 파티션 DDL 이 커밋된 직후에
--#   죽으면 카탈로그와 디렉터리가 한순간 어긋날 수 있고, **재기동이 그것을
--#   스스로 되맞춰야 한다.**
--#
--#   V5 이전의 성공 기준은 "수동 복구(DROP/CREATE INDEX 또는 ALTER INDEX
--#   REBUILD)로 되살아난다" 였다. V5 A-3 이 그것을 **"아무도 손대지 않아도
--#   재기동 하나로 산다"** 로 뒤집었다. 이 케이스가 재는 것이 그 뒤집힌
--#   기준이다 -- **어디에서도 REBUILD 를 부르지 않는다.**
--#
--# ★★ 무엇을 재지 못하는가 -- 정직하게
--#
--#   `--+SYSTEM server kill` 은 **진짜 크래시**지만 **지점을 고를 수 없다.**
--#   V5 의 crash matrix 는 FIT point 별로 갈래를 갈랐다(DDL 커밋 직후 ·
--#   purge 도중 · pending apply 도중). 그 갈래별 주장은 FIT 없이 설 수
--#   없고, 재구현에서 FIT 을 다시 만들 때 함께 세워야 한다.
--#
--#   이 케이스가 서는 자리는 그 아래층이다 -- **일감이 실린 상태에서 죽여도
--#   재기동 하나로 답과 유일성과 멤버 집합이 돌아온다.** 그것이 무너지면
--#   위층의 갈래별 주장은 잴 필요도 없다.
--#
--# ★ 판정으로 찍는다. 원시 값이 아니라 `OK`/`NG` 다 -- 이 `.lst` 는 언젠가
--#   다시 녹화되고, 원시 값만 찍으면 재녹화가 잘못된 구현의 값을 그대로
--#   축복한다.
--#
--# ★ 이 레인은 TC_GUIDE 의 Hard Stops("server restart") 밖이다. 따르는
--#   계약이 다르며, 그 사실을 여기 적는다.
--#
--# ★ `clean` 을 쓰지 않는다. 크래시 전 로그가 남아 있어야 재기동이 잴
--#   것을 갖는다.
--###########################################################################

--+SECTOR; PREPARATION

--+SKIP BEGIN;
DROP TABLE NGD_CVG;
--+SKIP END;

ALTER SYSTEM SET DISK_GLOBAL_INDEX_ENABLE = 1;
SELECT NAME, VALUE1 FROM V$PROPERTY WHERE NAME = 'DISK_GLOBAL_INDEX_ENABLE';

CREATE TABLE NGD_CVG ( P INTEGER, K INTEGER, V VARCHAR(16) )
PARTITION BY RANGE ( P )
(
    PARTITION P1 VALUES LESS THAN ( 100 ),
    PARTITION P2 VALUES LESS THAN ( 200 ),
    PARTITION P3 VALUES LESS THAN ( 300 ),
    PARTITION PD VALUES DEFAULT
) TABLESPACE SYS_TBS_DISK_DATA;

-- 파티션 키(P)를 담지 않은 유일 키 -> 글로벌이어야만 설 수 있다
CREATE UNIQUE INDEX NGD_CVG_G ON NGD_CVG ( K );

-- 전제 -- 네이티브 글로벌인가(판별자 101). 아니면 아래는 로컬을 재는 것이 된다.
SELECT CASE WHEN COUNT(*) = 1 THEN 'OK' ELSE 'NG' END AS IS_NATIVE_GLOBAL
  FROM SYSTEM_.SYS_PART_INDICES_ P, SYSTEM_.SYS_INDICES_ I
 WHERE P.INDEX_ID = I.INDEX_ID
   AND P.PARTITION_TYPE = 101
   AND I.INDEX_NAME = 'NGD_CVG_G';

--+SECTOR; WORKLOAD -- 파티션 DDL 을 실은 채로 죽는다

INSERT INTO NGD_CVG SELECT LEVEL,       1000 + LEVEL, 'A' FROM DUAL CONNECT BY LEVEL <= 50;
INSERT INTO NGD_CVG SELECT LEVEL + 100, 2000 + LEVEL, 'B' FROM DUAL CONNECT BY LEVEL <= 50;
INSERT INTO NGD_CVG SELECT LEVEL + 200, 3000 + LEVEL, 'C' FROM DUAL CONNECT BY LEVEL <= 50;
COMMIT;

-- 멤버 집합을 움직이는 DDL 셋. 각각 디렉터리를 다시 쓰게 한다.
ALTER TABLE NGD_CVG DROP PARTITION P2;
ALTER TABLE NGD_CVG SPLIT PARTITION PD AT ( 400 ) INTO ( PARTITION P4, PARTITION PD );
INSERT INTO NGD_CVG SELECT LEVEL + 300, 4000 + LEVEL, 'D' FROM DUAL CONNECT BY LEVEL <= 50;
COMMIT;

-- 크래시 직전의 진실을 못박는다. 재기동 뒤 이 값들과 같아야 한다.
SELECT COUNT(*) AS BEFORE_HEAP FROM NGD_CVG;
SELECT COUNT(DISTINCT P) AS BEFORE_LIVE_PARTS_WITH_ROWS FROM NGD_CVG;
SELECT CASE
         WHEN ( SELECT COUNT(*) FROM NGD_CVG )
            = ( SELECT /*+ INDEX( NGD_CVG, NGD_CVG_G ) */ COUNT(K)
                  FROM NGD_CVG WHERE K IS NOT NULL )
         THEN 'OK' ELSE 'NG'
       END AS BEFORE_TREE_EQUALS_HEAP
  FROM DUAL;

--+SECTOR; CRASH -- 정상 종료가 아니라 죽인다. 이 뒤로 REBUILD 는 부르지 않는다.

--+SYSTEM server kill;
--+SYSTEM server start;

SET LINESIZE 200;

--+SECTOR; A -- 답이 돌아왔는가 (트리로 센 값 == 힙으로 센 값)

SELECT CASE
         WHEN ( SELECT /*+ FULL SCAN( NGD_CVG ) */ COUNT(*) FROM NGD_CVG )
            = ( SELECT /*+ INDEX( NGD_CVG, NGD_CVG_G ) */ COUNT(K)
                  FROM NGD_CVG WHERE K IS NOT NULL )
         THEN 'OK' ELSE 'NG'
       END AS ANSWER_TREE_EQUALS_HEAP
  FROM DUAL;

-- 행 수가 크래시 전과 같은가 (커밋된 것은 살고, 그 이상 살지 않는다)
SELECT CASE WHEN COUNT(*) = 150 THEN 'OK' ELSE 'NG' END AS ROWCOUNT_PRESERVED
  FROM NGD_CVG;

--+SECTOR; B -- 멤버 집합이 살아 있는 파티션과 맞는가

-- ACTIVE 멤버 수 == 살아 있는 파티션 수.
-- DROP 이 남긴 자리는 DROPPED 로 남지만 ACTIVE 로 세어지면 안 된다.
SELECT CASE
         WHEN ( SELECT COUNT(*) FROM V$DISK_BTREE_GLOBAL_MEMBER
                 WHERE INDEX_NAME = 'NGD_CVG_G' AND STATE_NAME = 'ACTIVE' )
            = ( SELECT COUNT(*)
                  FROM SYSTEM_.SYS_TABLE_PARTITIONS_ TP, SYSTEM_.SYS_TABLES_ T
                 WHERE TP.TABLE_ID = T.TABLE_ID AND T.TABLE_NAME = 'NGD_CVG' )
         THEN 'OK' ELSE 'NG'
       END AS ACTIVE_MEMBERS_MATCH_LIVE_PARTS
  FROM DUAL;

SELECT STATE_NAME, COUNT(*) AS SLOTS
  FROM V$DISK_BTREE_GLOBAL_MEMBER
 WHERE INDEX_NAME = 'NGD_CVG_G'
 GROUP BY STATE_NAME ORDER BY STATE_NAME;

--+SECTOR; C -- 유일성이 재기동을 건넜는가

-- 다른 파티션에 같은 키 -- 트리가 하나이므로 실패해야 한다.
INSERT INTO NGD_CVG VALUES ( 350, 1001, 'DUP-AFTER' );
SELECT CASE WHEN COUNT(*) = 150 THEN 'OK' ELSE 'NG' END AS UNIQUE_STILL_ENFORCED
  FROM NGD_CVG;

--+SECTOR; D -- 판별자가 재기동을 건넜는가

SELECT CASE WHEN COUNT(*) = 1 THEN 'OK' ELSE 'NG' END AS NATIVE_AFTER_RESTART
  FROM SYSTEM_.SYS_PART_INDICES_ P, SYSTEM_.SYS_INDICES_ I
 WHERE P.INDEX_ID = I.INDEX_ID
   AND P.PARTITION_TYPE = 101
   AND I.INDEX_NAME = 'NGD_CVG_G';

--+SECTOR; E -- ★ 수동 개입 없이 곧바로 쓸 수 있는가

-- 재기동 직후, REBUILD 를 부르지 않은 채로 새 키를 넣는다.
-- V5 이전의 성공 기준은 여기서 수동 복구를 요구했다.
INSERT INTO NGD_CVG VALUES ( 5, 9999, 'AFTER' );
COMMIT;

SELECT CASE
         WHEN ( SELECT /*+ INDEX( NGD_CVG, NGD_CVG_G ) */ COUNT(*)
                  FROM NGD_CVG WHERE K = 9999 ) = 1
         THEN 'OK' ELSE 'NG'
       END AS WRITABLE_WITHOUT_REBUILD
  FROM DUAL;

SELECT CASE
         WHEN ( SELECT /*+ FULL SCAN( NGD_CVG ) */ COUNT(*) FROM NGD_CVG )
            = ( SELECT /*+ INDEX( NGD_CVG, NGD_CVG_G ) */ COUNT(K)
                  FROM NGD_CVG WHERE K IS NOT NULL )
         THEN 'OK' ELSE 'NG'
       END AS ANSWER_STILL_AGREES
  FROM DUAL;

--+SECTOR; FINALIZE

--+SKIP BEGIN;
DROP TABLE NGD_CVG;
--+SKIP END;
