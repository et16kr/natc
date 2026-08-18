# TEMP tablespace code review resolution

- Date: 2026-08-18
- Product tree: `/home/et16/work/altidev4_gi`
- Branch: `workspace/simple_temp_tablespace`
- Findings: `CODE_REVIEW_FINDINGS_20260817.md`
- Design reference: `docs/temp-tablespace-memory-extent-design.md`

## Result

The eight findings from the static review were addressed in focused product or
delivery commits. The implementation now follows the intended TEMP tablespace
ownership model: the standard node remains the durable definition owner, TEMP
allocation state remains boot-local, file-set publication is old-or-new, and
ADD/DROP preserves unaffected live runtime state.

## Finding-to-commit map

| ID | Resolution | Commit |
|---|---|---|
| F-01 | Added runtime bundle leases and delayed retirement until all readers release their leases. | `af50c48e` |
| F-02 | Published the definition, runtime file set, identity generation, and gate state through one lifecycle transaction. | `80a9d324` |
| F-03 | Preserved retained-file extent/body/autoextend state across ADD/DROP instead of requiring the whole space to be empty. | `15059300` |
| F-04 | Recomputed the standard TEMP total from live runtime file sizes after file DDL. | `51c9238e` |
| F-05 | Added prepared snapshot exchange and reversible runtime generation updates so failed publication preserves the before-image. | `3b2c0af4`, `27b66b8c` |
| F-06 | Removed the `file resize -> global registry` lock nesting from AUTOEXTEND while retaining the standard-node I/O pin. | `a0e0ad84` |
| F-07 | Required the standard node, immutable definition, and runtime owner all to match before accepting a same-value no-op. | `41d5f4b3` |
| F-08 | Added the Makefile-required `unittestSdpteDiskHooks.cpp` to the tracked checkpoint change set. | `0361f97c` |

The initial reviewed change set was committed as `0361f97c`. Each subsequent
finding was committed independently to keep the correction history auditable.

## Design-alignment result

| Principle | Result after correction |
|---|---|
| Durable definition is owned by existing WAL/anchor and standard nodes | Aligned |
| Runtime extent/page allocation state is boot-local and non-durable | Aligned |
| ADD keeps the old allocator available and preserves live retained-file state | Aligned |
| DROP gates only the target file and preserves retained-file state | Aligned |
| Readers observe an old or new definition/runtime projection, not a mixed image | Aligned |
| Retired runtime objects remain alive while a reader lease exists | Aligned |
| OPEN standard total is restored to `sum(runtime current)` after file DDL | Aligned |
| AUTOEXTEND does not acquire the global registry while holding the file resize mutex | Aligned |
| AUTOEXTEND no-op requires all three owners to match | Aligned |

## Focused verification

The focused binaries used while resolving the findings passed, including:

- `unittestSdpteDefinition`, `unittestSdpteModule`
- `unittestSdpteAddTempFile`, `unittestSdpteAlterSize`
- `unittestSdpteAlterAutoExtend`, `unittestSdpteAttributeLane`
- `unittestSdpteAutoExtend`, `unittestSdpteWiring`
- `unittestSdpteComponentDDL`

The final aggregate rerun produced complete passes for 10 targets:

- `sdpte_definition_projection`
- `sdpte_standard_node_io`
- `sdpte_format_binding_identity`
- `sdpte_definition_resize_config`
- `sdpte_recovery_control`
- `sdpte_projection_durability`
- `sdpte_change_surface`
- `sdpte_startup_reconcile`
- `sdpte_restart_crash`
- `sdpte_no_durability`

`sdpte_allocator_runtime`, `sdpte_concurrency_error`, and `sdpte_sql_view`
initially reached the same focused failure in
`unittestSdpteDropTempFile.cpp:850-857`. 후속 pre-commit 검증에서 이 항목은 제품
DROP contract가 아니라 synthetic publication fixture의 모델 오류로 확인됐다.
fixture가 실제 제품과 달리 drain을 보유한 retired allocator의 definition
generation을 APPLY 시점에 즉시 바꾸어, 이어지는 drain release가 자기 토큰을
invalid로 판정했다. 해당 in-place generation 변경만 제거해 실제
`sdpteService`의 old-runtime 보존 동작과 맞췄으며, 제품 DROP body는 변경하지
않았다. 이후 `unittestSdpteDropTempFile`, `sdpte_component_ddl`,
`sdpte_standard_node_io`, `sdpte_allocator_runtime`, `sdpte_concurrency_error`,
`sdpte_sql_view`가 모두 통과했다.

One initial `unittestSdpteExtent` run also saw the gate-versus-allocator worker
make no scheduling progress. Three direct reruns and the subsequent aggregate
rerun passed; no repeatable product failure was observed.

## Worktree hygiene

Unrelated existing changes in the product and NATC worktrees were preserved and
were not included in the TEMP review-fix commits.
