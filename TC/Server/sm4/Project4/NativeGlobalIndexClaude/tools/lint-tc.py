#!/usr/bin/env python3
"""서버 없이 도는 NativeGlobalIndexClaude 스위트 검사기.

ATAF 는 케이스를 실행해 봐야 오류를 알려주고, 실행하려면 서버가 필요하다.
이 검사기는 서버 없이 잡을 수 있는 것만 잡는다.

  구조   INCLUDE 해석, DEF/CALL 이름과 인자 수, 중괄호 짝,
         SKIP BEGIN/END 와 NODISPLAY ON/OFF 짝, DEF MAIN 존재
  참조   .ts 가 가리키는 .tc 실존, 어느 .ts 도 안 가리키는 .tc
  문법   altidev4 의 qcply.y 에 대조해 확인한 "확실히 틀린" SQL 형태만.
         SQL 전체를 파싱하지는 않는다 — 파서가 서버 바이너리 안에 있다.
  oracle .lst 유무 보고 (없으면 ATAF 는 무조건 FAIL 로 친다)

사용법:
    python3 tools/lint-tc.py            # 스위트 루트에서
    python3 tools/lint-tc.py --quiet    # 오류만
종료 코드: 오류가 하나라도 있으면 1
"""

import os
import re
import sys

# ---------------------------------------------------------------------------
# 확실히 틀린 SQL 형태. 각 항목은 altidev4 소스에 근거가 있어야 한다.
# (패턴, 설명, 근거)
# ---------------------------------------------------------------------------
BAD_SQL = [
    (re.compile(r'\bexchange\s+partition\b', re.I),
     "EXCHANGE PARTITION 은 Altibase 에 없다. "
     "ALTER TABLE <target> REPLACE <source> PARTITION <name> 을 쓴다",
     "qcply.y 에 EXCHANGE 토큰 자체가 없음"),

    (re.compile(r'\bdireckey\b', re.I),
     "direckey 오타. 키워드는 DIRECTKEY 다",
     "qcply.y:14941 strMatch(\"DIRECTKEY\", 9, ...)"),

    (re.compile(r'\bcreate\s+volatile\s+table\b', re.I),
     "CREATE VOLATILE TABLE 은 없다. CREATE VOLATILE TABLESPACE 로 "
     "테이블스페이스를 만들고 TABLESPACE 절로 테이블을 그 안에 둔다",
     "qcply.y:41958 은 TR_CREATE TR_VOLATILE TA_TABLESPACE 뿐"),

    (re.compile(r'\brebuild\s+tablespace\b', re.I),
     "ALTER INDEX ... REBUILD TABLESPACE 는 없다. "
     "REBUILD 또는 REBUILD PARTITION <name> [TABLESPACE ...] 뿐이다",
     "qcply.y:15061, 15075"),

    (re.compile(r'^\s*AUTOCOMMIT\s+(ON|OFF)\s*;', re.I | re.M),
     "AUTOCOMMIT ON/OFF 는 isql 스크립트(.sql) 문법이다. "
     ".tc 에서는 ALTER SESSION SET AUTOCOMMIT = TRUE/FALSE 를 쓴다",
     "PROJ-1624 keyrange.tc:8 및 그 .lst"),

    (re.compile(r'\bwith\s+table\s+\w+\s*;', re.I),
     "EXCHANGE ... WITH TABLE 잔재로 보인다",
     "qcply.y 에 해당 생성 규칙 없음"),

    (re.compile(r'/\*(?!\+)', re.M),
     "문장 수준의 C 스타일 주석. .tc 의 주석은 '#' 이고, '/*' 는 파서를 "
     "깨뜨린다(PARSE ERROR: Tokens is '/'). SQL 힌트 '/*+ ... */' 만 예외다",
     "ATAF .tc 문법. 실측: tableLock.tc 가 이것 때문에 ERROR 였다"),
]

# SPLIT PARTITION 은 AT (...) 또는 VALUES (...) 가 반드시 있어야 한다.
SPLIT_RE = re.compile(
    r'\bsplit\s+partition\s+\w+\s+(?!at\b|values\b)', re.I)

# table_options 순서: table_partitioning_option -> row_movement_option
#                     -> table_maxrows_option -> opt_record_access
#                     -> tablespace_name_option
# 즉 'tablespace X' 다음 줄에 'enable/disable row movement' 가 오면 틀렸다.
TBS_THEN_MOVEMENT = re.compile(
    r'^\s*tablespace\s+\w+\s*$\n^\s*(enable|disable)\s+row\s+movement\s*;',
    re.I | re.M)

DEF_RE = re.compile(r'^DEF\s+([A-Za-z_][A-Za-z0-9_]*)\s*\(([^)]*)\)', re.M)
CALL_RE = re.compile(r'\bCALL\s+([A-Za-z_][A-Za-z0-9_]*)\s*\(', re.M)
INCLUDE_RE = re.compile(r'^INCLUDE\s+(\S+?)\s*;', re.M)

ORACLE_TAG = "A4_64"


class Report:
    def __init__(self):
        self.errors = []
        self.warns = []
        self.notes = []

    def error(self, path, line, msg, why=None):
        self.errors.append((path, line, msg, why))

    def warn(self, path, line, msg, why=None):
        self.warns.append((path, line, msg, why))

    def note(self, msg):
        self.notes.append(msg)


def line_of(text, pos):
    return text.count("\n", 0, pos) + 1


def split_args(argstr):
    argstr = argstr.strip()
    if not argstr:
        return []
    return [a.strip() for a in argstr.split(",")]


def call_arity(text, start):
    """CALL NAME( 의 여는 괄호 다음부터 짝이 맞는 닫는 괄호까지의 인자 수."""
    depth = 0
    i = start
    in_str = None
    args = 1
    saw_any = False
    while i < len(text):
        c = text[i]
        if in_str:
            saw_any = True
            if c == in_str:
                in_str = None
        elif c in "\"'":
            in_str = c
            saw_any = True
        elif c == "(":
            depth += 1
            saw_any = True
        elif c == ")":
            if depth == 0:
                return (args if saw_any else 0), i
            depth -= 1
        elif c == "," and depth == 0:
            args += 1
            saw_any = True
        elif not c.isspace():
            saw_any = True
        i += 1
    return None, i


def collect_defs(text, path, rep):
    """이 파일이 정의하는 DEF 이름 -> 인자 수."""
    defs = {}
    for m in DEF_RE.finditer(text):
        name = m.group(1)
        params = split_args(m.group(2))
        if name in defs:
            rep.error(path, line_of(text, m.start()),
                      "DEF %s 가 중복 정의됐다" % name)
        defs[name] = len(params)
    return defs


def check_structure(path, text, rep):
    # DEF MAIN
    if path.endswith(".tc") and "DEF MAIN(" not in text.replace(" ", ""):
        if not re.search(r'^DEF\s+MAIN\s*\(', text, re.M):
            rep.error(path, 0, ".tc 에 DEF MAIN() 이 없다")

    if path.endswith(".i") and re.search(r'^DEF\s+MAIN\s*\(', text, re.M):
        rep.error(path, 0, ".i 는 MAIN 을 정의하면 안 된다")

    # 중괄호 짝 (문자열/주석 밖에서만)
    depth = 0
    for n, raw in enumerate(text.splitlines(), 1):
        line = raw.split("#", 1)[0]
        line = re.sub(r'"[^"]*"', "", line)
        line = re.sub(r"'[^']*'", "", line)
        for c in line:
            if c == "{":
                depth += 1
            elif c == "}":
                depth -= 1
                if depth < 0:
                    rep.error(path, n, "짝 없는 '}'")
                    depth = 0
    if depth != 0:
        rep.error(path, 0, "중괄호가 %d 개 안 닫혔다" % depth)

    # SKIP BEGIN / END
    begins = len(re.findall(r'^\s*SKIP\s+BEGIN\s*;', text, re.M))
    ends = len(re.findall(r'^\s*SKIP\s+END\s*;', text, re.M))
    if begins != ends:
        rep.error(path, 0, "SKIP BEGIN %d 개 vs SKIP END %d 개" % (begins, ends))

    # NODISPLAY ON / OFF
    ons = len(re.findall(r'^\s*NODISPLAY\s+ON\s*;', text, re.M))
    offs = len(re.findall(r'^\s*NODISPLAY\s+OFF\s*;', text, re.M))
    if ons != offs:
        rep.error(path, 0, "NODISPLAY ON %d 개 vs OFF %d 개" % (ons, offs))

    # explain plan on / off
    pon = len(re.findall(r'explain\s+plan\s*=\s*on', text, re.I))
    poff = len(re.findall(r'explain\s+plan\s*=\s*off', text, re.I))
    if pon != poff:
        rep.warn(path, 0,
                 "explain plan = on %d 회 vs off %d 회. 켠 채로 두면 "
                 "뒤따르는 모든 출력에 플랜이 섞인다" % (pon, poff))


def strip_comments(text):
    """'#' 주석을 지운다. 줄 수는 보존해야 줄 번호가 맞는다.

    '#' 은 .tc 의 줄 주석이다. SQL 안에 '#' 이 들어갈 일은 이 스위트에
    없으므로 단순 처리로 충분하다.
    """
    out = []
    for raw in text.split("\n"):
        i = raw.find("#")
        out.append(raw if i < 0 else raw[:i])
    return "\n".join(out)


def check_sql(path, text, rep):
    code = strip_comments(text)

    for pat, msg, why in BAD_SQL:
        for m in pat.finditer(code):
            rep.error(path, line_of(code, m.start()), msg, why)

    for m in SPLIT_RE.finditer(code):
        rep.error(path, line_of(code, m.start()),
                  "SPLIT PARTITION 에 AT ( ... ) 또는 VALUES ( ... ) 절이 없다",
                  "qcply.y:13894(AT), 13979(VALUES) — 둘 다 필수")

    for m in TBS_THEN_MOVEMENT.finditer(code):
        rep.error(path, line_of(code, m.start()),
                  "'tablespace X' 가 'enable/disable row movement' 보다 앞에 있다. "
                  "순서를 바꿔야 한다",
                  "qcply.y:17148 table_options 는 row_movement_option 이 "
                  "tablespace_name_option 보다 먼저다")


def resolve_includes(path, text, rep, cache):
    """이 파일이 INCLUDE 하는 .i 들의 경로 목록. 못 찾으면 에러."""
    out = []
    base = os.path.dirname(path)
    for m in INCLUDE_RE.finditer(text):
        target = m.group(1)
        cand = os.path.normpath(os.path.join(base, target))
        if os.path.isfile(cand):
            out.append(cand)
        else:
            rep.error(path, line_of(text, m.start()),
                      "INCLUDE 대상을 찾을 수 없다: %s "
                      "(ATAF 는 .tc 기준 상대 경로로 찾는다)" % target,
                      "찾아본 곳: %s" % cand)
    return out


def check_calls(path, text, rep, defs_by_file, cache):
    """CALL 이름과 인자 수가 어딘가의 DEF 와 맞는지."""
    visible = {}
    for inc in resolve_includes(path, text, rep, cache):
        visible.update(defs_by_file.get(inc, {}))
    visible.update(defs_by_file.get(path, {}))

    for m in CALL_RE.finditer(text):
        name = m.group(1)
        n, _ = call_arity(text, m.end())
        ln = line_of(text, m.start())
        if name not in visible:
            rep.error(path, ln,
                      "CALL %s — 어느 DEF 에도 없다 "
                      "(이 파일과 INCLUDE 한 .i 를 다 봤다)" % name)
        elif n is not None and visible[name] != n:
            rep.error(path, ln,
                      "CALL %s 인자 %d 개, DEF 는 %d 개"
                      % (name, n, visible[name]))


def check_suites(root, rep):
    """.ts 가 가리키는 대상 실존, 그리고 어느 .ts 도 안 가리키는 .tc."""
    referenced = set()
    for dirpath, _, files in os.walk(root):
        for f in files:
            if not f.endswith(".ts"):
                continue
            ts = os.path.join(dirpath, f)
            with open(ts, encoding="utf-8", errors="replace") as fh:
                for n, raw in enumerate(fh, 1):
                    line = raw.split("#", 1)[0].strip()
                    if not line or line.startswith("-") or "=" in line:
                        continue
                    target = os.path.normpath(os.path.join(dirpath, line))
                    if not os.path.isfile(target):
                        rep.error(ts, n, "참조 대상이 없다: %s" % line)
                    else:
                        referenced.add(target)

    for dirpath, _, files in os.walk(root):
        if os.sep + "tools" in dirpath:
            continue
        for f in files:
            if f.endswith(".tc"):
                p = os.path.normpath(os.path.join(dirpath, f))
                if p not in referenced:
                    rep.warn(p, 0,
                             "어느 .ts 도 이 케이스를 가리키지 않는다 "
                             "(의도한 것이면 README 에 이유를 남길 것)")


def check_oracles(root, rep):
    missing = []
    for dirpath, _, files in os.walk(root):
        for f in files:
            if not f.endswith(".tc"):
                continue
            stem = f[:-3]
            lst = os.path.join(dirpath, "%s_%s.lst" % (stem, ORACLE_TAG))
            if not os.path.isfile(lst):
                missing.append(os.path.join(dirpath, f))
    if missing:
        rep.note(
            "기대 결과(.lst) 없음: %d / %d 케이스.\n"
            "  ATAF 는 .out 을 <case>_%s.lst 와 대조하고, .lst 가 없으면\n"
            "  정상 실행돼도 FAIL 로 친다. 즉 지금은 회귀 게이트가 아니라\n"
            "  .out 육안 검토용이다."
            % (len(missing), len(missing), ORACLE_TAG))


def main():
    quiet = "--quiet" in sys.argv
    root = "."
    if not os.path.isfile(os.path.join(root, "README")):
        # 스위트 루트가 아니면 스크립트 위치의 부모를 쓴다
        root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

    rep = Report()
    cache = {}
    texts = {}
    defs_by_file = {}

    for dirpath, _, files in os.walk(root):
        if os.sep + "tools" in dirpath:
            continue
        for f in sorted(files):
            if not (f.endswith(".tc") or f.endswith(".i")):
                continue
            p = os.path.normpath(os.path.join(dirpath, f))
            with open(p, encoding="utf-8", errors="replace") as fh:
                t = fh.read()
            texts[p] = t
            defs_by_file[p] = collect_defs(t, p, rep)

    for p, t in sorted(texts.items()):
        check_structure(p, t, rep)
        check_sql(p, t, rep)

    for p, t in sorted(texts.items()):
        if p.endswith(".tc"):
            check_calls(p, t, rep, defs_by_file, cache)

    check_suites(root, rep)
    check_oracles(root, rep)

    rel = lambda p: os.path.relpath(p, root)

    if rep.errors:
        print("== 오류 %d ==" % len(rep.errors))
        for path, ln, msg, why in rep.errors:
            where = "%s:%d" % (rel(path), ln) if ln else rel(path)
            print("  %s\n      %s" % (where, msg))
            if why:
                print("      근거: %s" % why)

    if rep.warns and not quiet:
        print("\n== 경고 %d ==" % len(rep.warns))
        for path, ln, msg, why in rep.warns:
            where = "%s:%d" % (rel(path), ln) if ln else rel(path)
            print("  %s\n      %s" % (where, msg))

    if rep.notes and not quiet:
        print("\n== 참고 ==")
        for m in rep.notes:
            print("  %s" % m)

    if not quiet:
        print("\n검사: .tc/.i %d 개, 오류 %d, 경고 %d"
              % (len(texts), len(rep.errors), len(rep.warns)))

    return 1 if rep.errors else 0


if __name__ == "__main__":
    sys.exit(main())
