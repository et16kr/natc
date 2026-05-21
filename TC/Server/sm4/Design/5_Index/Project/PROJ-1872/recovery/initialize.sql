--###########################################################################
--# PROJ-1872 PAGE SIZE ESTIMATION
--###########################################################################

--+SKIP BEGIN;
DROP TABLE D1;
--+SKIP END;

CREATE TABLE D1 (I1 INTEGER) TABLESPACE SYS_TBS_DISK_DATA;
CREATE INDEX D1X ON D1( I1 );

CREATE VIEW NODE_SIZE AS
    SELECT
        MY_PAGEID, HEIGHT, IS_LEAF, SLOT_CNT, TOTAL_FREE_SIZE,
        CTL_SIZE*40 + (CASE WHEN IS_LEAF='T' THEN 8 ELSE 0 END) AS CTL_SIZE
    FROM D$DISK_INDEX_BTREE_STRUCTURE( D1X );

CREATE VIEW KEY_SIZE AS
    SELECT
        MY_PAGEID,
        SUM(COLUMN_LENGTH) AS TOTAL_KEY_SIZE
    FROM D$DISK_INDEX_BTREE_KEY( D1X )
    GROUP BY MY_PAGEID;

CREATE VIEW PAGE_SIZE_ESTIMATION AS
SELECT
    NODE.MY_PAGEID                                                  AS MY_PAGEID,
    NODE.HEIGHT                                                     AS HEIGHT,
    NODE.SLOT_CNT                                                   AS SLOT_CNT,
    NODE.TOTAL_FREE_SIZE                                            AS TOTAL_FREE_SIZE,
    (CASE WHEN NODE.IS_LEAF ='T' THEN 10 ELSE 14 END)*NODE.SLOT_CNT AS TOTAL_INFO_SIZE,
    KEYSIZE.TOTAL_KEY_SIZE                                          AS TOTAL_KEY_SIZE,
    CTL_SIZE                                                        AS CTL_SIZE,
    NODE.TOTAL_FREE_SIZE + KEYSIZE.TOTAL_KEY_SIZE
        + (CASE WHEN NODE.IS_LEAF ='T' THEN 10 ELSE 14 END)*NODE.SLOT_CNT
        + CTL_SIZE + 116                                            AS PAGE_SIZE
FROM
    NODE_SIZE AS NODE,
    KEY_SIZE  AS KEYSIZE
WHERE
    NODE.MY_PAGEID = KEYSIZE.MY_PAGEID;


DROP INDEX D1X;
DROP TABLE D1;
