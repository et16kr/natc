# 결함 보고 — `FROM TABLE SCHEMA` 가 프로퍼티 게이트를 지나친다

- 발견: 2026-08-20
- 방법: `NativeGlobalIndex-TC-Method.md` **수-1 형제 훑기**
- 감시자: `TC/.../NativeGlobalIndexClaude/Memory/Create/createPathSweep.tc` (D 절)
- 상태: **수정 완료 / 국소 검증 완료** — 후속 조합 감사는 §8 참조

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
--> 수정 전: Create success.
--> 수정 후: [ERR-313D0]
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
수정 전:
INDEX_NAME    IMPL    PARTITION_TYPE
ZZVG_SRC_U    NATIVE  101

수정 후에는 `VG_COPY` 자체가 생성되지 않는다.
```

**`DISK_GLOBAL_INDEX_ENABLE = 0` 에서도 같다** — `ZZVGD_SRC_U` / `NATIVE` / `101`.

---

## 3. 카탈로그 흔적이 아니라 **작동하는 인덱스**였다

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

수정 후에는 복사 테이블이 생성되지 않으므로 위 INSERT의 대상이 없다.
게이트가 열린 상태에서 만든 원본과 정상적인 스키마 복사는 기존 동작대로
유지된다.

---

## 4. 형제 대조 — 같은 게이트, 네 경로

프로퍼티를 0 으로 두고 같은 모양의 인덱스를 네 경로로 만들어 봤다.

| 경로 | 검증기 호출 | 결과 |
|---|---|---|
| `CREATE INDEX` | `qdx::validateIndexRestriction` | 거절 `ERR-313D0` |
| `ALTER TABLE ADD CONSTRAINT UNIQUE` | `qdbCommon::createConstrPrimaryUnique` | 거절 `ERR-31415` |
| `CREATE TABLE (... PRIMARY KEY ...)` | `qdbCommon::createConstrPrimaryUnique` | 거절 `ERR-31415` |
| **`CREATE TABLE ... FROM TABLE SCHEMA`** | **없음 (수정 전)** | **수정 전 Create success → 수정 후 `ERR-313D0`** |

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

## 7. 수정 내용

`src/qp/qdb/qdbCopySwap.cpp`의
`qdbCopySwap::validateCreateTableFromTableSchema`에 원본 테이블의
네이티브 글로벌 인덱스 존재 여부를 확인하는 게이트를 추가했다.

원본이 네이티브 글로벌 인덱스를 갖고 있으면 다음을 수행한다.

1. `snapshotGlobalIndexEnable()`로 해당 DDL 문장의 프로퍼티를 고정한다.
2. 논리 테이블과 모든 파티션의 매체 개수를 계산한다.
3. 형제 생성 경로와 같은 `qdx::isNativeGlobalIndexMedia()`를 호출한다.
4. 게이트가 닫혀 있으면 `ERR-313D0`으로 실패시키고 대상 테이블을 만들지 않는다.

게이트가 열려 있으면 기존 복제 동작을 그대로 둔다. 메모리·디스크의
게이트 off와 on을 확인했고, `createPathSweep.tc`를 두 번 실행해
연속 PASS를 확인했다.

**대안 판정**: 복제를 허용하되 **로컬 인덱스로 낮춰** 만드는 것도 가능한
설계다. 다만 그 경우 "스키마 복제 결과가 원본과 다르다" 가 되므로
복제의 계약을 바꾸는 결정이고, 문서로 남겨야 한다.

---

## 8. 후속 — 아직 닫지 않은 감사 항목

- [ ] §6-3의 다른 제한도 `FROM TABLE SCHEMA`에서 새는지 확인한다:
      휘발성·혼합 매체(`ERR-314AB`), 함수 기반·압축 키(`ERR-314AD`),
      인덱스 비트 예산 64(`ERR-314AC`), 키 길이 상한(`ERR-311E0`).
- [ ] 소스에서 인덱스를 생성·복제하는 경로를 다시 세고,
      `ALL INDEX ENABLE/DISABLE` 및 복제 메타 DDL처럼 같은 검증기를
      우회할 수 있는 경로를 분리한다.
- [ ] 현재 Disk 회귀의 9건 실패를 기준 빌드와 비교해 서버 회귀인지,
      기존 포팅 케이스의 절대 카탈로그 ID·환경 의존성인지 판정한다.
      현재 관측 목록은 `pdtBug_INITIALIZE`, `pdtBug_BUG-9`,
      `createTableAsSelect_RangePartTable`, `createIndexLocal`의
      Range/Hash/List 3건, `alterColumnLob_basic`,
      `statisticsAndHeader`, `qc_JoinTest`다. 이들은 CopySwap 수정의
      직접 실패로 확정된 것이 아니다.
- [x] 수정 후 `createPathSweep.tc`의 D 절이 `ERR-313D0`을 내는 것을
      확인하고 `.lst`를 기록했다.
