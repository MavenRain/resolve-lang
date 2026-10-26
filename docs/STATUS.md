# resolve-lang status

The build implements all the slices of docs/PLAN.md section 9 (S0 to S8):
the port of intent-lang, the `market` form, `Contest`, the ledger and the
masked ring, the encrypted dispute ballots, and the resolution contract on
an EVM chain. The plan is CLOSED (S8 s3, 2026-10-26). SPEC.md gives the
language, and docs/VALIDATION.md gives the gate results.

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
- S5 (the ledger, the freeze, the masked ring, O10; Q-S5-1 to Q-S5-3
  RULED (a)): `examples/ledger.lang` keeps the stakes of all markets in
  one `Map`, keyed by `hash m (addrToU256 a)`. The deadline of each market
  comes from its `market` form, and a `take` at the deadline or after it
  reverts (L7). `examples/ring.lang` puts a NUMS point in the slot of a
  member with a stake (L8). Each dispute has a key image: the slot is
  `K_i + t_d G`, with `t_d = hash(tag, d) mod r` and the
  deployment-scoped id `d = hash(domain, m)` (PLAN 4.3). Two run scripts
  and 11 ring eval rows test it. S7 lowers the ring and enforces the
  deployment domain.
- S6 (the encrypted dispute ballots, PLAN 4.4; Q-S6-1 to Q-S6-5 RULED
  (a)): the ballots of intent-lang S9 are ported for the verdict (O12). A
  ballot is a one-hot `Enc` over `Verdict`, and the poll id is the dispute
  id (O14). `tallyEnc` adds the ballots. L9 is a law-only def
  (`examples/tally.lang`), and a use of `decrypt` outside a law type gives
  `REFUSE_LAW` (L10, `test/check/tally-leak.lang`). The threshold open uses
  the quorum {1, 2}. The challenge outcome needs a majority, and a tie
  fails. `Params` (the dispute window and the vote window) is in the DAO.
- S7 (the contract, PLAN 4.7; Q-S7-1 to Q-S7-10 RULED): the contract of
  `examples/resolvekit.lang` (SPEC.md section 13) with the entries `take`,
  `propose`, `challenge`, `castSig`, `castSlot`, `castSeal`, `openTally`,
  `finalize` and `claim`, and the views `pollOpen`, `pollShut`, `stakeOf`,
  `fieldOf`, `pollWord` and `windows`. The
  contract lowers `Env.block` to NUMBER (b1), and `Env.chain` and
  `Env.self` to CHAINID and ADDRESS (b3; a run script gives them with an
  `env CHAIN SELF` line). `u256Mul` and `u256Div` are MUL and DIV (b4;
  `x / 0 = 0`). `test/resolvekit.sh` runs the contract on an EVM chain
  (62 chain steps) and prints the size rows (runtime 24441 bytes, initcode
  24471 bytes) and the gas of each entry.
- S8 (the mutants and the docs, PLAN 4.8; Q-S8-1 to Q-S8-7 RULED (a)): the
  mutants M1 to M8, one for each law row of `examples/resolvekit.lang`,
  are all KILLED. s2 added the kill rows of M8 (the domain:
  `test/run/resolvekit.chain.script`, `test/run/resolvekit.self.script`
  and two chain takes) and of M7 (the a1 row:
  `test/run/resolvekit.a1.script` and one chain cast): 13 runs and 65
  chain steps. s3 wrote SPEC.md sections 1 and 9 to 16, the resolution
  section of docs/VALIDATION.md and this file.

## Remaining M0 work

None: the plan of docs/PLAN.md is CLOSED (S8).

## Known limits

- O6: one dispute round. `Contest A` is a proposition (Q4 (a)), thus a
  dispute of a verdict (an escalation) is not in v1.
- The `Params` proposal: the proposed values are `init` constants of the
  program, and no entry proposes other values (Q-S7-5 (a), Q-S8-7 (a)).
- The size: the runtime of `examples/resolvekit.lang` is 24441 bytes, thus
  135 bytes of room are left under EIP-170 (24576 bytes).
- O13: `ecrecover` comes with the port and has no use.
- The non-goal of PLAN 4.3: a stake through another wallet, another venue
  or an off-chain hedge is outside the proof of L8.

## Internal boundaries

> Write here: one paragraph for each module group. Say which module holds
> which job, which tests check which tables, and which types a program
> cannot use.
