# Repository Guidelines

## Project Structure & Module Organization

This repository is a legacy NATC/ATAF test automation tree. Core native and Java sources live under `src/`: `ats2/` contains the STAF service, `atsclnt/` the client, `target_agent/` target/host helpers, `java/` shared Java support, `viewer/` the TDX viewer, and `ses/` SES integration. Public headers are in `include/`. Perl runtime modules are in `lib/`, command wrappers and utilities in `bin/`, environment scripts in `scripts/`, and runtime configuration in `conf/`. Test cases and expected outputs live in `TC/`; generated logs belong under `work/` and should not be treated as source.

## Build, Test, and Development Commands

Builds are environment-dependent. Set the needed variables first, typically `OS_NAME=linux`, `STAF_HOME`, `ALTIBASE_HOME`, `ATC_HOME`, and `ATAF_TEST_CASE`.

- `make -C src install`: builds the aggregate Java/SES targets listed by `src/Makefile`.
- `make -C src/ats2 install OS_NAME=linux`: builds the STAF ATS service library.
- `make -C src/atsclnt install OS_NAME=linux`: builds the `atsc` client.
- `make -C src/viewer install`: compiles `TDX_View.jar` and copies it to `$ATC_HOME/bin`.
- `make -C src clean`: removes aggregate build outputs.
- `bin/atc <path-to-case-or-suite>` or `bin/atc2 <path>`: run test cases through the installed ATC environment.

## Coding Style & Naming Conventions

Preserve the existing style in each area. C/C++ code uses K&R-like braces with aligned parameters and project typedefs such as `UInt`; avoid broad reformatting. Java code in this tree uses tabs and PascalCase method names in older files; match nearby code. Perl modules use `strict`, package-scoped exports, and snake_case helpers. Keep files UTF-8. Use existing prefixes and IDs in test paths, such as `BUG-46124`, `PROJ-2619`, and `TASK-5712`.

## Testing Guidelines

ATAF tests are organized under `TC/` as `.tc`, `.sql`, `.ts`, and expected `.lst` files. Keep expected outputs beside the case and use the established platform suffix, for example `initialize_A4_64.lst`. Add shared helpers under `TC/include/` only when multiple cases need them. Run the smallest relevant case or suite with `bin/atc`/`bin/atc2`, then check `work/log/` for failures.

## Agent-Specific References

For AI-assisted test work, review [TC_GUIDE.md](docs/TC_GUIDE.md) for general TC generation, [FIT_GUIDE.md](docs/FIT_GUIDE.md) for FIT-oriented work, and [DEBUGGING_GUIDE.md](docs/DEBUGGING_GUIDE.md) for debugging FAIL/ERROR test cases.

## Commit & Pull Request Guidelines

The visible history is sparse (`Initial commit`, `euckr to utf8`), so use short, imperative commit subjects under about 72 characters, for example `Add shard regression case`. Pull requests should describe the changed component, list required environment variables, include exact build/test commands run, and link the related BUG/PROJ/TASK when applicable. Include screenshots only for viewer UI changes.
