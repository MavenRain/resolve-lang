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

- Kit base data: `U256`, `Addr`, `Env` (`now`, `caller`), `Out` (`pay`,
  `pull`, `emit`), the contract state.
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
  computes to another outcome gives `TYPE_MISMATCH`.
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
| S2 | port intent-lang ef5abe8 (section 6); gate = the intent-lang S7 counters | NEXT |
| S3 | `Env.block` in the guest (O5); the `market` form (O4): `Reading`, `Outcome`, labels, `rule`, `answers`, `deadline`; rows of 4.2 | |
| S4 | `Contest` in `domain/domain.lang`; `Verdict`, `verdictAt`, `swap`; L3, L4, L6; the cell rows | |
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
  necessary part of the form.
- O5 deadline in blocks: `Env.block : U256` in the guest and NUMBER 0x43 in
  the contract. This is the design of intent-lang O17 (its USER ruling Q4
  (b)), not yet built there. If intent-lang builds it first, S3 ports it.
  Kept.
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

## 11. Questions for the USER (S1)

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
