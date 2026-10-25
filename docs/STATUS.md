# resolve-lang status

> Write here: one paragraph. Say which milestone the build implements, and
> which milestone it does not complete yet.

## Implemented

> Write here: one item for each feature that works. Name the former (F1 to
> F15), the core type or the core operation.

- S2 (kernel port): `src/`, `domain/`, `examples/`, `test/`, `gen/` and
  the Makefile of intent-lang ef5abe8 (by `git archive`), and the
  intent-lang text of SPEC.md, docs/host/README.md, docs/VALIDATION.md,
  formers/FORMERS.md, formers/tcc-evm-contract.md and probe/CAPABILITY.md.
  The code is the ef5abe8 code byte for byte. `examples/inventory.lang` and
  `test/check/domain-name.lang` of the seed are removed (ef5abe8 does not
  have them; intent-lang S2 removed them for the same cause). The gate
  gives the intent-lang S7 counts (docs/PLAN.md section 9). Name changes in
  the intent-lang text: SPEC.md line 1 (the title), line 3 (the working
  name) and line 14 (the purpose) say resolve-lang; docs/host/README.md
  line 3 adds "resolve-lang S2 ports it from intent-lang ef5abe8". These
  stay: the provenance comments `(orbit-lang Sn ...)` and `(intent-lang Sn
  ...)`, the evidence paths `~/Documents/intent-lang-work/...` in
  docs/VALIDATION.md, test/secptool.c and test/precompile.sh, the DAO words
  (`Orbit`, `orbitProj`), the bLSAG domain tag "orbit" and
  docs/VALIDATION.md, which records the gates of orbit-lang and
  intent-lang. The port carries the features of intent-lang S3 to S7
  (`REFUSE_CELL`, `cofamily`, sealed `Enc`, `Quorum` and `open`, `ZKProof`,
  the Sigma verifiers, `ecrecover`); the intent-lang docs/STATUS.md at
  ef5abe8 describes each one.
- S3 s1 (`Env.block`, O5): the guest `Env` has `block : U256`, and a
  `langc run` call is `NOW BLOCK CALLER NAME ARGS...`. This is intent-lang
  S8 b1: S3 replays its two replacer scripts (11 and 78 hits) and copies
  `examples/blocks.lang`, `test/run/blocks.script`, `test/run/blocks.out`,
  `test/lower/env-block.lang`, the run-2 fix of `test/evmchain.sh` and the
  b1 hunks of `docs/host/README.md`. The contract writer does not lower
  `block` yet (`REFUSE_LOWER`; NUMBER is S7). S3 s2 builds the `market` form.
- S3 s2 (the `market` form, O4; Q-S3-1 to Q-S3-5 RULED (a)): a kit program
  can declare `market M := sources ... outcomes L1 | ... | Lk deadline T
  rule T answers T`. The lexer reads `market` as a keyword and `M.x` as one
  name in a program. The parser needs the clauses in that order, one or
  more sources and two or more outcomes (else `PARSE_EXPECT`). The checker
  writes the form as the text of PLAN 4.6 (`M.Reading`, one selector for
  each source, `M.Outcome`, the labels, `M.deadline`, `M.rule`,
  `M.answers`) and checks each `def` as a program `def`. A guest market
  gives `REFUSE_KIT`, a domain market `REFUSE_DATA`, a program `def` with a
  `.` `REFUSE_NAME`, a missing branch `TYPE_MISMATCH` and a branch with the
  wrong reading `PATH_END`. `examples/market.lang` has a binary market and a
  market with three outcomes.
- S4 (`Contest`, PLAN 4.1, Q4 (a)): the domain declares the cell monad
  `Contest A` with the generator `prop` and the 1-cell
  `dispute dA dB dGround i` from `dA` to `dB`. A program defines
  `Verdict = Sum Unit Unit` (`left` is `i0`, `right` is `i1`), `swap` and
  `verdictAt A x y d v` (the path at the verdict endpoint). L3, L4 and L6
  hold by `refl` (`examples/contest-ends.lang`,
  `examples/contest-neutral.lang`). A wrong end gives `PATH_END`, and a
  dispute end of the type parameter gives `REFUSE_CELL` (fronttool).

## Remaining M0 work

> Write here: one numbered item for each missing feature. Say what each item
> needs first.

1. <work item>.

## Known limits

> Write here: one item for each limit of the current build, with its cause
> (a fuel budget, a host limit, a stack size).

- <limit>.

## Internal boundaries

> Write here: one paragraph for each module group. Say which module holds
> which job, which tests check which tables, and which types a program
> cannot use.
