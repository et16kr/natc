# AI Coding Agent TC Brief

이 문서는 AI coding agent에게 일반 `.tc` 테스트 케이스 작성을 요청할 때
단독으로 전달하기 위한 self-contained 브리프다. 이 문서만 보고 작성해야
하며, 다른 문서나 repository-local 도구가 있다고 가정하지 않는다.

FIT, fault injection, WhiteBox, restart/recovery 테스트는 이 브리프의
범위가 아니다. 그런 요청이면 이 브리프로 작업하지 말고 중단한다.

## Scope

이 브리프는 다음 작업에 사용한다.

- 일반 SQL regression test 작성 또는 수정.
- import 가능한 `.tc`, `.lst`, `.ts` artifact 작성.
- 기존 테스트 케이스를 아래 문법에 맞게 정리.
- coverage/repro 설명을 바탕으로 일반 SQL 경로를 검증하는 TC 작성.

## Syntax Status Model

이 브리프에서 command와 syntax는 아래 기준으로 판단한다.

| Status | Meaning |
|---|---|
| `generate` | 일반 TC에서 직접 생성해도 되는 안정적인 문법. |
| `generate-with-care` | 문법은 허용되지만 output 안정성, cleanup, target tool 지원 여부, 환경 계약을 확인해야 하는 문법. |
| `reference-gated` | 이 브리프만으로 생성하지 않는다. 사용자가 정확한 target 환경, 기존 예제, 기대 동작을 제공해야 한다. |
| `avoid` | 새 importable `.tc`에서 생성하지 않는다. deprecated, old-style, local-only, 또는 일반 TC에 부적절한 문법. |

Syntax class:

| Class | Meaning |
|---|---|
| `real_source` | `.tc` 또는 `.i` source 문법으로 사용할 수 있는 형태. |
| `old_style_sql_directive` | 과거 SQL file에 쓰이던 `--+` control line. 새 `.tc` 예제로 쓰지 않는다. |
| `local_only` | 특정 repository, local runner, smoke fixture, generated output에만 의미 있는 형태. |

Hard rule: 이 브리프의 tables에 없는 command, option, std function,
environment behavior는 생성하지 말고 blocker로 보고한다.

## Syntax Compatibility Inventory

File shape:

| Area | Status | Agent rule |
|---|---|---|
| `.tc` source with `INCLUDE`, optional `DECLARE`, `DEF MAIN()`, helper `DEF`, sectors | `generate` | 새 case의 기본 형태다. |
| `.i` include files | `generate-with-care` | `.i` helper만 include한다. included file은 `MAIN`을 정의하면 안 된다. |
| `.ts` suite files | `generate` | 한 줄에 하나의 relative `.tc` path를 적는다. |
| top-level executable `SECTOR`-only `.tc` | `avoid` | legacy/local shape다. 새 case에는 쓰지 않는다. |
| old-style `--+SECTOR`, `--+SET_ENV`, `--+SYSTEM` 등 | `avoid` | old-style SQL directive다. |

Structural syntax:

| Syntax | Status | Agent rule |
|---|---|---|
| `INCLUDE include.i;` | `generate` | `stdFunc.i`는 일반적으로 허용된다. custom include는 artifact tree 안에서 관리한다. |
| `DEF MAIN()` | `generate` | 필수 entry point. |
| `DEF helper( @aArg )` | `generate` | case-local helper에 사용한다. |
| `CALL helper();`, `$sRet = CALL helper();` | `generate` | helper 호출에 사용한다. |
| `RETURN value;` | `generate` | helper function 안에서만 사용한다. |
| `SECTOR; description` | `generate` | `MAIN` 안에서 required order를 지킨다. |
| `$name`, `${name}` | `generate` | 변수. SQL/string 안에서는 braced form을 선호한다. |
| `@name`, `@{name}` | `generate` | function argument. |
| `#`, `--#`, `<# ... #>` comments | `generate` | source 설명에 사용한다. |

Basic values and SQL:

| Syntax | Status | Agent rule |
|---|---|---|
| `$name = expression;` | `generate` | 문자열, 숫자, 변수 참조, 간단한 산술에 사용한다. |
| double-quoted strings | `generate` | 변수 확장이 필요하면 사용한다. |
| single-quoted strings | `generate-with-care` | 확장이 없어야 할 때만 사용한다. |
| `SQL Statement;` | `generate` | 일반 TC의 기본 검증 방식. |
| `SQL Statement; > $var;` | `generate-with-care` | SQL output을 변수로 capture하고 visible oracle output에서는 숨긴다. |
| `--@SQL Statement;` | `generate-with-care` | variable-expanding SQL prefix. 꼭 필요할 때만 사용한다. |
| `--$SQL Statement;` | `generate-with-care` | literal `${...}` SQL이 필요할 때만 사용한다. |

Control:

| Command | Status | Syntax / rule |
|---|---|---|
| `IF` / `ELSIF` / `ELSE` | `generate` | Use block braces on their own lines. |
| `FEXIST` | `generate` | `IF ( FEXIST "path" )` with a normal block. |
| `LIKE` | `generate-with-care` | tool별 regex/containment 차이가 있을 수 있다. |
| `LOOP` | `generate` | `LOOP 10 { ... }`. finite positive count만 사용한다. |
| `FOR` | `generate` | `FOR $sValue IN 1 2 3 { ... }`. |
| `BREAK` | `generate` | `LOOP` 또는 `FOR` 안에서만 사용한다. |
| `ATAF_EXIT` | `avoid` | 일반 generated TC에서 쓰지 않는다. |
| `FAIL_HANDLER` | `avoid` | deprecated. |

Data control:

| Command | Status | Syntax / rule |
|---|---|---|
| `GETCOLUMN` | `generate` | `GETCOLUMN [-d delim] [-i n] "format" $source $dest;`. |
| `GETROW` | `generate` | `GETROW [-v] [-r] "pattern" $source $dest;` 또는 line number form. |
| `TAIL` | `generate` | `TAIL [-n n] [-r] $source $dest;`. |
| `LPAD`, `RPAD`, `SORT`, `QUERY_SORT` | `avoid` | 이 브리프만으로 생성하지 않는다. |

Environment and client/server:

| Command | Status | Syntax / rule |
|---|---|---|
| `SET_ENV` | `generate-with-care` | `SET_ENV NAME="value";`. restart/env restore 계약이 필요하다. |
| `UNSET_ENV` | `generate-with-care` | `UNSET_ENV NAME;`. 설정 복구가 명확할 때만 사용한다. |
| `DECLARE SERVER` | `reference-gated` | target `server.conf` 또는 equivalent 환경 계약이 필요하다. |
| `DECLARE CLIENT` | `reference-gated` | target `client.conf` 또는 equivalent 환경 계약이 필요하다. |
| `RESTART_CLIENT` | `reference-gated` | client env 변경과 target tool behavior가 명확해야 한다. |
| `CLIENT_COMMAND`, `CLIENT_PROMPT`, `CLIENT` | `avoid` | standalone form은 생성하지 않는다. |
| `ATAF_PRODUCT_TYPE`, HDB/XDB topology | `reference-gated` | product topology 계약 없이 생성하지 않는다. |

Result control:

| Command | Status | Syntax / rule |
|---|---|---|
| `SKIP` | `generate` | `SKIP BEGIN; ... SKIP END;`. expected cleanup failure에 사용한다. |
| `NODISPLAY` | `generate` | `NODISPLAY ON; ... NODISPLAY OFF;`. noisy setup/cleanup output을 숨긴다. |
| `IGNORE` | `generate-with-care` | comparison을 무력화하므로 매우 제한적으로 사용한다. |
| `SET_EXTENSION` | `generate-with-care` | multi-oracle `.lst`가 명확할 때만 사용한다. |

File, process, thread, event, and system commands:

| Command / area | Status | Rule |
|---|---|---|
| `OPEN`, `READ`, `WRITE`, `CLOSE` | `generate-with-care` | artifact tree 안의 relative file에만 사용하고 handle을 닫는다. |
| `PRINT` | `generate` | visible output이므로 `.lst`에 반영한다. |
| `SLEEP` | `generate-with-care` | 유일한 synchronization으로 쓰지 않는다. |
| `MKDIR`, `RMDIR`, `CP`, `MV`, `RM`, `LN`, `FILESIZE`, `CAT` | `generate-with-care` | case가 만든 relative path에 한정한다. |
| `SED`, `GSUB` | `generate-with-care` | regex 차이가 있을 수 있어 단순 패턴만 사용한다. |
| `RAND`, `DATE` | `generate-with-care` | nondeterministic output을 `.lst`에 직접 남기지 않는다. |
| `SHELL`, `EXEC`, `SEND`, `P_WAIT`, `KILL`, `GETPID` | `reference-gated` | external process 계약이 명시된 경우에만 사용한다. |
| `THREAD`, `JOIN` | `reference-gated` | concurrency와 client routing 계약이 명확할 때만 사용한다. |
| `POST`, `WAIT` | `generate-with-care` | thread/event flow가 필요한 경우에만 사용한다. |
| `SERVER_WAIT` | `avoid` | server connection tracking 계약 없이 생성하지 않는다. |
| `MAKE` | `reference-gated` | source/build/cleanup 계약이 필요하다. |

Fault injection and WhiteBox:

| Area | Status | Agent rule |
|---|---|---|
| `fitclient`, `stdFit.i`, `##fail`, `##success` | `avoid` | 일반 TC 브리프에서는 생성하지 않는다. |
| `FIT_RESTART_ENABLE`, `FIT_CONNECT_RETRY`, `FIT_CONNECT_WAIT_SEC`, `FIT_PROCESS_TYPE` | `avoid` | FIT/recovery 전용이다. |
| `ATAF_IGNORE`, `ATAF_RECON_TRC_ENABLE`, `SET_RESTART` | `avoid` | 일반 TC에서 생성하지 않는다. |
| `ART_*`, `SETLIMITPOINT` | `avoid` | WhiteBox/deprecated 영역이다. |

Standard library:

| Function / include | Status | Agent rule |
|---|---|---|
| `stdFunc.i` | `generate` | 일반 TC에서 include 가능하다. |
| `stdClean()` | `generate-with-care` | full DB isolation이 필요한 initialization에만 사용한다. |
| server lifecycle `std*` helpers | `reference-gated` | lifecycle/recovery 계약이 필요하다. |
| other `std*` functions | `reference-gated` | signature와 side effect가 제공되지 않으면 생성하지 않는다. |

## Artifact Shape

전달할 artifact directory layout은 target tool이나 project 규칙을 따른다.
아래 구조는 정리하기 쉬운 예시일 뿐, 필수 구조가 아니다. 필수 규칙은
`.tc`와 tagged `.lst` oracle 관계, 그리고 `.ts`의 relative `.tc` 참조다.

```text
import_artifacts/
  suites/
    productArea.ts
  cases/
    productArea/
      caseName.tc
      caseName_A4_64.lst
      supporting_input.dat
```

Rules:

- 각 `.tc`는 tagged oracle `.lst`를 가진다. 기본 oracle tag는 `A4_64`다.
- validator/runner는 지정된 `.tc` file 또는 directory 아래의 `.tc` files를
  대상으로 삼을 수 있다.
- `.ts` suite file은 실행할 `.tc` path를 한 줄에 하나씩 적는다.
- `.ts` 안의 path는 suite file 기준 상대 경로를 사용한다.
- supporting data file은 artifact tree 안에 두고 상대 경로로 참조한다.
- local run output, temporary files, parser traces, AI notes는 artifact에
  넣지 않는다.
- `.ts`에는 executable setup logic을 넣지 않는다.

Oracle file naming:

- Default oracle for `caseName.tc` is `caseName_A4_64.lst`.
- Do not use plain `caseName.lst` for the default case.
- If the target tool defines a different oracle/platform tag, use
  `caseName_<TAG>.lst`.
- If `SET_EXTENSION "name";` is active, use
  `caseName_A4_64_name.lst`.
- Numbered oracle variants use `_1` through `_9`, for example
  `caseName_A4_64_1.lst`.
- Host-specific oracle variants may exist in some target environments, but do
  not generate them unless the environment contract requires them.

Example `.ts`:

```text
TestListDescription  =  PROJECT-0000 Product area regression
###############################################################################
../cases/productArea/basicInsertSelect.tc
../cases/productArea/boundaryValueOrder.tc
###############################################################################
```

## Naming And Formatting

Naming:

- Use `.tc` for test cases and `.ts` for suites.
- Use lowercase or lower camel case for normal file and directory names.
- Preserve uppercase project, bug, or task IDs, for example `BUG-47736.tc`.
- Avoid special characters in test, suite, and directory names.
- Use suite names that match their directory when a directory has a primary
  suite.

Good names:

```text
insert.tc
rollbackQuery.tc
finalizeForProperty.tc
BUG-47736.tc
```

Avoid:

```text
INSERT.tc
UseMemoryManager.tc
for_disk_index_manager.tc
for-disk-index-manager.tc
Finalize(For)Property.tc
```

Formatting:

- Use uppercase source keywords: `DEF`, `MAIN`, `CALL`, `IF`, `THREAD`,
  `JOIN`, `SET_ENV`, `NODISPLAY`, and so on.
- Use four spaces for indentation. Do not use tabs.
- Put block braces on their own lines.
- End statements with semicolons unless the syntax starts a block.
- Put comments on their own lines above the source they explain.
- Keep SQL keywords uppercase in newly written SQL.
- Use one space around operators and after keywords.
- Do not put a space between a function name and `(` in definitions or calls.

Correct block style:

```text
IF ( $sCount > 0 )
{
    PRINT "HAS_ROWS";
}
ELSE
{
    PRINT "NO_ROWS";
}
```

## Required TC Shape

새 importable `.tc`는 아래 구조를 기본으로 한다.

```text
###########################################################################
# TestCase Description = Short deterministic purpose.
# Project ID           = PROJECT-0000
###########################################################################
INCLUDE stdFunc.i;

DEF MAIN()
{
##################################
SECTOR; INITIALIZATION
##################################
    SKIP BEGIN;
    DROP TABLE T_AGENT_EXAMPLE;
    SKIP END;

##################################
SECTOR; PREPARATION
##################################
    CREATE TABLE T_AGENT_EXAMPLE ( I1 INTEGER );
    INSERT INTO T_AGENT_EXAMPLE VALUES ( 1 );

##################################
SECTOR; TEST
##################################
    SELECT I1 FROM T_AGENT_EXAMPLE ORDER BY I1;

##################################
SECTOR; FINALIZATION
##################################
    SKIP BEGIN;
    DROP TABLE T_AGENT_EXAMPLE;
    SKIP END;
}
```

Required rules:

- Leading comments must include `TestCase Description`.
- `Project ID` should be present when a project, task, bug, or request ID is
  known.
- `DEF MAIN()` is the only entry point for executable test flow.
- Required sectors inside `MAIN` appear in this order:
  `INITIALIZATION`, `PREPARATION`, `TEST`, `FINALIZATION`.
- The test sector may be literal `SECTOR; TEST` or descriptive, such as
  `SECTOR; INSERT BOUNDARY TEST`, as long as it remains in the test position.
- Use braces on their own lines.
- End statements with semicolons.

## Source Syntax

Comments:

```text
# line comment
--# line comment
<#
block comment
#>
```

Variables:

```text
$sName = "value";
$sNumber = 10;
$sLabel = "row-" || "one";
PRINT $sName;
```

Rules:

- Values may be `INT`, `FLOAT`, or `STRING`.
- Common numeric operators are `+`, `-`, `*`, `/`, and `%`.
- String concatenation uses `||`.
- Global variable names start with `g`, for example `$gTotalCount`.
- Local variable names start with `s`, for example `$sCount`.
- Function arguments start with `a`, for example `@aTableName`.
- Initialize variables before arithmetic or comparison.
- Assign one variable per line.
- Use `${sName}` for variable expansion inside SQL or strings.
- Use `@{aName}` for function argument expansion inside SQL or strings.
- Escape expansion when a literal is required: `\${sName}`.
- Double-quoted strings expand `${...}` and `@{...}`.
- Single-quoted strings do not expand variables.
- Common escapes include `\n`, `\t`, `\"`, `\'`, escaped `\${...}`, and `\\`.
- Do not rely on uninitialized variables for numeric work.

Functions:

```text
DEF helper( @aInput )
{
    RETURN @aInput;
}

$sResult = CALL helper("value");
```

Rules:

- Helper functions are allowed for repeated case-local logic.
- Function arguments use `@name`.
- Do not define another `MAIN`.
- Do not invent standard library function names or signatures.
- Helper functions may be defined after `MAIN`.
- Include files may define helper functions but must not define `MAIN`.
- Keep function arguments explicit and readable.

Include rules:

```text
INCLUDE include_file_name;
```

- Use `.i` include files only.
- `INCLUDE stdFunc.i;` is allowed for normal cases.
- Do not use absolute, wildcard, variable, or generated include paths.
- Keep custom include files under the same artifact tree or target environment
  include location.

SQL:

```text
CREATE TABLE T1 ( I1 INTEGER );
INSERT INTO T1 VALUES ( 1 );
SELECT I1 FROM T1 ORDER BY I1;
DROP TABLE T1;
```

Rules:

- Prefer direct SQL statements.
- Use `SQL Statement; > $sDestination;` only when SQL output must be captured
  for TC processing instead of normal `.lst` comparison.
- `--@SQL Statement;` expands variables like normal SQL.
- `--$SQL Statement;` keeps the SQL body unexpanded.
- Add `ORDER BY` when row order affects `.lst` output.
- Keep setup DDL and data creation in `PREPARATION`.
- Keep assertions and selected output in `TEST`.
- Drop objects created by the case in `FINALIZATION`.
- Use unique object names to avoid collision with other tests.
- Use `SKIP BEGIN` / `SKIP END` around best-effort cleanup.
- Avoid current timestamps, random values, unordered scans, and environment
  specific output unless hidden or normalized.
- If a displayed expression has an oversized type width, such as `LISTAGG`,
  `CLOB`, or a long `VARCHAR`, normalize the visible output with `CAST(... AS
  VARCHAR(n))` after any needed `SUBSTR` so the oracle stays reviewable.
- When substituting string values into SQL, include SQL quotes explicitly:
  `VALUES ( '${sValue}' )`.

Output control:

```text
NODISPLAY ON;
DROP TABLE T1;
NODISPLAY OFF;
```

- Use `NODISPLAY` only to hide noisy setup/cleanup output.
- Do not hide the result that the test is meant to verify.

Data extraction:

```text
SELECT COUNT(*) FROM T1; > $sRows;
GETROW 1 $sRows $sLine;
GETCOLUMN "${1}" $sLine $sCount;
PRINT $sCount;
```

Use `GETROW`, `GETCOLUMN`, or `TAIL` only when the test needs to parse captured
output in TC logic. Prefer plain SQL output and `.lst` comparison when possible.

Control flow:

```text
IF ( $sCount == "1" )
{
    PRINT "PASS";
}
ELSE
{
    PRINT "FAIL";
}

LOOP 3
{
    PRINT "loop";
}

FOR $sValue IN 1 2 3
{
    PRINT $sValue;
}
```

Use finite loops only. Keep generated logic simple enough to audit.

File commands may be used only for files inside the artifact tree:

```text
OPEN OUT -m w "relative/path/out.txt";
WRITE OUT "content";
CLOSE OUT;
```

Always close opened handles.

## Result Oracle

Tagged `.lst` files are the expected visible output for `.tc` files.

Rules:

- Create or update the tagged `.lst`, normally `caseName_A4_64.lst` for
  `caseName.tc`.
- Generate `.lst` from a real target-tool run when possible.
- Do not guess complex database error text or nondeterministic output.
- A newly generated `.tc` is not complete until the matching tagged `.lst` is
  present. Run the exact target command, inspect the generated `.out`, copy it
  to the tagged `.lst` only when the SQL result is intentional, then rerun the
  same command and confirm PASS.
- Stabilize result ordering with `ORDER BY`.
- Hide setup/cleanup noise instead of recording unstable cleanup failures.
- Use `SKIP` only for expected errors or cleanup attempts whose output should
  not fail the case.
- Keep only intentional, user-visible verification output in `.lst`.
- Review copied `.out` or runner output before accepting it as `.lst`.
- Do not run broad cleanup helpers in `FINALIZATION` just to clean generated
  objects. Drop the objects created by the case.

Multi-oracle support:

```text
SET_EXTENSION "extension";
SET_EXTENSION "";
```

Use `SET_EXTENSION` only when the case intentionally switches expected-result
files and the matching tagged oracle files are provided. For example,
`caseName.tc` with `SET_EXTENSION "memory";` uses
`caseName_A4_64_memory.lst`.

## Hard Stops

Stop and report the blocker instead of guessing when:

- The requested syntax is not described in this brief.
- The expected `.lst` cannot be derived from deterministic output.
- The test needs server restart, multi-server topology, HDB/XDB, WhiteBox,
  fault injection, external processes, or product-specific environment setup.
- The test needs a standard helper whose signature is unknown.
- The target tool requires an artifact layout that conflicts with this brief.

## Do Not Generate

- FIT, `fitclient`, `stdFit.i`, `##fail`, `##success`.
- WhiteBox, fault injection, restart/recovery, HDB/XDB, or multi-server logic.
- Old-style `--+` directives.
- `SQL BEGIN` / `SQL END`.
- Top-level executable `SECTOR`-only `.tc` files.
- Shell or Python wrappers for behavior that TC syntax can express directly.
- Absolute local paths.
- AI metadata comments, prompt notes, or local-only implementation notes inside
  import artifacts.

## Validation

Use the target tool's validator or runner, not repository-local commands from
this brief. Before finishing, verify at least:

- Every `.tc` parses.
- Every `.tc` has the required tagged `.lst`, normally `_A4_64.lst`.
- Every `.ts` references existing `.tc` files by valid relative paths.
- Required sectors exist in the correct order.
- The visible output matches `.lst`.
- No old-style directives, local-only paths, AI metadata, absolute local paths,
  or hidden shell wrapper dependencies are present.
- Output is deterministic or intentionally hidden/normalized.

## Prompt Template

```text
You are an AI coding agent creating importable TC artifacts.

Use only the syntax and rules in this brief. Do not assume access to additional
documents or repository-local tools. Create .tc and tagged .lst files, and
create .ts suite files when a suite is needed.

Use tagged oracle names. For caseName.tc, create caseName_A4_64.lst unless the
target tool explicitly requires another oracle tag.

This is a normal SQL regression TC request. Do not use FIT, fitclient,
WhiteBox, restart/recovery controls, old-style --+ directives, local helper
paths, shell wrappers, or guessed complex oracle output.

Validate with the target tool's parser/runner before finishing and report any
blocker instead of inventing unsupported syntax.
```
