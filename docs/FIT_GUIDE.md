# AI Coding Agent FIT Brief

이 문서는 AI coding agent에게 FIT 또는 fault injection 기반 `.tc` 테스트
작성을 명시적으로 요청할 때만 단독으로 전달하기 위한 self-contained
브리프다. 이 문서만 보고 작성해야 하며, 다른 문서나 repository-local
도구가 있다고 가정하지 않는다.

일반 SQL regression test에는 이 문서를 사용하지 않는다.

## Use This Only When

사용자 요청에 아래 의도가 명확히 포함될 때만 사용한다.

- FIT TC 작성.
- `fitclient` 기반 fault rule 작성.
- `##fail` 또는 `##success`를 사용한 SQL outcome 검증.
- 기존 FIT UID를 이용한 reachability, cleanup, error branch 검증.
- 사용자가 명시한 product FIT point 설계 검토.

요청이 일반 SQL TC 작성이면 FIT 문법을 생성하지 않는다.

## Syntax Status Model

이 브리프에서 command와 syntax는 아래 기준으로 판단한다.

| Status | Meaning |
|---|---|
| `generate` | FIT TC에서 직접 생성해도 되는 안정적인 문법. |
| `generate-with-care` | 문법은 허용되지만 output 안정성, cleanup, target tool 지원 여부, 환경 계약을 확인해야 하는 문법. |
| `reference-gated` | 이 브리프만으로 생성하지 않는다. 사용자가 정확한 target 환경, 기존 예제, 기대 동작을 제공해야 한다. |
| `avoid` | 생성하지 않는다. deprecated, old-style, local-only, 또는 FIT TC에 부적절한 문법. |

Syntax class:

| Class | Meaning |
|---|---|
| `real_source` | `.tc` 또는 `.i` source 문법으로 사용할 수 있는 형태. |
| `old_style_sql_directive` | 과거 SQL file에 쓰이던 `--+` control line. 새 `.tc` 예제로 쓰지 않는다. |
| `local_only` | 특정 repository, local runner, smoke fixture, generated output에만 의미 있는 형태. |

Hard rule: 이 브리프의 tables에 없는 command, option, std function,
environment behavior는 생성하지 말고 blocker로 보고한다.

## Common Source Syntax Inventory

FIT TC도 일반 `.tc` source shape를 따르므로 아래 문법 상태를 적용한다.

File and structural syntax:

| Syntax | Status | Agent rule |
|---|---|---|
| `.tc` source with `INCLUDE`, `DEF MAIN()`, helper `DEF`, sectors | `generate` | FIT case의 기본 형태다. |
| `.i` include files | `generate-with-care` | `stdFunc.i`, `stdFit.i`를 사용할 수 있다. included file은 `MAIN`을 정의하면 안 된다. |
| `.ts` suite files | `generate` | 한 줄에 하나의 relative `.tc` path를 적는다. |
| `DEF MAIN()` | `generate` | 필수 entry point. |
| `DEF helper( @aArg )`, `CALL`, `RETURN` | `generate` | case-local helper에 사용한다. |
| `SECTOR; description` | `generate` | `MAIN` 안에서 required order를 지킨다. |
| `$name`, `${name}`, `@name`, `@{name}` | `generate` | 변수와 argument. SQL/string 안에서는 braced form을 선호한다. |
| `#`, `--#`, `<# ... #>` comments | `generate` | source 설명에 사용한다. |
| top-level executable `SECTOR`-only `.tc` | `avoid` | legacy/local shape다. |
| old-style `--+` directives | `avoid` | 새 `.tc` source에 쓰지 않는다. |

Common commands:

| Command / syntax | Status | Rule |
|---|---|---|
| direct SQL statement | `generate` | FIT action이 검증할 SQL은 직접 보이게 작성한다. |
| `SQL Statement; > $var;` | `generate-with-care` | SQL output capture가 꼭 필요할 때만 사용한다. |
| `SKIP` | `generate` | cleanup failure 안정화에 사용한다. |
| `NODISPLAY` | `generate` | noisy setup/cleanup output을 숨긴다. |
| `PRINT` | `generate` | visible output이므로 `.lst`에 반영한다. |
| `GETROW`, `GETCOLUMN`, `TAIL` | `generate-with-care` | FIT verification에 output parsing이 필요할 때만 사용한다. |
| `IF`, `FOR`, `LOOP`, `BREAK`, `FEXIST`, `LIKE` | `generate-with-care` | FIT path를 흐리지 않게 단순하게 사용한다. |
| `OPEN`, `READ`, `WRITE`, `CLOSE` | `generate-with-care` | artifact tree 안의 relative file에만 사용한다. |
| `SHELL`, `EXEC`, `SEND`, `P_WAIT`, `KILL`, `GETPID` | `reference-gated` | external process 계약이 명시된 경우에만 사용한다. |
| `THREAD`, `JOIN`, `POST`, `WAIT` | `reference-gated` | concurrency/event 계약이 명확할 때만 사용한다. |
| environment/server/client commands | `reference-gated` | FIT environment/restart 계약이 필요하다. |
| `SERVER_WAIT`, `ATAF_EXIT`, `FAIL_HANDLER` | `avoid` | 이 브리프만으로 생성하지 않는다. |
| `LPAD`, `RPAD`, `SORT`, `QUERY_SORT` | `avoid` | 이 브리프만으로 생성하지 않는다. |

FIT-specific syntax:

| Syntax / area | Status | Agent rule |
|---|---|---|
| `stdFit.i` | `generate` | FIT TC에서 include한다. |
| core `fitclient` commands | `generate-with-care` | `reset`, `enable`, `mode`, `add`, `update`, `delete`, `lst/list`. |
| `fitclient add -f faultFileName` | `generate-with-care` | fault file이 artifact에 포함되고 형식이 명확할 때만 사용한다. |
| `##fail`, `##success` | `generate-with-care` | 다음 SQL statement 하나에만 적용한다. |
| `fitmon` | `reference-gated` | target tool 지원과 expected output이 명확할 때만 사용한다. |
| FIT recovery/process controls | `reference-gated` | product recovery/process behavior 계약이 필요하다. |
| reconnect/restart/FATAL controls | `reference-gated` | restart/reconnect/FATAL behavior 계약이 필요하다. |
| `ART_*`, `SETLIMITPOINT` | `avoid` | WhiteBox/deprecated 영역이다. |

## Artifact Shape

전달할 artifact directory layout은 target tool이나 project 규칙을 따른다.
아래 구조는 정리하기 쉬운 예시일 뿐, 필수 구조가 아니다. 필수 규칙은
`.tc`와 tagged `.lst` oracle 관계, 그리고 `.ts`의 relative `.tc` 참조다.

```text
import_artifacts/
  suites/
    fitArea.ts
  cases/
    fitArea/
      fitFailureCase.tc
      fitFailureCase_A4_64.lst
```

Rules:

- 각 `.tc`는 tagged oracle `.lst`를 가진다. 기본 oracle tag는 `A4_64`다.
- validator/runner는 지정된 `.tc` file 또는 directory 아래의 `.tc` files를
  대상으로 삼을 수 있다.
- `.ts` suite file은 실행할 `.tc` path를 한 줄에 하나씩 적는다.
- `.ts` 안의 path는 suite file 기준 상대 경로를 사용한다.
- local run output, temporary files, parser traces, AI notes는 artifact에
  넣지 않는다.
- `.ts`에는 executable setup logic을 넣지 않는다.

Oracle file naming:

- Default oracle for `fitFailureCase.tc` is `fitFailureCase_A4_64.lst`.
- Do not use plain `fitFailureCase.lst` for the default case.
- If the target tool defines a different oracle/platform tag, use
  `fitFailureCase_<TAG>.lst`.
- If `SET_EXTENSION "name";` is active, use
  `fitFailureCase_A4_64_name.lst`.
- Numbered oracle variants use `_1` through `_9`, for example
  `fitFailureCase_A4_64_1.lst`.
- Host-specific oracle variants may exist in some target environments, but do
  not generate them unless the environment contract requires them.

Naming and formatting:

- Use `.tc` for test cases and `.ts` for suites.
- Use lowercase or lower camel case for normal file and directory names.
- Preserve uppercase project, bug, or task IDs.
- Avoid special characters in test, suite, and directory names.
- Use uppercase source keywords and SQL keywords.
- Use four spaces for indentation. Do not use tabs.
- Put braces on their own lines.
- End statements with semicolons unless the syntax starts a block.
- Put comments on their own lines above the source they explain.

## Required FIT TC Shape

FIT TC도 일반 TC와 같은 source shape를 사용한다.

```text
###########################################################################
# TestCase Description = Verify target FIT failure path.
# Project ID           = PROJECT-0000
###########################################################################
INCLUDE stdFunc.i;
INCLUDE stdFit.i;

DEF MAIN()
{
##################################
SECTOR; INITIALIZATION
##################################
    fitclient reset;
    fitclient enable on;

    SKIP BEGIN;
    DROP TABLE T_FIT_EXAMPLE;
    SKIP END;

##################################
SECTOR; PREPARATION
##################################
    CREATE TABLE T_FIT_EXAMPLE ( I1 INTEGER );
    INSERT INTO T_FIT_EXAMPLE VALUES ( 1 );

##################################
SECTOR; TEST
##################################
    fitclient add -u ClassOrFile::function::targetStatement::Alias -a jump -c 1;

    ##fail
    SQL_THAT_MUST_FAIL;

    fitclient lst;

##################################
SECTOR; FINALIZATION
##################################
    fitclient reset;

    SKIP BEGIN;
    DROP TABLE T_FIT_EXAMPLE;
    SKIP END;
}
```

Required rules:

- Leading comments must include `TestCase Description`.
- `DEF MAIN()` is the only entry point for executable test flow.
- Required sectors inside `MAIN` appear in this order:
  `INITIALIZATION`, `PREPARATION`, `TEST`, `FINALIZATION`.
- Include `stdFit.i` for FIT TC unless the target environment explicitly uses a
  different FIT setup mechanism.
- `fitclient reset;` appears near the start and again in `FINALIZATION`.
- `fitclient enable on;` appears before `fitclient add`.
- Cleanup must be stable and must not leave registered FIT rules behind.

## FIT Environment Model

FIT has two separate concepts:

- Product/server FIT capability: commonly enabled through `FIT_ENABLE=1` before
  the server starts.
- TC-level fault activation: controlled by `fitclient enable on/off` and
  `fitclient add`.

Do not confuse them. `fitclient enable on` activates registered fault behavior;
it does not replace the target environment's server-start FIT setup.

If the requested test requires server restart or recovery behavior, stop and
ask for the target environment contract unless it is fully specified.

## FIT Test Workflow

Use this workflow for most FIT requests:

1. Identify the target failure path, cleanup path, or reachability point.
2. Confirm the exact existing UID. If no UID is provided or discoverable, stop
   and report the gap.
3. For reachability, start with `fitclient add -u UID -a hit -c 1;`.
4. For failure-path validation, use `fitclient add -u UID -a jump -c 1;` and
   place `##fail` before the SQL expected to fail.
5. Keep setup deterministic and hidden when it is not part of verification.
6. Run the SQL that should hit the FIT point.
7. Use `fitclient lst;` to expose `HIT_COUNT`, `HIT_TOTAL`, and `ACTIVATION`
   when those fields are part of verification.
8. End with `fitclient reset;` in `FINALIZATION`.
9. If product FIT points were added by explicit request, report any new UID
   that lacks a corresponding TC.

## fitclient Commands

Use real `fitclient` commands inside the `.tc`. Do not write action files
directly.

Reset:

```text
fitclient reset;
```

- Clears registered fault rules and hit state.
- Use at the beginning and end of each FIT TC.

Enable:

```text
fitclient enable on;
fitclient enable off;
```

- Activates or deactivates registered fault behavior.
- Use `enable on` before `add`.

Mode:

```text
fitclient mode single;
fitclient mode multi;
```

- `single`: one fault is active according to registration order.
- `multi`: multiple faults may be active together.
- If mode is needed, set it before adding faults.

Add:

```text
fitclient add -u UID -a ACTION;
fitclient add -u UID -a jump -c 1;
fitclient add -u UID -a hit -c 1;
fitclient add -u UID -a jump -s db1;
fitclient add -u UID -a jump -r;
fitclient add -u UID -a jump -r 10;
fitclient add -f faultFileName;
```

Options:

- `-u`: FIT UID. Required except with `-f`.
- `-a`: action. Required except with `-f`.
- `-c`: `HIT_TOTAL`; the Nth hit activates the action. Default is 1.
- `-s`: SID. Default is `DEFAULT`.
- `-r`: repeat. No value means infinite repeat; a value gives repeat count.
- `-f`: load a fault file. When `-f` is used, other options are ignored.

Common actions:

- `hit`: reachability check. Usually pair with `##success`.
- `jump`: failure path check. Usually pair with `##fail`.
- `kill`: process termination scenario. Use only with explicit recovery
  expectations.
- `sigsegv`: crash/FATAL style scenario. Use only with explicit crash outcome
  expectations.
- `sleep`, `wakeup`: scheduling or coordination scenarios. Use only when the
  expected timing behavior is deterministic.

Update/delete:

```text
fitclient update -u UID -a jump -c 100 -s db1 -r 10 -i 1;
fitclient update -r 0 -i 1;
fitclient delete -u UID;
fitclient delete -i 1:10;
```

- Use sparingly. Prefer adding the correct rule from the start.

List:

```text
fitclient lst;
fitclient list;
```

Check fields such as:

- `HIT_COUNT`: actual hit count.
- `HIT_TOTAL`: hit count needed to activate.
- `ACTION`: selected action.
- `ACTIVATION`: whether the fault activated.
- `REPEAT_COUNT`, `REPEAT_TOTAL`: repeat state.

Fault files:

```text
fitclient add -f faultFileName;
```

- A fault file may contain `add`, `update`, `delete`, `reset`, or similar
  fitclient-style commands.
- The `fitclient` prefix may be present or omitted inside the fault file when
  the target tool supports that style.
- Use only when the file is included in the artifact tree or target environment.
- Prefer direct `fitclient add ...;` in the `.tc` for simple generated cases.

## SQL Outcome Markers

`##fail` and `##success` apply to the next SQL statement only.

Failure expectation:

```text
fitclient add -u ClassOrFile::function::targetStatement::Alias -a jump -c 1;

##fail
INSERT INTO T1 VALUES ( 1 );
```

Success expectation:

```text
fitclient add -u ClassOrFile::function::targetStatement::Alias -a hit -c 1;

##success
SELECT COUNT(*) FROM T1;
```

Rules:

- Put the marker immediately before the SQL statement it applies to.
- Runtime commands such as `fitclient lst;` do not consume the marker.
- Use `##fail` when the SQL must fail for the test to pass.
- Use `##success` only when explicit success expectation is useful.
- Keep one FIT action tied to one main SQL outcome whenever possible.
- `##fail` passes only when the next SQL fails.
- `##success` passes only when the next SQL succeeds.

## UID Rules

UIDs should be existing, meaningful, and specific.

Recommended format:

```text
ClassOrFile::function::targetStatement::Alias
```

Project-specific UID format may prefix the UID:

```text
PROJECT-ID@ClassOrFile::function::targetStatement::Alias
```

Rules:

- Do not invent a UID if the target UID is unknown.
- Do not use line numbers as UID identity.
- Do not use vague aliases such as `test1`, `point`, or `temp`.
- If no existing UID reaches the target path, report the missing FIT point
  requirement instead of guessing.

## Product FIT Point Edits

Do not edit product source unless the user explicitly asks for source changes.
If source changes are requested, apply these design rules:

- Search for an existing nearby FIT point before adding a new one.
- Reuse an existing UID when it reaches the intended path and state.
- Use `IDU_FIT_POINT` for a generic failure tail where no specific exception
  label is needed.
- Use `IDU_FIT_POINT_RAISE` when the target must jump to a specific
  `IDE_EXCEPTION(label)` block.
- Place the FIT point immediately before the target statement.
- For cleanup coverage, place it after required resource/state setup.
- Add or design a matching FIT TC for every new point.
- Follow nearby UID naming style.
- If code comments near FIT points record expected TC paths, preserve that style.

## Result Oracle

Tagged `.lst` files are the expected visible output for `.tc` files.

Rules:

- Create or update the tagged `.lst`, normally
  `fitFailureCase_A4_64.lst` for `fitFailureCase.tc`.
- Generate `.lst` from a real target-tool run when possible.
- Stabilize normal SQL output with `ORDER BY` when row order matters.
- Include intentional `fitclient` output only when it is part of verification.
- Do not guess complex crash, fatal, or nondeterministic output.
- Hide setup/cleanup noise when it is not the verification target.
- Review copied `.out` or runner output before accepting it as `.lst`.

## Completion Report

When finishing a FIT request, report:

- Generated or modified `.tc`, `.lst`, and `.ts` files.
- Each UID used by each TC.
- Each `fitclient` action and important options such as `-c`, `-s`, and `-r`.
- Whether the test is reachability, failure-path, cleanup, crash/FATAL, or
  other FIT coverage.
- Whether `fitclient lst;` verifies `HIT_COUNT`, `HIT_TOTAL`, or `ACTIVATION`.
- Any product FIT point that appears necessary but was not added.
- Any new product FIT point that was added but still lacks a TC.
- Validation or runner result from the target tool, or the blocker that
  prevented validation.

## Hard Stops

Stop and report the blocker instead of guessing when:

- The request did not explicitly ask for FIT or fault injection.
- The target UID is unknown or cannot be confirmed.
- The expected `.lst` cannot be derived from deterministic output.
- The test requires restart, recovery, DA/HDB process scope, `fitmon`, or
  product environment behavior that is not fully specified.
- Product source changes appear necessary but were not explicitly requested.

## Do Not Generate

- FIT TC for a normal SQL regression request.
- Product source FIT point edits without explicit source-change approval.
- Guessed UID names.
- Action files written directly instead of `fitclient`.
- TC that leaves FIT state enabled or fault rules registered after completion.
- Shell or Python wrappers that replace visible TC FIT flow.
- Old-style `--+` directives.
- AI metadata comments, prompt notes, or local-only implementation notes inside
  import artifacts.

## Validation

Use the target tool's validator or runner, not repository-local commands from
this brief. Before finishing, verify at least:

- Every `.tc` parses.
- Every `.tc` has the required tagged `.lst`, normally `_A4_64.lst`.
- Every `.ts` references existing `.tc` files by valid relative paths.
- Required sectors exist in the correct order.
- FIT state is reset in finalization.
- The visible output matches `.lst`.
- No old-style directives, local-only paths, AI metadata, absolute local paths,
  or hidden shell wrapper dependencies are present.
- Output is deterministic or intentionally hidden/normalized.

## Prompt Template

```text
You are an AI coding agent creating FIT-specific TC artifacts.

Use only the syntax and rules in this brief. Do not assume access to additional
documents or repository-local tools. Create .tc and tagged .lst files, and
create .ts suite files when a suite is needed.

Use tagged oracle names. For fitFailureCase.tc, create
fitFailureCase_A4_64.lst unless the target tool explicitly requires another
oracle tag.

This is a FIT/fault injection request. Use real fitclient commands in the .tc
file. Do not add or edit product FIT points unless explicitly requested. If the
requested UID does not exist or cannot reach the target path, stop and report
that gap.

Validate with the target tool's parser/runner before finishing and report any
blocker instead of inventing unsupported syntax.
```
