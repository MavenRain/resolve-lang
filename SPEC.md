# resolve-lang specification (draft)

Status: draft before milestone M0. `resolve-lang` is a working name.

Fill each section. The quoted line under each heading says what to write
there. Delete the quoted line when the section is complete.

## 1. Purpose

resolve-lang is a language for the resolution of prediction markets. Its
type formers are F1 to F19 of `formers/FORMERS.md`. Its core data types and
core operations are only the types and operations of `design/DESIGN.md`
(the design).

A `market` form (section 11) gives the data sources, the outcomes, the
deadline (a block number), the rule (a function from a reading of the
sources to an outcome) and the answers (for each outcome, a reading that
the rule maps to that outcome). The compiler checks that the rule is total
and that each outcome has an answer (L1, L2). A dispute of a proposed
outcome is a 1-cell of the cell monad `Contest` (section 12). The members
of the DAO vote on a dispute with encrypted one-hot ballots, signed over a
masked ring: a member with a stake in the market cannot sign a ballot that
verifies (L8). A contract program also supplies its state, `init`, entries
and views. `langc --kit build` writes its EVM bytecode when these
definitions meet the lowering restrictions (section 13). The host is
TinyCC (the tcc-evm-contract host of lang-template). The target is EVM
bytecode.

Sections 2 to 8 are the base language: the intent-lang text, ported from
intent-lang ef5abe8 (docs/PLAN.md section 6). Sections 11 to 16 give the
parts that resolve-lang adds. docs/PLAN.md records the rulings and the
build of each part.

## 2. Programs

> Write here: the form of a program and the refusal list. Copy the host
> forms from `formers/tcc-evm-contract.md`. Add each fixed first definition that the
> domain needs (for example a size parameter).

A program is a sequence of definitions:

```
def NAME : TYPE := TERM
```

The compiler refuses these host forms in a program: <the list from
`formers/tcc-evm-contract.md`>. It also refuses a definition that uses a core name or
a prelude name. Thus a program cannot add a data type, an unproved fact or
general recursion. Recursion comes only from `fold` and `unfold` (F6, F7).
The compiler writes the target; a program cannot.

Only `domain/domain.lang` declares a family; a `family` in a program gives
`REFUSE_DATA`. A family with a type parameter is a type constructor, so it
must be a cell signature (rule R1, S3): only type parameters, no `and`
block, each type parameter the one field of exactly one generator
constructor, and each other point field closed base data (independent of
the parameters and earlier fields), the family at its own parameters or
a path in it. Universe aliases in headers are normalized before this
shape check. Higher-kinded parameters and type indices are refused: type
arguments must be uniform universe parameters of a cell signature.
Else the checker gives `REFUSE_CELL`.
The cons list `List` (with `nil`, `cons` and `unfold`) is the kit host ABI:
a guest program that names one gives `REFUSE_CELL` and uses `FreeMon` of
`domain/domain.lang` in its place.
The dual of a cell monad is the cofree comonad of a cocell signature (S4,
O28). Only `domain/domain.lang` declares one: `cofamily D (A : Type n) :=
c (o : A) (f : D A) (g : E -> D A)`. A `cofamily` in a program gives
`REFUSE_DATA`. The shape: one type parameter, no index, no `and` block,
one clause with no result and no boundary, exactly one observation field
of the type `A`, and each other field a cofield `D A` or a labelled
cofield `E -> D A` with `E` closed base data in a universe at most `n`.
Else the checker gives `REFUSE_CELL`.
Closed labels are checked after normalization; erased references to the
parameter or earlier fields do not make a label dependent. The checked
closed label core is retained for `D.g.E`.
The checker elaborates the
cofamily to text (choice (ii)) and checks each generated declaration:
the positions `family D.pos := D.here | D.f (D.f.rest : D.pos) |
D.g (D.g.label : D.g.E) (D.g.rest : D.pos)` (with `def D.g.E := E`),
`def D := fun A => D.pos -> A`, the destructors `o : D A -> A` (the
position `D.here`), `f : D A -> D A` and `g : D A -> E -> D A`, the walk
`D.walk` (a fold over the positions that applies the steps from the
seed), the corecursor `c : (A S : Type n) -> (S -> A) -> steps -> S ->
D A` and the bisimulation principle `DBisim`. The steps and the
hypotheses of `DBisim` follow the field order. The generated names are
core names (rule R4): a definition that holds one gives `REFUSE_NAME`.
The head of a corecursor value is the observation of the seed, and its
tail is the corecursor at the next seed, by conversion. A state field of
a cofamily type is a function type, so it gives `REFUSE_STATE`.
The modifiers `sealed family` and `law def` are domain only (rule O7,
S5). A program that uses one gives `REFUSE_DATA`. The domain declares
`sealed family Enc (A : Type 0) := encEta (encOf : A)`, the identity cell
monad with a sealed eliminator, with `encBind`, `encMap` and `encOp2`.
It also declares two law defs: `decrypt : (A : Type 0) -> Enc A -> A` (the
counit) and `observe : (A : Type 0) -> Enc A -> Trunc1 A` (decrypt under
`Trunc1`). The law-only roots are a law def, an `elim` or a `fold` of a
sealed family, and a projection of a field of a sealed family's
constructor. A guest definition that uses a root or a law-only guest
definition is law-only too. The checker walks the checked declared type
before normalization, its quoted normal form, and the body of each guest
definition. Explicit binder annotations are retained for this walk, even
when their variables are unused. The walk does not enter an application of
the type former `Trunc1` (the constructor `trunc1` has no exemption). A
law-only guest definition must have a law type: after its Pi binders,
the codomain is a `Path` or a `Trunc1`. Else the checker gives
`REFUSE_LAW`. Kit mode records the law-only flag and does not refuse. A
state field of type `Enc A` gives `REFUSE_STATE`. The host model is
exponential ElGamal over BN254 G1 (`src/front/elgamal.c`, not guest
visible). The domain also declares `family Quorum := quorum (quorumT :
Size) (quorumN : Size)` (S6), the public part of a threshold opening (t
of n). Quorum is not sealed and has no parameter. The law def `open : (A
: Type 0) -> Quorum -> Enc A -> A` is `decrypt` for each quorum. A guest
use of `open` outside a law type gives `REFUSE_LAW`, as `decrypt` does. A
state field of type `Quorum` gives `REFUSE_STATE`. The shares, the partial
decryptions and their DLEQ proofs are host data (`src/front/threshold.c`).
The dealer requires fresh private seed entropy for its polynomial
coefficients; public coefficients expose sk from one share.
The chain checks one proof and the opening with `ecMul`, `ecAdd` and
`hash` (`examples/threshold.lang`).
The domain declares `def ZKProof : Type 0 -> Type 0 := fun W => Trunc1
W` (S7): a proof of W is the truncation of W, and zero knowledge is the
squash cell. ZKProof is a def, not a family. The O7 walk does not enter
an application of `ZKProof`, as it does not enter one of `Trunc1`: the
checked declared type is walked before normalization, where `ZKProof W`
is still an application of the def. The domain also declares `sealed
family Transcript (W : Type 0) := transcript (transcriptOf : W)`. In the
ideal model a transcript holds its witness, as an `Enc` holds its
plaintext. The law def `verified : (W : Type 0) -> Transcript W ->
ZKProof W` truncates the witness. A guest use of `verified` outside a law
type gives `REFUSE_LAW`, as `decrypt` does. A state field of type
`Transcript W` gives `REFUSE_STATE`. A failed check is a host refusal or
a chain revert, so the codomain is not an `Option`. The real proofs are
host data (`src/front/sigma.c`): a proof of randomness (a Chaum-Pedersen
DLEQ) and a one-hot ballot (one disjunctive proof for each slot, bound to
a context word ctx, and a proof of randomness for the sum). The chain
checks them with `ecMul`, `ecAdd` and `hash` (`examples/onehot.lang`).
Rule R17 (S7): a closed `ecrecover` computes in `langc eval`
(`src/front/secp256k1.c`) by the rules of precompile 0x01: v is 27 or 28
and 1 <= r, s < n, else the address 0. A high s is accepted (0x01 has no
EIP-2 rule). An open `ecrecover` is stuck and lowers to a STATICCALL to
0x01. A closed `ecAdd` or `ecMul` computes; `ecPairing` stays stuck.
A domain family can have an index telescope after its
parameters: `family ChoiceBag : Size -> Type 0 := ...`, a Pi
telescope that ends in `Type 0`. Each constructor of an indexed family
states its result after its fields: `choiceNil : ChoiceBag sz0`. A path
constructor states it after its interval fields and before its boundary.
A constructor with no result, a result whose head is not the family at its
parameters, or an end of a path constructor at another index gives
`HIT_INDEX`. The keyword `and` joins the sorts of an inductive-inductive
block: `family Charter := ... and Ratified : Charter -> Type 0 := ...`
(no type parameter: S3 fixes the rule type to `Size`, rule R1). The headers bind first, then the point
constructors of all sorts, then the path constructors. A header that names
its own sort or a later sort of its block gives `BLOCK_ORDER`. A fold over
an indexed family has one constant target, as a fold over a uniform family
does. A fold over a block of n sorts takes n target types (one for each
sort in declaration order), then one case for each constructor of each
sort (sort by sort, in declaration order), then the value. The sorts share
the parameter telescope of the scrutinee (F18, F19).

`elim` also takes a domain family with path constructors (F16, USER ruling
S7). The motive binds the indices and then the value: `P : (n : Size) ->
Bag A n -> Type 0`. A point case takes the fields and an induction binder
after each recursive field or path field. A path case is a PathP over the
motive, and a squash case is a square over the motive. A block sort is
outside `elim`. The DAO prelude (`Config`, `Constitution`, `Aggregation`,
`Tally`, `aggregate`, `gov` and `amend`) follows the last of `orbitProj`
and `outcomeSet`. The program gives the proof slot `def outcomeSet : isSet
Outcome` after `Outcome`, and the slot `def menu : Outcome ->
Constitution` after the prelude. A slot at another type, or a program
definition of a prelude name, gives `REFUSE_SIG`. The domain families
`Pos : Size -> Type 0` (the positions of a bag) and `Word : Size -> Type
0` (the words of adjacent swaps) give the guest theorem `bagOrbit : (n :
Size) -> Equiv (OrbitN n) (Bag Choice n)` (`examples/bagorbit.lang`).

## 3. Type formers

> Write here: only the deviations from the formers. Do not copy the forms.
> Give each former whose status in `formers/tcc-evm-contract.md` is not DONE, and the
> open item (section 9) that records it.

The type formers are F1 to F19 of `formers/FORMERS.md`. This language uses
the tcc-evm-contract column of the realization matrix. `formers/tcc-evm-contract.md` gives
the host form of each former.

| ID | Status on tcc-evm-contract | Effect on this language | Open item |
|---|---|---|---|
| | | | |

## 4. Structures

> Write here: the carriers of Monad (F5), fold and unfold (F6, F7) and
> filter (F8) that the design uses. Name each carrier that the host does not
> give.

- **Monad**: `pure`, `map`, `bind` on <carriers>.
- **Algebra**: `fold` on <carriers>. `unfold` on <carriers>, or the reason
  that there is no `unfold`.
- **Filterable**: `filter` on <carriers>.

## 5. Core types

> Write here (DOMAIN SLOT): only the types of `design/DESIGN.md`. Give each
> type its meaning in the design and its definition in host forms. Mark each
> definition that a probe fact forces with "probe-forced".

| Type | Meaning (design section) | Definition |
|---|---|---|
| | | |

## 6. Core operations

> Write here (DOMAIN SLOT): only the operations of `design/DESIGN.md`. Give
> each operation its type and its meaning in the design.

| Operation | Type | Meaning (design section) |
|---|---|---|
| | | |

## 7. Target and instance encoding

> Write here: what the compiler writes. For a JSON target, give the instance
> rule and the encoding table. For a contract target, give the storage, the
> entries and the guards. Say how each proof erases.

An instance is a top-level definition whose type is a data type (F14).

| Type | Encoding |
|---|---|
| | |

## 8. Host and target

> Write here: the host, its pinned commit (`PIN`), the facts from
> `probe/CAPABILITY.md` that set the design, and the check that the compiler
> runs on its output (for example the axiom report).

## 9. Open items

The items are those of docs/PLAN.md section 10. Each one is RULED, CLOSED
or kept as a builder call. The questions and the rulings are in
docs/PLAN.md section 11.

- O1. The name: resolve-lang. Kept (builder call).
- O2. The target: EVM by the tcc-evm-contract host. RULED 2026-10-24
  (USER): Q1 (a).
- O3. The kernel: a port of intent-lang ef5abe8. RULED 2026-10-24 (USER):
  Q2 (a).
- O4. The `market` form: a top-level form that elaborates to text (section
  11). RULED 2026-10-24 (USER): Q3 (a), Q-S3-1 to Q-S3-5 (a). Built (S3).
- O5. The deadline in blocks: `Env.block` in the guest, NUMBER (0x43) in
  the contract (section 14). Built (S3, S7).
- O6. One dispute round in v1. `Contest A` is a proposition (Q4 (a)), thus
  a dispute of a verdict has no meaning in v1. Kept: a limit (section 16).
- O7. A dispute of a proposal against itself is a loop. L5 refuses it in
  the contract. Kept.
- O8. The refusal code for a missing outcome branch: `TYPE_MISMATCH`.
  Kept. Probe-forced (PLAN 4.6, p6).
- O9. The source registry: a market can read any name. The proposal holds
  the data (Q10 (a)). Kept.
- O10. The key image for each dispute: the tweaked key of the member and a
  deployment-scoped dispute id (section 13). RULED 2026-10-24 (USER): Q6
  (a), Q-S5-1 and Q-S5-2 (a). Built (S5, S7).
- O11. The UAT regime of a binary verdict: one verdict for each tally (the
  Arrow-Debreu regime). CLOSED (S6).
- O12. The encrypted ballots of intent-lang S9, ported for the verdict.
  CLOSED (S6): Q-S6-2 (a).
- O13. `ecrecover` comes with the port and has no use. Kept (section 16).
- O14. The poll id of a dispute ballot: the dispute id, not poll 0. Kept:
  the cast entries take the poll of the dispute (section 13).
- O15. `claim` needs `u256Mul` and `u256Div`. Built (S7, section 14).
- O16. One member, one ballot (the ring and the key image), not token
  weight. The charter decides who is a member. Kept: Q6 (a).

## 10. Milestones

The milestones are the slices of docs/PLAN.md section 9.

| Slice | Content | Status |
|---|---|---|
| S0 | the seed from lang-template (tcc-evm-contract); the design; the plan; the kit gate | DONE |
| S1 | the USER rulings Q1 to Q10 | DONE |
| S2 | the port of intent-lang ef5abe8 | DONE |
| S3 | `Env.block` in the guest (O5); the `market` form (O4) | DONE |
| S4 | `Contest` in the domain; `Verdict`, `verdictAt`, `swap`; L3, L4, L6 | DONE |
| S5 | the position ledger, the freeze (L7), the masked ring (L8), the key image of each dispute (O10) | DONE |
| S6 | the encrypted dispute ballots over `Verdict`, L9, the threshold open, the majority; `Params` | DONE |
| S7 | the contract writer for the entries of section 13; NUMBER, CHAINID and ADDRESS; `u256Mul` and `u256Div`; the chain test | DONE |
| S8 | the mutants M1 to M8; this text, docs/VALIDATION.md, docs/STATUS.md; the close | DONE |

Status (2026-10-26): S0 to S8 are DONE. The plan of docs/PLAN.md is
CLOSED.

## 11. The market form

A kit program declares a market with one top-level form (O4, docs/PLAN.md
4.6). The clauses come in this order, one time each:

```
market M :=
  sources s1 ... sn
  outcomes L1 | ... | Lk
  deadline T
  rule T
  answers T
```

- `sources`: one or more names. Each source is a `U256`. A source can have
  any name (O9).
- `outcomes`: two or more labels.
- `deadline`: a `U256`, a block number (O5).
- `rule`: a term of the type `M.Reading -> M.Outcome`.
- `answers`: a term of the type of `M.answers` below.

The checker elaborates the form to text, as it elaborates a cofamily
(choice (ii) of section 2). It checks each generated declaration as a
program `def`, in this order:

| Name | Generated text |
|---|---|
| `M.Reading` | `def M.Reading : Type 0 := Prod U256 (Prod U256 ... U256)` (for n = 1, `U256`) |
| `M.si` | `def M.si : M.Reading -> U256`, the projection of source i |
| `M.Outcome` | `def M.Outcome : Type 0 := Sum Unit (Sum Unit ... Unit)` (k copies of `Unit`) |
| `M.Lj` | `def M.Lj : M.Outcome := inr^(j-1) (inl unit)` (for j = k, `inr^(k-1) unit`) |
| `M.deadline` | `def M.deadline : U256 := T` |
| `M.rule` | `def M.rule : M.Reading -> M.Outcome := T` |
| `M.answers` | `def M.answers : (o : M.Outcome) -> Sigma (r : M.Reading) (Path M.Outcome (M.rule r) o) := T` |

The form makes no reading constructor: a branch of `answers` writes
`pair`. The kernel has no eta rule for `Unit`, thus each branch does an
`elim` on its `Unit` field (`examples/market.lang`).

A market declaration generates ordinary definitions. The contract
program supplies the state and operations that use them. For
example, `examples/market.lang` passes `langc --kit check`; building it
gives `REFUSE_LOWER` because it has no state or `init`.

| Case | Code |
|---|---|
| no `answers` clause, a clause that is missing or out of order | `PARSE_EXPECT` |
| no source, or fewer than two outcomes | `PARSE_EXPECT` |
| a program `def` whose name has a `.` | `REFUSE_NAME` |
| a label or a source two times, or a label equal to a source or to a generated name | `REFUSE_NAME` |
| a `market` in a guest program | `REFUSE_KIT` |
| a `market` in `domain/domain.lang` | `REFUSE_DATA` |
| a missing branch | `TYPE_MISMATCH` (O8) |
| an outcome with no reading | `PATH_END` |

A diagnostic in a clause term gives the line in the generated text (the
source `market M`), not the line in the program.

## 12. Contest, Verdict and the laws

The domain declares the cell monad of a dispute (docs/PLAN.md 4.1, Q4
(a)):

```
family Contest (A : Type 0) := prop (propOf : A)
  | dispute (dA : Contest A) (dB : Contest A) (dGround : U256) (i : I) [ ~i -> dA, i -> dB ]
```

`prop p` is a proposal. `dispute dA dB g i` is a 1-cell from `dA` to `dB`
with the ground `g`. `Contest A` is a proposition, thus v1 has one
dispute round (O6). A dispute is not a path in `M.Outcome`: two different
outcomes have no path between them. A program defines the verdict
(`examples/contest-ends.lang`):

- `Verdict := Sum Unit Unit`, `left := inl unit` (the end `i0`) and
  `right := inr unit` (the end `i1`).
- `swap : Verdict -> Verdict` exchanges `left` and `right`.
- `verdictAt A x y d v` is the end of the dispute `d` at the verdict `v`.

| Law | Statement | Where it holds |
|---|---|---|
| L1 total | `rule M : Reading M -> Outcome M` | the type of `M.rule` (`examples/market.lang`) |
| L2 answer | `answers M o` for each `o` | `elim`, each branch `refl` (`examples/market.lang`) |
| L3 ends | `d @ i0 == prop p`, `d @ i1 == prop q` | by definition (`examples/contest-ends.lang`) |
| L4 verdict | `verdictAt d left == prop p`, `verdictAt d right == prop q` | `refl` (`examples/contest-ends.lang`) |
| L5 moot | if `rule M r == rule M s`, the contract refuses the dispute | the `challenge` guard (section 13) |
| L6 neutral | `verdictAt (sym d) (swap v) == verdictAt d v` | `elim` on `v`, `refl` (`examples/contest-neutral.lang`) |
| L7 freeze | `take` at `block >= deadline M` reverts | the `take` guard (`examples/ledger.lang`) |
| L8 eligible | a ballot verifies only over the masked ring of the dispute, with a fresh key image | the bLSAG verifier (`examples/ring.lang`) |
| L9 tally | `open q (tallyEnc bs) == count (map decrypt bs)` | a law-only def (`examples/tally.lang`) |
| L10 privacy | only the tally opens; `observe = \|_\| . decrypt` | `test/check/tally-leak.lang` gives `REFUSE_LAW` |
| L11 DAO | the Lan unit, descent and uniqueness laws; the charter ratification | ported from intent-lang (`examples/dao.lang`) |

## 13. The contract

The reference program is `examples/resolvekit.lang`. Its `known`,
`deadlineOf` and `ruleOf` definitions explicitly encode a closed list of
two markets: market 0 (deadline block 10) and market 1 (deadline block
20). They copy the deadlines and rules of `examples/ledger.lang`; adding
a `market` declaration requires wiring its definitions into the contract
operations. The reference program has three members a0, a1 and a2, and
the asset at 0x...ee. `test/resolvekit.sh` runs its contract on an EVM chain
(docs/VALIDATION.md, the last section).

The state:

| Field | Type | Content |
|---|---|---|
| `used` | `Map U256 Flag` | the key images (one nullifier for each key image and poll) that cast a ballot |
| `pend` | `Map U256 U256` | the 8 ciphertext words of a ballot after `castSig` |
| `stage` | `Map U256 U256` | the steps of a ballot: the signature, then each slot proof |
| `tally` | `Map U256 U256` | for each poll: the 8 words of the encrypted tally, the number of casts, the result of the open |
| `book` | `Map U256 U256` | the stake of each member in each market, the stake on each outcome, the pool of each outcome and the total pool |
| `marks` | `Map U256 U256` | the fields 0 to 8 of each market (below) |
| `disputeWindow` | `U256` | the blocks for a challenge after a proposal (`Params`) |
| `voteWindow` | `U256` | the blocks for a vote after a challenge (`Params`) |

The fields of a market: 0 proposed, 1 the proposed outcome, 2 the last
challenge block, 3 the reading, 4 challenged, 5 the challenge outcome, 6
the last voting block, 7 finalized, 8 the final outcome.

Each entry first checks the domain: the hash of `chain` and `self` must be
the deployment id of the program (O10). Else the entry reverts.

| Entry | Reverts unless | Effect |
|---|---|---|
| `take m o x` | the market is known, `o` is an outcome, `block < deadline m` (L7) | the stake of the caller, its stake on `o`, the pool of `o` and the total pool grow by `x`; the contract pulls `x` of the asset from the caller |
| `propose m r` | the market is known, `block >= deadline m`, no proposal | fields 0 to 3: the outcome `rule m r`, the last challenge block `block + disputeWindow`, the reading `r`; event `Proposed` |
| `challenge m t` | a proposal, no challenge, `block <=` field 2, `rule m t` is not the proposed outcome (L5) | fields 4 to 6: the outcome `rule m t`, the last voting block `block + voteWindow`; the poll of the dispute opens; event `Disputed` |
| `castSig q I ... ` | the poll `q` is open, the key image `I` did not cast in `q`, the bLSAG signature over the ring of `q` verifies (L8) | keeps the 8 ciphertext words |
| `castSlot q I j ...` | `castSig` of `I` is done, `j` is 0 or 1, the one-hot proof of slot `j` verifies | marks slot `j` |
| `castSeal q I ...` | the poll is open, `I` did not cast, both slots are marked, the sum proof verifies (one vote) | marks `I` as used; adds the ballot to the encrypted tally; adds 1 to the casts; event `Voted` (the key image only) |
| `openTally q ... n` | the poll is shut, not opened, `n <= casts`, the threshold open of the `right` slot to `n` verifies (L9) | the result: pass if `n > casts - n`, else fail (a tie fails); a pass of poll 0 sets the proposed `Params` |
| `finalize m` | the market is known, a proposal, not finalized; with a challenge, the poll is opened; with no challenge, `block >` field 2 | fields 7 and 8: the final outcome is the challenge outcome if the poll passed, else the proposed outcome; event `Resolved` |
| `claim m` | the market is finalized, and `(stake * pool) / stake == pool` for the stake of the caller on the final outcome and the total pool (no wrap; a stake of 0 fails unless the pool is 0) | pays the caller its stake on the final outcome times the total pool over the pool of the final outcome; sets that stake to 0 (one claim) |

The exported views are:

| View | Result |
|---|---|
| `pollOpen q` | whether poll `q` accepts ballots at the current block |
| `pollShut q` | whether poll `q` is past its voting deadline |
| `stakeOf m a` | the stake of `a` in market `m` |
| `fieldOf m f` | field `f` of market `m` (0 to 8 above), including finalized status (7) and final outcome (8) |
| `pollWord q k` | word `k` of the tally of poll `q` |
| `windows` | `256 * disputeWindow + voteWindow` |

The polls: poll 0 is the DAO poll of the `Params` proposal, open up to
block 10. Poll `m + 1` is the dispute poll of market `m`, open from the
challenge up to field 6. The poll id of a dispute is `d = hash
(deployment, m)` (O14).

The ring of a poll has one slot for each member. Slot `i` is `K_i + t_d
G`, with `t_d = hash (1, d) mod r`, thus a key image is different in each
dispute (O10). In a dispute poll, the slot of a member with a stake in the
market is a NUMS point `N_i` with no known discrete log (the masked ring,
L8). The ring size does not change. The DAO poll has no mask.

A ballot is four calls through three entries: `castSig`, `castSlot` for
slot 0, `castSlot` for slot 1, then `castSeal`. One ballot has 43 words,
and a call has at most 22 (docs/PLAN.md 4.7). The ballot is exponential ElGamal over BN254 G1 with a one-hot proof
(section 2).

## 14. The Env fields and the U256 operations

| Name | Type | Contract | Slice |
|---|---|---|---|
| `block env` | `U256` | NUMBER (0x43) | S3 (guest), S7 (contract) |
| `chain env` | `U256` | CHAINID (0x46) | S7 |
| `self env` | `Addr` | ADDRESS (0x30) | S7 |
| `u256Mul x y` | `U256 -> U256 -> U256` | MUL: the product modulo 2^256 | S7 |
| `u256Div x y` | `U256 -> U256 -> U256` | DIV: `x / 0 = 0` | S7 |

A `langc run` call is `NOW BLOCK CALLER NAME ARGS...`. A run script gives
`chain` and `self` with one `env CHAIN SELF` line, before the first call.
The defaults are chain 0 and the address 0. `u256Mul` and `u256Div` do not
trap in `langc eval` or in the contract.

## 15. Non-goals

- A stake through another wallet, another venue or an off-chain hedge is
  outside the proof. The proof of L8 covers only the stake that the
  registered key of the member holds in the ledger of this market. The
  binding of a member to a key by the charter is the only defense
  (docs/PLAN.md 4.3).
- Token-weighted votes. Each member has one ballot (O16).

## 16. Limits

- O6: one dispute round. A dispute of a verdict (an escalation) is not in
  v1.
- The `Params` proposal: the proposed `Params` are constants of the
  program (`newDispute` and `newVote` in `examples/resolvekit.lang`), and a
  pass of poll 0 sets them. No entry proposes other values (Q-S7-5 (a),
  Q-S8-7 (a)).
- The size: the runtime of `examples/resolvekit.lang` is 24441 bytes. The
  EIP-170 limit is 24576 bytes, thus 135 bytes of room are left. The
  initcode is 24471 bytes (EIP-3860 limit 49152).
- O13: `ecrecover` comes with the port and has no use in resolve-lang.
