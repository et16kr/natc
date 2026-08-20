# 결함 보고 — `FROM TABLE SCHEMA` 가 프로퍼티 게이트를 지나친다

- 발견: 2026-08-20
- 방법: `NativeGlobalIndex-TC-Method.md` **수-1 형제 훑기**
- 감시자: `TC/.../NativeGlobalIndexClaude/Memory/Create/createPathSweep.tc` (D 절)
- 상태: **`.lst` 미기록** — 지금 동작을 기대값으로 굳히지 않는다

---

## 1. 한 문장

`MEM_GLOBAL_INDEX_ENABLE = 0`(또는 `DISK_` = 0) 인 상태에서
**`CREATE TABLE ... FROM TABLE SCHEMA ... USING PREFIX ...` 는
네이티브 글로벌 인덱스를 만들어 준다.** 같은 인덱스를 `CREATE INDEX` ·
`ADD CONSTRAINT` · `CREATE TABLE ... PRIMARY KEY` 로 만들려 하면 전부
거절되는데, 이 경로만 통과한다.

---

## 2. 재현

```sql
ALTER SYSTEM SET MEM_GLOBAL_INDEX_ENABLE = 1;

CREATE TABLE VG_SRC ( P INTEGER, K INTEGER, V VARCHAR(16) )
PARTITION BY RANGE ( P )
( PARTITION P1 VALUES LESS THAN (10), PARTITION PD VALUES DEFAULT )
TABLESPACE SYS_TBS_MEM_DATA;

-- 파티션 키 P 를 포함하지 않는 키 -> 글로벌이어야만 선다
CREATE UNIQUE INDEX VG_SRC_U ON VG_SRC ( K ) TABLESPACE SYS_TBS_MEM_DATA;

-- ★ 게이트를 닫는다
ALTER SYSTEM SET MEM_GLOBAL_INDEX_ENABLE = 0;

CREATE TABLE VG_COPY FROM TABLE SCHEMA VG_SRC USING PREFIX ZZ;
--> Create success.
```

```sql
SELECT I.INDEX_NAME, DECODE(I.INDEX_TABLE_ID,0,'NATIVE','GIT') IMPL,
       P.PARTITION_TYPE
  FROM SYSTEM_.SYS_INDICES_ I, SYSTEM_.SYS_TABLES_ T,
       SYSTEM_.SYS_PART_INDICES_ P
 WHERE I.TABLE_ID = T.TABLE_ID AND P.INDEX_ID = I.INDEX_ID
   AND T.TABLE_NAME = 'VG_COPY';
```

```
INDEX_NAME    IMPL    PARTITION_TYPE
ZZVG_SRC_U    NATIVE  101
```

**`DISK_GLOBAL_INDEX_ENABLE = 0` 에서도 같다** — `ZZVGD_SRC_U` / `NATIVE` / `101`.

---

## 3. 카탈로그 흔적이 아니라 **작동하는 인덱스**다

```sql
INSERT INTO VG_COPY VALUES (1,  500, 'a');   --> 1 row inserted.
INSERT INTO VG_COPY VALUES (21, 500, 'b');   --> [ERR-11058 : The row already
                                             --    exists in a unique index.]
SELECT COUNT(*) FROM VG_COPY;                --> 1
```

두 행은 **서로 다른 파티션**(P1 과 PD)에 들어간다. 파티션 간 중복이
거절된다는 것은 **하나의 트리가 파티션을 가로질러 서 있다**는 뜻이고,
로컬 인덱스는 그렇게 하지 못한다. 즉 게이트가 닫힌 인스턴스에
**기능하는 네이티브 글로벌 인덱스**가 존재한다.

---

## 4. 형제 대조 — 같은 게이트, 네 경로

프로퍼티를 0 으로 두고 같은 모양의 인덱스를 네 경로로 만들어 봤다.

| 경로 | 검증기 호출 | 결과 |
|---|---|---|
| `CREATE INDEX` | `qdx::validateIndexRestriction` | 거절 `ERR-313D0` |
| `ALTER TABLE ADD CONSTRAINT UNIQUE` | `qdbCommon::createConstrPrimaryUnique` | 거절 `ERR-31415` |
| `CREATE TABLE (... PRIMARY KEY ...)` | `qdbCommon::createConstrPrimaryUnique` | 거절 `ERR-31415` |
| **`CREATE TABLE ... FROM TABLE SCHEMA`** | **없음** | **Create success.** |

---

## 5. 왜 그런가 — 좌표

`qdx::validateNativeGlobalIndex` 를 부르는 자리는 소스 전체에서 **셋뿐**이다.

```
src/qp/qdx/qdx.cpp:3454       qdx::validateAlterRebuild
src/qp/qdx/qdx.cpp:11362      qdx::validateIndexRestriction
src/qp/qdb/qdbCommon.cpp:6931 qdbCommon::createConstrPrimaryUnique
```

`FROM TABLE SCHEMA` 는 `src/qp/qdb/qdbCopySwap.cpp` 가 처리하고, 그
파일에는 그 호출이 **없다.** 원본의 인덱스 정의를 그대로 복제하므로
게이트를 물어볼 기회 자체가 없다.

---

## 6. 왜 문제인가

1. **은퇴 회계가 샌다.** J24(V4 D-2)는 프로퍼티 0 의 뜻을
   "네이티브 글로벌 인덱스를 만들 수 없다" 로 정하고 덮는 문장을 회계했다.
   이 경로가 그 회계 밖이다. V4 리뷰 §3 이 찾은 여섯 번째 경로(DIRECTKEY)와
   **같은 종류의 누락**이다.
2. **게이트가 탈출구로 쓰인다.** 프로퍼티 0 은 "네이티브를 쓰지 않겠다" 는
   운영 결정인데, 스키마 복제 한 번으로 그 결정이 뒤집힌다. 복제된 테이블은
   사용자가 끄기로 한 구현 위에 선다.
3. **다른 거절도 함께 지나칠 가능성.** 이 경로가 검증기를 아예 안 거치므로,
   프로퍼티만이 아니라 검증기가 막는 **다른 조합**(휘발성·혼합 매체
   `ERR-314AB`, 함수 기반·압축 키 `ERR-314AD`, 인덱스 예산 64 `ERR-314AC`,
   키 길이 상한 `ERR-311E0`)도 같이 새는지 확인해야 한다.
   **아직 확인 안 했다 — 후속 작업.**

---

## 7. 고칠 자리 제안

`qdbCopySwap` 의 인덱스 복제 지점에서 원본 인덱스가 네이티브 글로벌이면
`qdx::validateNativeGlobalIndex` 를 태우거나, 최소한 게이트를 물어
거절한다. 거절 코드는 형제 경로와 같아야 한다 —
`CREATE INDEX` 가 내는 `ERR-313D0`, 제약이면 `ERR-31415`.

**대안 판정**: 복제를 허용하되 **로컬 인덱스로 낮춰** 만드는 것도 가능한
설계다. 다만 그 경우 "스키마 복제 결과가 원본과 다르다" 가 되므로
복제의 계약을 바꾸는 결정이고, 문서로 남겨야 한다.

---

## 8. 후속

- [ ] §6-3 의 다른 거절 조합도 이 경로로 새는지 훑는다 (수-1 계속)
- [ ] `ALTER TABLE ... ALL INDEX ENABLE`, 복제 메타 DDL 등 **검증기를 안
      거치는 다른 경로**가 더 있는지 소스에서 센다
- [ ] 수정이 들어오면 `createPathSweep.tc` D 절이 A~C 와 같은 거절을 내는지
      확인하고 그때 `.lst` 를 찍는다
