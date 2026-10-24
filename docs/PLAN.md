# resolve-lang plan

resolve-lang is a Cubical TT language for prediction-market resolution. A
program declares market questions, the resolution protocol and the DAO that
governs them. The compiler checks the laws and writes the EVM bytecode of
the contract. `design/DESIGN.md` holds the request and the design verbatim.

In this file, "intent-lang" means MavenRain/intent-lang at ef5abe8 (tree
da87a361, S7 closed). "P" is its `docs/PLAN.md`, "D" is its
`domain/domain.lang` and "H" is its `docs/host/README.md`.

## 1. Rulings

USER rulings (the request, 2026-10-24):

- R1 type formers: for type constructors and higher kinds, only cell monads
  and their duals, in a locally presentable, locally cartesian closed
  (infinity,1)-category, as Cubical TT represents it.
- R2 base types and operations: the minimum that satisfies the pasted
  description (the five bullets under "The language").
- R3 governance: a ZK FHE MPC UAT-compliant self-referential DAO governs.
  The paste names it: an orbit-lang DAO.
- R4 host: TinyCC.

USER rulings (S1, 2026-10-24), verbatim:

> Q1-Q10 -> take all defaults

So each question of section 11 takes its recommendation (a):

- Q1 (a): the target is EVM bytecode by hosts/tcc-evm-contract, for any
  EVM chain.
- Q2 (a): S2 ports the kernel of intent-lang ef5abe8 (section 6). R1 is
  already enforced there.
- Q3 (a): `answers M` gives one branch for each outcome, each with a
  reading that gives that outcome (4.2).
- Q4 (a): a dispute is a path in `Contest A`, a cell monad. `Contest A` is
  a proposition, so the path says only "in dispute" (4.1).
- Q5 (a): a proposal carries a reading; its outcome is `rule M r` (3.2).
- Q6 (a): public positions frozen at the deadline, a bLSAG over the masked
  member ring and a key image for each dispute (4.3).
- Q7 (a): the majority of the opened tally gives the verdict; a tie keeps
  the first proposal (4.4).
- Q8 (a): a parimutuel pool: `take` before the deadline, `claim` after
  `finalize` (section 7).
- Q9 (a): no bonds in v1.
- Q10 (a): the proposal reports the data of the sources; the dispute is
  the check (3.2).

USER rulings (S3, 2026-10-24) on Q-S3-1 to Q-S3-5 (section 11), verbatim:

> All five (a) (Recommended)

So each Q-S3 question takes its recommendation (a):

- Q-S3-1 (a): a market is in a kit program only. A guest market gives
  `REFUSE_KIT`; a market in `domain/domain.lang` gives `REFUSE_DATA`.
- Q-S3-2 (a): the lexer reads `M.x` as one name in a program. A program
  `def` whose name has a `.` gives `REFUSE_NAME`.
- Q-S3-3 (a): a market with no `answers` clause is a parse refusal
  (`PARSE_EXPECT`).
- Q-S3-4 (a): the program writes `answers` as an `elim` term. Each branch
  does an `elim` on its `Unit` field.
- Q-S3-5 (a): an outcome with no reading gives `PATH_END`.

Builder calls (section 10 gives each one; Q1 and Q2 rule O2 and O3):

- O1: the name resolve-lang (the title of the paste).
- O2: the target is EVM bytecode, with the kit hosts/tcc-evm-contract. The
  request names no target. The DAO (orbit-lang), the siblings that the paste
  names (sealed-lang) and intent-lang all use this kit, and Polymarket
  settles on an EVM chain. RULED: Q1 (a).
- O3: the kernel comes from intent-lang ef5abe8, not from orbit-lang 2162fb2.
  intent-lang already enforces R1 with the same words (section 6). RULED:
  Q2 (a).
- The "Activity" bullets are motivation. The paste marks them as secondary
  sources. The plan does not check them, and no type or operation comes
  from them. They name three threats that the design answers: many
  disputes, votes in few wallets, and voters with a stake in the market.
- The "Fit" bullet places the language beside sealed-lang and auction-lang.
  No type or operation comes from it.
- Tests are guest-language files plus `langc run` scripts. The kit gate
  scripts stay. We add no new harness.

## 2. The reading of R1

R1 has the same words as the type-former ruling of intent-lang. intent-lang
P section 2 gives the reading, and its S3 and S4 put it in the checker. The
S2 port (section 6) carries that checker. resolve-lang does not build it
again.

| Part | Cubical TT | R1 limit |
|---|---|---|
| Ambient | Pi, Sigma, `Path`, `PathP`, `I`, `i0`, `i1`, `transp`, `hcomp`, `U`, `Glue`, `ua`, the builtin `Sum` and `Unit` | none: the internal language of the category |
| CM, cell monad | a `family` with a type parameter: the parameter is the one field of one generator; each other field is closed base data, the family at its own parameters, or a path in it | else `REFUSE_CELL` |
| CC, cocell comonad | a `cofamily` with one observation `A` and cofields `D A` or `E -> D A` | else `REFUSE_CELL` |

Only `domain/domain.lang` declares a family or a cofamily. A program that
declares one gets `REFUSE_DATA`. A family with no type parameter is a base
type, not a type constructor. R2 limits it, not R1.

What R1 means for resolve-lang:

- An outcome set is closed base data. A program writes it as a nested `Sum`
  of `Unit`, as intent-lang does (`examples/regimes.lang:6`). It is a set:
  equality is decidable, so Hedberg's theorem applies.
- The dispute type (4.1) is the only new type constructor. It is a cell
  monad.
- The new base types (positions, the dispute record) have no type
  parameter.

## 3. The minimal base signature (R2)

Each type and operation below answers one bullet of the paste. The table
gives the bullet, the minimum and the reading.

| Bullet | Minimum | Reading |
|---|---|---|
| typed term over named sources and a deadline | `Reading M`, `Outcome M`, `rule M`, `deadline M` | 3.2 |
| every outcome needs a branch | `answers M` | 3.2, 4.2 |
| a dispute is a path between proposed outcomes | `Contest`, `dispute`, `verdictAt` | 4.1 |
| ZK proof of no position | `position`, frozen ledger, eligible ring, per-dispute key image | 4.3 |
| an orbit-lang DAO governs | the ported DAO, `Params`, encrypted ballots on `Verdict` | 3.1, 3.3 |

### 3.1 Part D: the DAO

Part D is the DAO of intent-lang (P 3.1 and 3.4). It comes with the S2 port.
The S2 port changes no name.

- Kit base data: `U256`, `Addr`, `Env` (`now`, `block`, `caller`), `Out`
  (`pay`, `pull`, `emit`), the contract state. S3 b1 adds `block` (O5).
- Slots: `Member`, `Choice`, `Group`, `Decision` (one value of `Params`).
- Defined: `Config`, `Orbit` (= `Config / act`), `Constitution`,
  `Aggregation`, `Tally`, `act`, `orbitProj`, `aggregate`, `gov`, `amend`.
- Self-reference: `Charter` and `Ratified` (D:217-223). The DAO amends its
  own charter by its own vote.
- ZK: `ZKProof W := Trunc1 W` (D:159), `Transcript`, the law `verified`,
  Sigma verifiers by Fiat-Shamir, bLSAG ring ballots.
- FHE: the sealed `Enc` monad (D:136), law-only `decrypt` and `observe`,
  exponential ElGamal on BN254 in the host.
- MPC: `Quorum` and the law `open` (D:149-151). The members hold threshold
  shares. The chain checks one DLEQ proof for each share.
- UAT: aggregation is the left Kan extension along the voter-orbit quotient
  (orbit-lang `design/DESIGN.md:39`, from MavenRain/self-referential-dao).
  The orbit quotient makes the vote anonymous: a permutation of the members
  does not change the result.

intent-lang has not built its encrypted ballots yet (its S9: `tallyEnc`, the
tally law `open q (tallyEnc bs) == count (map decrypt bs)`). resolve-lang
builds them in its S6 for the dispute ballot (O12).

### 3.2 Part M: the market

A market `M` has five parts. A program gives them with the `market` form
(O4). The form elaborates to ordinary definitions, and the checker checks
each one:

| Part | Type | Note |
|---|---|---|
| `M.sources` | named fields `s1 ... sn` | each source is a `U256` value at the deadline |
| `Reading M` | `U256 * ... * U256` | ambient product; `M.s1 : Reading M -> U256` is the projection |
| `Outcome M` | nested `Sum Unit` | the labels `M.Yes`, `M.No`, ... name its values |
| `deadline M` | `U256` | a block number (O5) |
| `rule M` | `Reading M -> Outcome M` | a total term: no general recursion |
| `answers M` | `(o : Outcome M) -> Sigma (r : Reading M) (Path (Outcome M) (rule M r) o)` | one branch for each outcome (4.2) |

A proposal carries a reading, and its outcome is `rule M r` (Q5 (a)). So a
proposal cannot claim an outcome that its own reading does not give. The
vote is about the facts (which reading is true), not about the rule.

The data sources are reported: the proposer gives the reading, and the
dispute is the check (Q10 (a)).

### 3.3 Part R: resolution

| Name | Kind | Meaning |
|---|---|---|
| `Contest A` | CM (4.1) | proposals and the disputes between them |
| `prop : A -> Contest A` | generator | a proposal |
| `dispute` | 1-cell generator | a path between two proposals |
| `Verdict` | `Sum Unit Unit` | the endpoint that the DAO picks: `left` = `i0`, `right` = `i1` |
| `verdictAt` | defined | the path evaluated at the verdict endpoint |
| `position : U256 -> Addr -> U256` | state | the stake of an address in a market |
| `take` | entry | adds stake before the deadline (Q8) |
| `Eligible M k` | defined | `Path U256 (position M (addr k)) 0` at the deadline |
| `Params` | DAO decision | `disputeWindow`, `voteWindow` (in blocks) |

## 4. Readings of the design on Cubical TT

### 4.1 A dispute is not a path in `Outcome M`

`Outcome M` is a finite sum of `Unit`. Its equality is decidable, so it is a
set (Hedberg), and `inl` and `inr` are disjoint. A path in `Outcome M`
between two different outcomes is a proof of a false statement. A path
between two equal outcomes is `refl`. So a dispute cannot be a path in
`Outcome M`. intent-lang met the same problem with the decay of an amount
(P 4.1).

Reading (Q4 (a)): a dispute is a path in a cell monad of proposals.

```
family Contest (A : Type 0) :=
    prop (propOf : A)
  | dispute (dA : Contest A) (dB : Contest A) (dGround : U256) (i : I)
      [~i -> dA, i -> dB]
```

This is a cell signature: `A` is the one field of the generator `prop`, and
`dispute` takes the family at its own parameter, closed base data (the
dispute id) and the interval. A dispute between proposals `p` and `q` is
`fun i => dispute (prop p) (prop q) g i : Path (Contest A) (prop p) (prop q)`.
It is a path between proposed outcomes, as the paste says. The two ends are
`prop p` and `prop q` by definition.

The verdict picks an endpoint of the interval:

```
verdictAt d v := either (fun _ => d @ i0) (fun _ => d @ i1) v
```

The contract keeps the proposal at that end. No eliminator out of `Contest
A` is needed, so the paths never have to map into `Outcome M`.

A consequence that the USER must see: for a fixed `g`, the 1-cell connects
every two points, so `Contest A` is a proposition (the same argument as
`squash1`). All disputes between `p` and `q` are equal as paths. The path
says "p and q are in dispute"; the dispute id and the ballots live in the
contract state. Q4 (b) keeps the identity of each dispute in the path: a
family with no type parameter whose points are outcome codes (`Pos n`) and
whose 1-cell takes two codes and an id, in the shape of `orbitNEq`
(D:205-206). Then `Contest` is a free groupoid, a chain of disputes is a
path (composition by `trans`, D:21-23), and two disputes are different
paths. The cost: a proposal is an outcome code, not a typed reading, and
`Contest` is a base type, not a type constructor.

### 4.2 Every outcome needs a branch

Reading (Q3 (a)): `answers M` is a dependent function out of `Outcome M`.
The program writes it with `elim` on the nested `Sum`, one branch for each
outcome. Each branch gives a reading and `refl`: `rule M r` computes to the
outcome when `r` is closed.

- A missing branch: the checker refuses the `elim` (wrong case count,
  `TYPE_MISMATCH`, intent-lang `test/check/elim-case-count.lang`).
- An outcome that no reading gives: the branch has no term, so the market
  does not type-check. This is the sentence of the paste.
- A reading with no outcome: `rule M` is a total function, so this cannot
  occur.
- A reading with two outcomes: `rule M` is a function, so this cannot occur.

Q3 (b) is coverage only: `rule M` total, no `answers`. The kernel already
gives that, so the bullet would add nothing.

The refusal code stays `TYPE_MISMATCH`. A dedicated code (`REFUSE_BRANCH`)
is O8.

### 4.3 The ZK proof of no position

Reading (Q6 (a)):

- Positions are public contract state. `take` adds stake. A `take` at a
  block at or after `deadline M` is refused, so the ledger is frozen at the
  deadline. No voter can buy a stake after the ring is fixed.
- The eligible ring of `M` has one slot for each member `i`. The slot holds
  the member key `K_i` when `position M (addr K_i) == 0`. Otherwise it holds
  `N_i`, a point with no known discrete log (hash to curve of `i` and a
  fixed tag). Nobody can sign for `N_i`, so a member with a stake cannot
  sign. The ring size stays `n`, and each slot is one of two compile-time
  constants. The bLSAG verifier keeps its unrolled form (H:318) and picks
  each slot from state.
- The ballot carries a bLSAG ring signature over that ring. The ring
  signature is a Sigma OR-proof, so it is a zero-knowledge proof of the
  statement `Sigma (k : Member) (Eligible M k * Owns k)`. In the type it is
  `ZKProof (...)`.
- One member, one ballot for each dispute: the key image is the nullifier.

Finding from the survey: in intent-lang the key image `I = x * Hp(K)` does
not depend on the poll (H:318; inferred, not tested). With a ring that
changes from market to market, a fixed key image is an intersection attack:
an observer who sees the same `I` in three markets knows that the voter is
in the intersection of the three eligible sets. resolve-lang needs a key
image for each dispute, `I = x * Hp(K, poll)` (O10). The cost is one hash
to curve for each slot for each dispute, on chain (MODEXP 0x05 for the
square root).

Limit, stated in SPEC as a non-goal: the proof covers the stake that the
member's registered key holds in this market's ledger. A stake through
another wallet, another venue or an off-chain hedge is outside any on-chain
proof. The charter's binding of a member to a key is the only defense.

Q6 (b): positions are encrypted (`Enc`), and the voter proves with a Sigma
proof that their committed stake opens to 0. It hides the stakes, and it
costs a new proof form.

### 4.4 The vote and the UAT regime

A dispute is a path, so it has exactly two ends. The verdict has two
alternatives. For two alternatives, simple majority is the only rule that is
anonymous, neutral and positively responsive (May's theorem, 1952). So
Arrow's theorem does not apply. The design gives the three conditions:

- anonymous: the orbit quotient of the DAO;
- neutral: `sym` swaps the ends, and `verdictAt (sym d) (swap v) ==
  verdictAt d v` holds by `refl` in each case of `v` (L6);
- positively responsive: majority on the opened tally.

orbit-lang `design/DESIGN.md:39` names three UAT regimes. Which regime holds
a binary verdict is O11 (read MavenRain/self-referential-dao).

The verdict rule (Q7 (a)): the opened tally of `right` votes against `left`
votes; a tie keeps the first proposal (`left`, `i0`).

### 4.5 The chain fragment

From intent-lang (P 4.3), unchanged: exponential ElGamal on BN254 G1 (ecAdd
0x06, ecMul 0x07), the threshold opening with one DLEQ proof for each share,
Sigma verifiers by Fiat-Shamir (keccak), bLSAG membership. New: the masked
ring (4.3), the key image for each dispute (O10), `Env.block` lowered to
NUMBER 0x43 (O5).

### 4.6 The market form

S3 s1 (2026-10-24) writes this design. Q-S3-1 to Q-S3-5 (section 11) are
RULED: (a) (section 1). Each choice below is the recommendation (a), and
S3 s2 builds it. The probes ran
`build/langc check` (the S3 b1 build) on the guest files p1 to p9 in
`~/Documents/resolve-lang-work/S3-probes/`.

Surface: one top-level form. The clauses come in this order, one time each.

```
market Rain :=
  sources rainfall temp
  outcomes Yes | No
  deadline 1000u
  rule fun (r : Rain.Reading) => flagIf (u256Le 50u (Rain.rainfall r)) Rain.Yes Rain.No
  answers fun (o : Rain.Outcome) =>
    elim (fun (x : Rain.Outcome) => Sigma (r : Rain.Reading) (Path Rain.Outcome (Rain.rule r) x))
      (fun (u : Unit) => elim (fun (v : Unit) => Sigma (r : Rain.Reading) (Path Rain.Outcome (Rain.rule r) (inl v))) (pack (pair 60u 20u) refl) u)
      (fun (u : Unit) => elim (fun (v : Unit) => Sigma (r : Rain.Reading) (Path Rain.Outcome (Rain.rule r) (inr v))) (pack (pair 10u 20u) refl) u) o
```

- `sources s1 ... sn`: one or more names. Each source is a `U256` (3.2). A
  source can have any name (O9).
- `outcomes L1 | ... | Lk`: two or more labels.
- `deadline t`: `t : U256`, a block number (O5).
- `rule t`: `t : M.Reading -> M.Outcome`. `flagIf` takes any result type
  (`examples/residuals.lang:28`), so a rule branches on `u256Le` and
  `u256Eq`.
- `answers t`: `t` has the type of `M.answers` below (Q-S3-4).

Elaboration: the form becomes text, as `check_cofamily` does in intent-lang
(SPEC "choice (ii)"). The checker checks each generated declaration as a
program `def`, in this order:

| Name | Text | 3.2 |
|---|---|---|
| `M.Reading` | `def M.Reading : Type 0 := Prod U256 (Prod U256 ... U256)` (n = 1: `U256`) | `Reading M` |
| `M.si` | `def M.si : M.Reading -> U256 := fun (r : M.Reading) => first (second^(i-1) r)` (i = n: `second^(n-1) r`) | `M.si` |
| `M.Outcome` | `def M.Outcome : Type 0 := Sum Unit (Sum Unit ... Unit)` (k copies of `Unit`) | `Outcome M` |
| `M.Lj` | `def M.Lj : M.Outcome := inr^(j-1) (inl unit)` (j = k: `inr^(k-1) unit`) | the labels |
| `M.deadline` | `def M.deadline : U256 := t` | `deadline M` |
| `M.rule` | `def M.rule : M.Reading -> M.Outcome := t` | `rule M` |
| `M.answers` | `def M.answers : (o : M.Outcome) -> Sigma (r : M.Reading) (Path M.Outcome (M.rule r) o) := t` | `answers M` |

The form makes no reading constructor: a branch writes `pair`.

Probe facts (b1 build):

- `elim` takes a `Sum` scrutinee with a dependent motive (p1). A `def` of a
  type (`def O : Type 0 := Sum Unit Unit`) unfolds in the motive and the
  scrutinee (p9).
- The kernel has no eta rule for `Unit`. `refl : Path (Sum Unit Unit) (inl
  unit) (inl x)` for a variable `x : Unit` gives `PATH_END` (p3). Thus a
  branch `fun (u : Unit) => pack r refl` fails (p5). Each branch does an
  `elim` on its `Unit` field, as in the example; that checks (p7, p8, p9).
  With three outcomes, the `inr` case gets `t : Sum Unit Unit` and does one
  more `elim` on `t`.
- A missing branch gives `TYPE_MISMATCH`: "elim on Sum Unit Unit needs a
  motive, 2 cases and a scrutinee" (p6). This is the O8 code.
- A branch whose reading gives a different outcome gives `PATH_END`: "the
  path at i1 is inr unit, but the type needs inl unit" (p9). Section 8 says
  `TYPE_MISMATCH` for this case before Q-S3-5. RULED: (a) keeps `PATH_END`.

Refusals:

| Case | Code | Question |
|---|---|---|
| no `answers` clause, a clause missing or out of order | `PARSE_EXPECT` | Q-S3-3 |
| no source, or fewer than two outcomes | `PARSE_EXPECT` | Q-S3-3 |
| a program `def` whose name has a `.` | `REFUSE_NAME` | Q-S3-2 |
| a label or a source two times, or a label equal to a source or to a generated name | `REFUSE_NAME` ("already defined", check.c:3071) | |
| a `market` in a guest program | `REFUSE_KIT` (the `U256` of `M.Reading`, check.c:2605) | Q-S3-1 |
| a `market` in `domain/domain.lang` | `REFUSE_DATA` | Q-S3-1 |
| a missing branch | `TYPE_MISMATCH` | O8 |
| an outcome with no reading | `PATH_END` | Q-S3-5 |

A diagnostic with a line number in a clause term (`deadline`, `rule`,
`answers`) gives the line in the generated text (source `market M`), not the
line in the program. The checker checks the generated `def` text again.
Kept for S3; S8 can map the line back.

Build sites (S3 s2): lexer.h `TokKind`; lexer.c:21-72 (keywords) and
240-264 (names: today only `lex_internal` lets a name hold `.`); parser.c
130-166, 370-406 and 614-669 (top-level forms); ast.h:65-70 (declaration
kinds); check.c:4515-4562 (form dispatch), with `check_cofamily`
(check.c:4250-4513) as the model.

## 5. Laws

| Law | Statement | How it holds |
|---|---|---|
| L1 total | `rule M : Reading M -> Outcome M` | a term of the type |
| L2 answer | `answers M o` for each `o` | `elim`, each branch `refl` |
| L3 ends | `d @ i0 == prop p`, `d @ i1 == prop q` | definitional |
| L4 verdict | `verdictAt d left == prop p`, `verdictAt d right == prop q` | `refl` |
| L5 moot | if `rule M r == rule M s`, the contract refuses the dispute | state rule; the outcomes agree |
| L6 neutral | `verdictAt (sym d) (swap v) == verdictAt d v` | `elim` on `v`, `refl` |
| L7 freeze | `take` at `block >= deadline M` reverts | state rule |
| L8 eligible | a ballot verifies only over the masked ring at the deadline, with a fresh key image for the dispute | verifier |
| L9 tally | `open q (tallyEnc bs) == count (map decrypt bs)` | law-only, as in intent-lang P 3.1 |
| L10 privacy | only the tally opens; `observe = |_| . decrypt` | squash path (intent-lang S5) |
| L11 DAO | the Lan unit, descent and uniqueness laws; charter ratification | ported (orbit-lang, intent-lang) |

## 6. Kernel route

S2 copies intent-lang ef5abe8 with `git archive ef5abe8 | tar -x` into the
seed. This is how intent-lang S2 ported orbit-lang (P:330-343). kitshift.py
does not fit (its KEPT rule keeps the seed files). After the copy:

- Rename `intent-lang` to `resolve-lang` in the names of the language. The
  "(orbit-lang Sn ...)" and "(intent-lang Sn ...)" comments stay as
  provenance.
- Keep Part D, Enc, Quorum, Transcript, the Sigma verifiers, the bLSAG
  ballots and ecrecover. ecrecover has no use in resolve-lang (O13).
- intent-lang has no swap code at ef5abe8, so nothing is removed.
- The gate after the port is `make -B check`: archive mtimes are stale.
  The S2 target is the intent-lang S7 counters: examples 49, check refusals
  186, kit-only refusals 22, evals 188, precompile 143 steps, emit 24, every
  regression line passed (`~/Documents/intent-lang-S7-b5-gate.log`).

S2 (DONE, 2026-10-24): the port is `git -C intent-lang archive ef5abe8 src
domain examples test gen Makefile | tar -x`, then `git archive ef5abe8` of
SPEC.md, docs/host/README.md, docs/VALIDATION.md, formers/FORMERS.md,
formers/tcc-evm-contract.md and probe/CAPABILITY.md. The seed keeps
design/, docs/PLAN.md, README.md and LICENSE-*. docs/STATUS.md keeps the
seed text and gets an S2 item with the list of name edits. After the copy,
the code is the ef5abe8 code byte for byte (`diff -rq`). Surprises:

- The seed has two files that ef5abe8 does not have:
  `examples/inventory.lang` and `test/check/domain-name.lang`. The archive
  does not remove them, so S2 removes them (`git rm`), as intent-lang S2
  did. They are seed files, not ported code, so "nothing is removed" above
  still holds for the port.
- There are four name edits, the same four sites as in intent-lang S2:
  SPEC.md lines 1, 3 and 14, and docs/host/README.md line 3. The other
  `intent-lang` words in the ported files are provenance: the comment at
  src/front/front.c:12, and the evidence paths
  `~/Documents/intent-lang-work/...` in docs/VALIDATION.md (lines 315 and
  373), test/secptool.c:3 and test/precompile.sh:144.
- The gate log `~/Documents/resolve-lang-S2-gate.log` is byte for byte the
  intent-lang S7 log (110 lines). No name edit is in a file that the gate
  reads.

## 7. The contract

One contract for each program. The markets of the program are a closed
list; a market id is its index.

| Entry | When | Effect |
|---|---|---|
| `take M o x` | `block < deadline M` | `pull x`; `position M caller` (the total stake) and the pool of outcome `o` grow by `x` (Q8) |
| `propose M r` | `block >= deadline M`, no proposal | stores `r`, `rule M r` and the block |
| `dispute M s` | within `disputeWindow` of the proposal | refused if `rule M s == rule M r` (L5); stores `s`, opens a poll |
| `ballot M c sig` | within `voteWindow` | `c : Enc (Verdict -> U256)` one-hot; checks the one-hot proof and the masked-ring bLSAG (L8) |
| `openTally M shares` | after `voteWindow` | threshold open (L9); stores the verdict (4.4) |
| `finalize M` | after `disputeWindow` with no dispute, or after `openTally` | stores the resolved outcome; emits `Resolved` |
| `claim M` | after `finalize` | pays the stake share of the winning outcome (Q8 (a)) |
| DAO entries | any time | charter amendment, `Params` ratification (ported) |

Events: `Proposed`, `Disputed`, `Voted` (the key image only), `Resolved`.

## 8. Tests

Guest files under `test/check/` and `examples/`, `langc run` scripts under
`test/run/`, and chain rows in the kit scripts:

- `market-missing-branch.lang`: `answers` with one branch missing gives
  `TYPE_MISMATCH`.
- `market-unanswerable.lang`: an outcome whose branch gives a reading that
  computes to another outcome gives `PATH_END` (4.6, Q-S3-5 (a)).
- S3 s2 rows for the other refusals of 4.6: `market-dotted-def.lang` and
  `market-label-source.lang` give `REFUSE_NAME`, `market-guest.lang` gives
  `REFUSE_KIT` (and checks in kit mode), `test/parse/market-no-answers.lang`
  gives `PARSE_EXPECT`, and a fronttool row gives `REFUSE_DATA` for a
  market in the domain. Eval rows apply `M.rule` to a reading and take the
  `witness` of `M.answers` at a label (`examples/market.lang`).
- `contest-ends.lang`, `contest-neutral.lang`: L3, L4, L6 by `refl`.
- `contest-cell.lang`: `Contest` passes the cell-signature check; a variant
  with `dispute (dA : A) ...` gives `REFUSE_CELL`.
- Run scripts with the block column: a `take` at the deadline reverts; a
  dispute with the same outcome is refused; a ballot from a member with a
  stake fails the ring check; a second ballot with the same key image is
  refused; a tie keeps the first proposal.
- Ring rows: the same member in two disputes gives two different key
  images (O10).

## 9. Slices

| Slice | Content | Status |
|---|---|---|
| S0 | generate from lang-template (tcc-evm-contract); DESIGN verbatim; this plan; README; kit gate | DONE |
| S1 | USER rules Q1-Q10; this plan records the rulings | DONE |
| S2 | port intent-lang ef5abe8 (section 6); gate = the intent-lang S7 counters | DONE: `make -B check` EXIT 0 with the intent-lang S7 counters: 49 examples, 0 failed; 19 parse, 186 check and 22 kit-only refusals; 188 evals, 2 proves; contracts 2 written and 5 refused; rings 6 built and 2 refused; 28 guest and 14 host differential rows; 5 runs, 10 run refusals; 8 asmtool; 3 builds, 16 lower refusals, 33 build checks; 20 dispatch; 43 evm steps; 14 precompile rows and 143 steps; 13 mock rows; 15 diff rows; 24 emit regressions; the 13 "regressions: passed" lines; 0 failures. The log is byte for byte the intent-lang S7 log (section 6) |
| S3 | `Env.block` in the guest (O5); the `market` form (O4): `Reading`, `Outcome`, labels, `rule`, `answers`, `deadline`; rows of 4.2 | s1 DONE (2026-10-24): b1 `Env.block` (O5) is the intent-lang S8 b1 port, and `make -B check` EXIT 0 with the S2 counters except 50 examples (`blocks.lang`), 6 runs (`blocks.script`), 11 run refusals (a bad BLOCK), 17 lower refusals and 34 build checks (`env-block.lang`). The log is byte for byte the intent-lang S8 b1 log. The market design is 4.6. s2 DONE (2026-10-24): the market build after the USER rulings Q-S3-1 to Q-S3-5 (a) (section 1): the `market` keyword and `M.x` names in a program, `parse_market`, `check_market` (text elaboration), `examples/market.lang` (Rain and Heat), five check rows, one parse row, six eval rows and a fronttool `REFUSE_DATA` row. `make -B check` EXIT 0 with the s1 counters except 51 examples, 20 parse, 191 check and 23 kit-only refusals, and 194 evals. DONE |
| S4 | `Contest` in `domain/domain.lang`; `Verdict`, `verdictAt`, `swap`; L3, L4, L6; the cell rows | NEXT |
| S5 | the position ledger, the freeze, the masked ring, the key image for each dispute (O10) | |
| S6 | encrypted dispute ballots: one-hot `Enc` over `Verdict`, `tallyEnc`, L9, threshold open, majority; `Params` in the DAO | |
| S7 | the contract writer: the entries of section 7; `Env.block` lowered to NUMBER; chain rows | |
| S8 | mutants, SPEC, VALIDATION, close | |

## 10. Open items

Each item is RULED (S1, 2026-10-24) or kept as the builder call.

- O1 name: resolve-lang. Builder call. Kept.
- O2 target: EVM by hosts/tcc-evm-contract. RULED: Q1 (a).
- O3 kernel: port intent-lang ef5abe8. RULED: Q2 (a).
- O4 the `market` form: a top-level form that elaborates to definitions, as
  the cofamily form does in intent-lang (text elaboration). The checker
  refuses a market without `answers`. The alternative is a Sigma over the
  universe; it loses the source names. Kept. Q3 (a) makes `answers` a
  necessary part of the form. S3 s1: the design is 4.6 (Q-S3-1 to Q-S3-5).
  RULED: Q-S3-1 to Q-S3-5 (a). S3 s2 builds the form.
- O5 deadline in blocks: `Env.block : U256` in the guest and NUMBER 0x43 in
  the contract. This is the design of intent-lang O17 (its USER ruling Q4
  (b)), not yet built there. If intent-lang builds it first, S3 ports it.
  Kept. S3 b1 ports the guest side from intent-lang S8 b1 (not committed
  there, so S3 replays its replacers). The b1 files keep the intent-lang
  slice and item names as provenance: intent-lang S10 and O36 (NUMBER) are
  resolve-lang S7 and O5.
- O6 one dispute round in v1. A dispute of the verdict (escalation) is path
  composition `trans d e`; it needs Q4 (b) to mean more than `refl`. Kept:
  Q4 (a) makes `Contest A` a proposition, so v1 has one round.
- O7 a dispute of a proposal against itself (`dispute (prop p) (prop p)`)
  is a loop. L5 refuses it in the contract. Kept.
- O8 a dedicated refusal code for a missing outcome branch. Default: keep
  `TYPE_MISMATCH`. Kept: `TYPE_MISMATCH`.
- O9 the source registry: which names a market can read. Default: any name;
  the DAO does not list sources in v1. Kept: any name. Q10 (a) puts the
  data in the proposal.
- O10 the key image for each dispute (4.3). Without it, the masked ring
  leaks the voter by intersection. Needs a hash to curve on chain. Test
  rows in section 8. RULED: Q6 (a). The hash to curve is S5 work.
- O11 the UAT regime of a binary verdict (4.4). Kept: open until S6.
- O12 intent-lang S9 builds the same encrypted ballots for its DAO.
  resolve-lang S6 builds them for the verdict. Later, one of the two ports
  the other's form. Kept.
- O13 ecrecover comes with the port and has no use. Keep it (no removal
  work) or remove it in S2. Kept: S2 keeps ecrecover (section 6).
- O14 the guest poll id is fixed to 0 (H:310). The dispute ballot needs a
  poll id for each dispute: a change of the signature. Kept: S6 work.
- O15 `claim` needs division (stake times pool over winning pool). The kit
  U256 operations need a check in S5. Kept: Q8 (a) keeps `claim`.
- O16 votes in few wallets: one member, one ballot (the ring and the key
  image), not token weight. The charter decides who is a member. Kept:
  Q6 (a) gives one ballot for each member.

## 11. Questions for the USER (S1, S3)

Each question has a recommendation (a). All ten are RULED (S1, 2026-10-24;
the quote is in section 1).

- Q1 target. (a) EVM bytecode by hosts/tcc-evm-contract, for any EVM chain.
  (b) Another TinyCC kit (name it). RULED: (a).
- Q2 kernel route. (a) Port intent-lang ef5abe8: R1 is already enforced.
  (b) Port orbit-lang 2162fb2 and narrow it to R1 again. RULED: (a).
- Q3 "every outcome needs a branch". (a) `answers M`: one branch for each
  outcome, each with a reading that gives it (4.2). (b) Coverage of `rule
  M` only. RULED: (a).
- Q4 the dispute path. (a) `Contest A`, a cell monad; a proposition, so the
  path says only "in dispute" (4.1). (b) A dispute groupoid over outcome
  codes with no type parameter; each dispute is its own path. RULED: (a).
- Q5 a proposal carries. (a) A reading; the outcome is `rule M r`. (b) An
  outcome only. RULED: (a).
- Q6 the no-position proof. (a) Public positions frozen at the deadline, a
  bLSAG over the masked member ring, a key image for each dispute. (b)
  Encrypted positions and a Sigma proof that the stake opens to 0. RULED:
  (a).
- Q7 the verdict rule. (a) Majority of the opened tally; a tie keeps the
  first proposal. (b) A quorum and a threshold that the DAO ratifies in
  `Params`. RULED: (a).
- Q8 the market around the resolution. (a) A parimutuel pool: `take` before
  the deadline, `claim` after `finalize`. (b) Positions as records, with no
  tokens. (c) No ledger: resolution only, with the positions from another
  contract. RULED: (a).
- Q9 bonds. (a) None in v1: the paste names none. (b) A proposer bond and a
  disputer bond; the loser pays. RULED: (a).
- Q10 data sources. (a) Reported in the proposal; the dispute is the check.
  (b) On-chain feeds read at the deadline block. RULED: (a).

S3 s1 (2026-10-24) adds five questions for the market form (4.6). Each has
a recommendation (a). The USER ruled all five (a) (section 1).

- Q-S3-1 where a market can be. (a) Kit programs only. `U256` and the
  `u256` operations are kit-only (REFUSE_KIT, check.c:2605), so a guest
  market gives `REFUSE_KIT`; a market in `domain/domain.lang` gives
  `REFUSE_DATA`. (b) Guest markets too, with `Nat` sources and a `Nat`
  deadline. RULED: (a).
- Q-S3-2 the names `M.x`. (a) The lexer reads `M.x` as one name in a
  program. Only the market elaboration makes such a name; a program `def`
  whose name has a `.` gives `REFUSE_NAME`. (b) Generated names with `_`
  (`M_x`), no lexer change; a program `def` can then take a generated name
  first. RULED: (a).
- Q-S3-3 a market with no `answers`. (a) A parse refusal: the grammar needs
  the `answers` clause (`PARSE_EXPECT`, one more parse refusal row). (b) A
  dedicated check code (`REFUSE_MARKET`). RULED: (a).
- Q-S3-4 the `answers` term. (a) The program writes it as an `elim` term;
  the kernel has no `Unit` eta, so each branch does an `elim` on its `Unit`
  field (4.6, probes p3, p5, p8). (b) The form takes `label => reading`
  pairs and writes the `elim` text; then a missing label is a form refusal,
  not `TYPE_MISMATCH` (O8 changes). (c) Add `Unit` eta to the conversion;
  then a branch is `fun (u : Unit) => pack r refl`, but each ported row must
  pass again on a kernel change. RULED: (a).
- Q-S3-5 the code for an outcome with no reading. (a) `PATH_END`, the code
  that `refl` at the wrong end gives (probes p4, p9); the section 8 row
  changes. (b) The market check maps `PATH_END` in `answers` to
  `TYPE_MISMATCH`, as section 8 said before the ruling. RULED: (a).
