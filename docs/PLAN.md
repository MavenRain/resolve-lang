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

At the S2 port (ef5abe8), intent-lang had not built its encrypted ballots.
It added `tallyEnc` and the tally law
`open q (tallyEnc bs) == count (map decrypt bs)` at 3df9d96 (its S9).
resolve-lang S6 s2 ports them for the dispute ballot (4.4, O12, Q-S6-2).

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

S4 (DONE, 2026-10-24): the probes accept this family as it is. The `U256`
field and the boundary pass the cell-signature check, and a variant with
`dispute (dA : A) ...` gives `REFUSE_CELL` (rule R1). The kernel has no
implicit arguments, so `verdictAt` takes the type and the two ends:
`verdictAt A x y d v`. `Verdict`, `left`, `right`, `swap` and `verdictAt`
are program `def`s, not domain names: a domain name is a core name (rule
R4), and `examples/formers.lang` defines `left` and `right`. S6 or S7
decides if they move into the domain.

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

S5 s1 probes (2026-10-24, ~/Documents/resolve-lang-work/S5-probes,
Q-S5-1 to Q-S5-3 OPEN). P1: a state `Map U256 U256` keyed by
`hash m (addrToU256 a)` holds the stakes of all markets; a `take` at a block
before the deadline adds to the stake, and a `take` at the deadline or after
it reverts (L7). P2: the slot of member `i` is `flagIf` of the stake test,
over two closed points; when member 1 has a stake, a ballot that member 1
signs over the unmasked ring reverts, and `zkSign` over the masked ring
traps, because the key of member 1 is not in it (L8). A second ballot with
the same key image reverts. P3: the test confirms the survey finding. The
key image of member 0 at poll 0 and at poll 1 is the same point.

The probes show that the form `I = x * Hp(K, poll)` is not necessary, and
that it costs more than the plan says. `H_p` in `front/blsag.c` reads only
the point. To bind the poll, the kernel must change `blsag.c`, the `zkHp`
and unroll code of `front/eval.c`, and the blsagtool and precompile rows.
The DAO writer keeps `pollId` in the state, so its verifier can then not
fold `H_p` at compile time, and needs a hash to curve on chain. Proposed
form (Q-S5-1 (a)), with no bLSAG kernel change: dispute `d` has the public tweak
`t_d = hash(tag, d) mod r`. The eligible slot of member `i` is
`K_i + t_d G`, and the member signs with the key `x_i + t_d mod r`. Then
`I_d = (x_i + t_d) * Hp(K_i + t_d G)`. In P3, member 0 gets two different
key images in disputes 0 and 1, and both ballots count. This tests two
indices within one deployment. The dispute id must also separate
deployments: for local market index `m`, use
`d = hash(deploymentDomain, m)`, where `deploymentDomain` binds the intended
chain and contract instance. Under the market-only form `d = m`, two
contracts' market 0 ballots by the same member have equal key images,
even with eligible sets `{K_0, K_1}` and `{K_0, K_2}`; their intersection
identifies `K_0`. A C probe against `front/blsag.c` reproduces two valid
signatures with equal images, and different images with the scoped form.
For distinct scoped ids, the working anonymity assumptions are DDH in G1
and random-oracle hashes, as for bLSAG; P3 is not a security proof.

The static route (Q-S5-2 (a)) requires the deployment domain before
compilation. The writer must bind that compiled domain to the actual chain
and contract instance, refusing execution at a different target, and the
wallet must check it before signing. A redeployment or another chain needs
a different domain and a new build. With that domain and the closed market
list, each `t_d`, each slot point and each `H_p` is a compile-time constant,
so the chain needs no hash to curve (no MODEXP). If the domain is known only
at runtime, that constant-folding claim does not apply; S7 then needs a
runtime hash-to-curve route or a separate precomputation design.
The NUMS point is `N_i = H_p((hash(tag', i) mod r) G)` (builder default):
nobody knows its discrete log if `H_p` is a random oracle. S7 must lower a
`zkVerify` whose slots are `flagIf c P Q` over closed points; the unroll
now needs a closed point in each slot (`zk_ring` in `front/eval.c`).

S5 s2 (2026-10-24): the USER ruled Q-S5-1 (a), Q-S5-2 (a) and Q-S5-3
(a), and `examples/ring.lang` builds that form. The deployment domain is
`hash(chainId, instance)`, a `def` fixed before compilation. The tweak
`t_d = hash(1, d) mod r` does the reduction in the guest: `modR` does five
steps of the subtraction of `r`, because `2^256 - 1 < 6 r`. `zkKey` takes
only a Nat, thus it cannot reduce a hash. The NUMS point is
`N_i = zkHp (ecMul g (modR (hash 2 i)))`. The charter lists the members
as pairs of an address and a key, in the order of the ring. A ballot
reverts in an unknown market and before the deadline of the market, and
the poll that the member signs is `d`. `dispute` is a domain constructor
(rule R4), thus the guest calls the dispute id `disputeOf`.

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

S6 s1 probes (2026-10-25, ~/Documents/resolve-lang-work/S6-probes,
Q-S6-1 to Q-S6-5 OPEN). intent-lang built its encrypted ballots after the
S2 port (3df9d96, its S9): `examples/tally.lang` (guest),
`examples/ballot.lang` (kit) and `test/ballottool.c`. The probes use that
code over `Verdict`.

- P1 (kit, over `examples/ring.lang`): a ballot is two slot ciphertexts
  `(C1, C2) = (r G, b G + r PK)`, with `b` 0 or 1. The ring signature signs
  the digest of the 8 slot words in place of the clear choice. The
  signature verifies over the tweaked ring of the dispute `idA`, and its
  key image is the key image of the clear S5 ballot (the key image does
  not depend on the message). A changed slot fails the check, and the same
  signature fails at a different dispute id. The one-hot OR proofs and the
  sum proof need the host prover. intent-lang binds them to
  `ctx = hash(ballotTag, I, poll)` with poll 0; S6 s2 puts the dispute id
  `d` in place of the poll (Q-S6-2).
- P2 (guest): `tallyEnc` and `count` over `Hist = Verdict -> Size`,
  `lawTallyEnc` (L9) and `lawHist` check by `elim` on the size, as in
  intent-lang. A def that opens one ballot with a `Size` codomain gives
  `REFUSE_LAW` (L10).
- P3 (kit): the slot sums of two ballots (one `right`, one `left`) open by
  the quorum {1, 2} of the shares `f(i) = 5 + 7 i`. `K = 2 D1 + (r - 1) D2`
  is `x C1`, and each slot opens to 1. A count of 2 does not open. The DLEQ
  proof for each share stays the host row of `threshold.lang`.
- P4 (guest and kit): `verdictOf h` is `right` only when the count of
  `right` is more than the count of `left`. The tie (1, 1) in the two
  orders and the empty tally keep `left`; (0, 2) and (1, 2) give `right`;
  (2, 1) gives `left`. Under `trunc1`, the opened tie of P2 gives `left`.
  `keptNone` (no ballot keeps the first proposal) holds by `refl`. On the
  chain the word form is `flagIf (u256Le r l) 0u 1u`.

S6 s2 (2026-10-25) builds P1 to P4 after the rulings Q-S6-1 to Q-S6-5
(a). The ballot `ctx` and the signature use the dispute id `disputeId`
(Q-S5-2 (a)) in place of poll 0. The ring is the tweaked ring `K_i + t G`
with `t = hash(1, d) mod r`, and the signing key is `k_i + t mod r`. The
eval row `imageGood` checks that the key image of the ballot of voter 0
equals the key image of `sigA` in `examples/ring.lang`. Thus the encrypted
ballot and the clear S5 ballot of one member in one dispute have one key
image, and the S5 check against a second ballot applies to the encrypted
ballot.

The opening checks `opens` and `openSum` require a count below the BN254
scalar order `r`. Without this bound, the curve equation also accepts
`n + r` for a count of `n`, which can change the word majority. Zero and
`r - 1` are canonical counts; `r` and larger counts are refused.

O11 (read on 2026-10-25: MavenRain/self-referential-dao a965183,
`README.md` and `DENOTATIONAL-DESIGN.md`). A DAO is in one of three UAT
regimes. Arrow-Impossibility: no anonymous aggregation exists.
Arrow-Debreu: the Lan is object-unique, so each configuration has one
verdict. Schelling-Ising: two object-distinct Lans give two verdicts at one
configuration. This regime needs an indiscrete target and cannot occur over
a discrete target (`DENOTATIONAL-DESIGN.md:58`). The verdict of
resolve-lang is `verdictOf : Hist -> Verdict`. It reads only the counts, so
it is constant on the orbits of the member order (anonymous), and an
aggregation exists. `Verdict` is a discrete type with two points, so the
Schelling-Ising regime cannot occur. The binary verdict is in the
Arrow-Debreu regime: each tally has one verdict. At a tie a neutral rule
has two verdicts; Q7 (a) keeps `left`, so `verdictOf` is not neutral at a
tie. At each other tally it is neutral (May). O11 is closed.

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

### 4.7 The contract (S7 s1 probes)

S7 s1 (2026-10-25) ran the probes P1 to P5 on a scratch tree from
`git archive HEAD` (`~/Documents/resolve-lang-work/S7-probes/run.sh` and
`run2.sh`). No source file changes.

Survey. The port has one contract writer, `src/front/writer.c` (orbit-lang
S9 B1). It writes the plain tally DAO of `examples/dao.lang` ("contracts:
2 written, 5 refused"). It has no market entry, no encrypted ballot and no
opening. After its S9 (3df9d96), intent-lang has one commit, 79e1898 (its
S10). S10 lowers `Env.block` to NUMBER, adds the `evm t8n` route for a step
at BLOCK more than 0, and adds `examples/daokit.lang`: a kit contract
written by hand from the host constants. `writer.c` does not change
(intent-lang Q-S10-3 (a)). The encrypted cast is four calls through three
entries: `castSig`, `castSlot` for slot 0, `castSlot` for slot 1, then
`castSeal`. Both slot proofs are required before sealing. One ballot has
43 words and a call has at most 22 (intent-lang O39). The encrypted tally
is 8 state words. `enact` opens the slot 0 tally with the quorum {1, 2}
and sets the window by
`decide`. This commit is the port source of S7 (Q-S7-2).

P1 (the entry names). In the kit mode, `def dispute` gives `REFUSE_NAME:
dispute is a domain constructor (rule R4)`. `take`, `propose`, `challenge`,
`contest`, `disputeEntry`, `ballot`, `openTally`, `finalize`, `claim`,
`params`, `setParams` and `decide` pass `langc --kit check` (Q-S7-1). In
the guest mode each one gives `REFUSE_KIT`, because `U256` is a kit item.
The contract is a kit file.

P2 (the masked ring). K4c lowers `zkVerify` only over a closed ring. These
give `REFUSE_LOWER: K4c does not lower zkVerify at a word position`: a ring
point from an argument, the ring from the state (the S5 `ballot` entry of
`examples/ring.lang`, removed in S7 s4), and a ring element `flagIf c P Q` over two closed
points. A `flagIf` between two closed rings lowers. The kit runtime of
`examples/ballot.lang` is 10511 bytes. With one more view over a second
closed ring it is 14000 bytes, thus one verifier instance is about 3.5 kB.
The masked ring of a market has 2^n closed rings for n members (each slot
is the tweaked key or the NUMS point), and each market has its own tweak.
With 3 members and 2 markets this is 16 instances, about 56 kB. The EIP-170
limit is 24576 bytes (Q-S7-3). The one-hot and sum proofs of
`examples/ballot.lang` already lower and verify on the chain (the S6
precompile rows). S7 s2 b2 (Q-S7-3 (a)) lowers a selected ring as one
verifier, not as 2^n closed rings. The forecast of 3.5 kB for one instance
is not the size of this verifier: one selected verifier over a ring of 3 is
about 5.9 kB (5857 bytes, the b2 note below).

P3 (the encrypted tally and the opening). The resolve-lang `langc` refuses
to build `examples/daokit.lang` of intent-lang. The `src/` diff of 79e1898
(`src/ir.h`, `src/lower.c`, `src/evm.c`, `src/asm.h`) applies to HEAD with
no fuzz. After it, `langc` builds, and daokit has a runtime of 16702 bytes,
the size of intent-lang S10. Thus the 8 tally words and the threshold
opening of `enact` with the quorum {1, 2} lower as they are. For a verdict,
the opening of the `right` slot gives r, then l = casts - r, and the
verdict is `flagIf (u256Le r l) 0u 1u` (Q-S6-3 (a)).

P4 (`Params`). daokit keeps one `window` word and one `proposal` word (an
`init` constant). `enact` sets `window` to `proposal` when yes is more than
no. The resolve-lang `Params` has two words, `disputeWindow` and
`voteWindow` (Q-S6-4 (a), Q-S7-5). The kit U256 operations are `u256Add`,
`u256Sub`, `u256Eq` and `u256Le`. There is no multiplication and no
division (O15, Q-S7-7). The kit `Env` has NOW and CALLER (and BLOCK after
the port). It has no chain id and no contract address (Q-S7-6).

P5 (the size of S7). With Q-S7-5 (a), the contract has 9 entries: `take`,
`propose`, `challenge`, `castSig`, `castSlot`, `castSeal`, `openTally`
(one opening for a dispute poll and for the DAO poll), `finalize` and
`claim`, and the views. The kit inlines a `def` at each use (P2: a second
call of `sigOk` adds its code again). Thus one entry holds the one verifier
and one entry holds the one opening. Forecast with Q-S7-3 (a) and Q-S7-5
(a): daokit (16702 bytes, one verifier and one opening) plus the market
entries (the kit `take` of `examples/ledger.lang` is 292 bytes), about 19
to 21 kB. This is a forecast, not a measurement. It counts a closed
verifier. A selected verifier over a ring of 3 is 5857 bytes and a closed
verifier over a ring of 3 is 3489 bytes (the b2 note below), thus the
forecast goes up by at least 2.4 kB, to about 21.4 to 23.4 kB. The size
row of the
contract decides, and a size over EIP-170 is a STOP. The compiler work
(NUMBER, the ring lowering, the `Env` fields, the U256 operations) and the
contract work are each about the size of intent-lang S10, thus S7 needs
three build sessions (Q-S7-4).

S7 s2 (2026-10-25): the USER ruled Q-S7-1 to Q-S7-8 (a) (section 11). Part
b1 is built. It is the port of intent-lang 79e1898: the `src/` diff
(`IR_ENV_BLOCK`; `env_op` emits NUMBER (0x43) for `block`), the t8n route
of `test/evmchain.sh` (a chain with `numbered=1` runs each step at BLOCK
more than 0 on `evm t8n` from the t8n key address), and the `blocks` chain
of `test/evm.sh`. `test/lower/env-block.lang` leaves the refusal list.
`test/run/blocks.script` runs at NOW 1 and BLOCK 42. The gate counters are
the S7 s1 counters except the lower line (16 refusals and 33 checks, were
17 and 34) and 44 evm steps (was 43). Parts b2 (the ring lowering of
Q-S7-3), b3 (the `Env` fields of Q-S7-6) and b4 (`u256Mul` and `u256Div`
of Q-S7-7) are the s2 resume. Two facts for b2: `zkVerify` gets its
verifier term in the evaluator (`zk_unroll` in `src/front/eval.c`), not in
`src/lower.c`. `blsag_hash_point` starts at counter 0 for each point, thus
each leaf `H_p` is a build constant, but the ring digest D folds the hash
over all ring points, thus with a selected ring D is a term of the selected
points.

S7 s2 b4 (2026-10-25): `u256Mul` and `u256Div` are kit operations
(Q-S7-7 (a)). `u256Mul` is EVM MUL (the product modulo 2^256) and
`u256Div` is EVM DIV (x / 0 = 0). Neither op traps. The evaluator uses
`u256_mul_wrap` and `u256_div_zero` (`src/front/u256.c`). The lowering maps
them to `IR_OP_WORD_MUL` and `IR_OP_WORD_DIV`, which emit MUL and DIV.
`test/check/pruned-op.lang` refuses `u256Min` now (it refused `u256Mul`).
The product can wrap, thus `claim` must check it: the product divided by
the stake must be the pool (Q-S7-7). Parts b2 and b3 are the next session
(S7 s2 resume 2).

S7 s2 b3 (2026-10-25): the kit `Env` has two new fields, `chain : U256`
and `self : Addr` (Q-S7-6 (a)). The lowering maps them to `IR_ENV_CHAIN`
and `IR_ENV_SELF`, which emit CHAINID (0x46) and ADDRESS (0x30). `langc
run` reads the two values from the env line `env CHAIN SELF` of a script.
This line comes one time, before the first call. Without it, the chain id
is 0u and the address is 0x0, thus the other scripts do not change.
`examples/chains.lang` (a kit file) has the eval rows, the entry `stamp`
and the entry `onlyAt`, which reverts on another chain id or another
address. `test/run/chains.script` runs it at chain 1 and at the receiver
address of `test/evmchain.sh`. `test/evm.sh` runs it on the chain, and
it refuses an env line that does not give these values. Part b2 (the ring
lowering of Q-S7-3) is the next session (S7 s2 resume 3).

S7 s2 b2 (2026-10-25): `zkVerify` lowers over a selected ring (Q-S7-3
(a)). A ring element is a closed point or a `flagIf` tree of closed points
with a stuck condition. In `src/front/eval.c`, `zk_split` gives a `flagIf`
tree of words for the point, and for `H_p` of each leaf (each leaf `H_p` is
a build constant). `zk_selected_terms` takes a closed list of 1 to
`BLSAG_RING_MAX` such elements. The digest D is the hash fold of
`blsag_digest` over the words (2n - 1 hash nodes). `zk_unroll` takes the
point words, the `H_p` words and D. When `zk_ring` fails with a stuck
result, `zk_verify` tries `zk_selected_terms`, and a list of n + 3 words
gives the unrolled verify for each poll id, choice and signature. A ring
point from an argument stays `REFUSE_LOWER`. The rows are the 2 `selected
ring` rows of `test/gate.sh` and `examples/zksel.lang` (section 8).

The size. p2-elem (the base of 10511 bytes and one view over a selected
ring of 3) has a runtime of 16368 bytes, thus one selected verifier over a
ring of 3 adds 5857 bytes. One closed verifier over a ring of 3 adds 3489
bytes (P2). For a ring of 2, `examples/zksel.lang` has 3228 runtime bytes
and `examples/zkcast.lang` has 2086. The bound of S7 s2 resume 3 (below
10511 + 3489 = 14000 bytes) was wrong: a selected verifier holds the full
verifier and the words of both points, thus it cannot be smaller than a
closed verifier. The row compares with p2-sel (17422 bytes: the same base
with two closed verifiers). The cause: `src/lower.c` has no memo for a word
term, thus D is lowered at each of its 2n - 1 uses (each c_i two times and
the last `u256Eq` one time: 5 uses for n = 3), each with 2 IFs and 5
KECCAK nodes. The point and `H_p` words add 4 IFs. A possible shrink (not
done): a memo in `src/lower.c` for a shared `flagIf` word value (as the
curve memo `memo_add`), or D as one `flagIf` over closed digests when one
element is selected. The S7 s3 contract has a masked ring of 3 members
with each slot selected: its size row decides, and a size over EIP-170 is
a STOP.

S7 s3a (2026-10-25): the size probe and the word memo (Q-S7-9 (a)). The
probe (`~/Documents/resolve-lang-work/S7-s3/s3a.py`) builds scratch kit
files in `$TMPDIR`, not in `examples/`. The ring of Q-S7-5 (a) has 3
members and 2 markets. Each slot is a `flagIf` tree over the poll q: at
poll 0 the key tweaked by the poll 0 id, at poll m + 1 the `flagIf` of the
stake test over the key tweaked by the dispute id and N_i. One entry
holds one `zkVerify` over this ring. Its poll id `pollId q` is a `flagIf`
over the argument q. The base without a verifier has 419 runtime bytes.

| Ring of the probe | Runtime before the memo | Runtime with the memo |
|---|---|---|
| closed: the 3 keys tweaked by the poll 0 id | 3744 | 3144 |
| selected by the poll only | 10093 | 4998 |
| selected by the poll and the stake tests, 2 markets | 19081 | 7566 |
| selected by the poll and the stake tests, 1 market | 12026 | 5551 |

Before the memo, the selected verifier added 18662 bytes, thus the
forecast was 16702 - 3325 + 18662 + 292 = 32331 bytes and more (the
daokit size, minus the closed verifier of the probe, plus the selected
verifier, plus `take`). This is over EIP-170. With 1 market it was 25276
bytes and more, also over. The USER ruled Q-S7-9 (a). `lower_if_value`
in `src/lower.c` now lowers one IF for each `flagIf` word value in an
entry, as the curve memo `memo_add`: a second use in the same block, or
in a block that runs after it, reads the local of the first IF. A use in
the other arm of an IF gets its own IF. Before the memo, each slot word
was lowered at each use of D and one time in the loop. With the memo,
the selected verifier adds 7147 bytes, and the forecast is 16702 - 3325
+ 7147 + 292 = 20816 bytes plus the other market entries. The closed
probe also gets smaller, because `pollId q` has more than one use. The
gate rows keep their bytes, except the `selected ring` line: p2-elem has
15478 runtime bytes (was 16368). `examples/zksel.lang` has 2691 runtime
bytes (was 3228). `examples/zkcast.lang` (2086) and `examples/ballot.lang`
(10511) do not change. The probe uses the poll 0 id `hash deployment
255u`. The contract (s3b) sets this id.

S7 s3b part 1 (2026-10-25): the contract `examples/resolvekit.lang` (a kit
file in `examples/kit.txt`). It has the 9 entries of P5 and 6 views:
`take`, `propose`, `challenge` (Q-S7-1 (a)), `castSig`, `castSlot`,
`castSeal`, `openTally`, `finalize` and `claim`, and the views `stakeOf`,
`fieldOf`, `pollWord`, `windows`, `pollOpen` and `pollShut`. Each entry
reverts when `domainOf (chain env) (self env)` is not `deployment`
(Q-S7-6 (a)). The deployment
is `domainOf 1u` and the receiver address of `test/evmchain.sh`. The
markets are 0 and 1, and `ruleOf` copies the rules of `examples/ledger.lang`
as words. The members are the host points p0, p1 and p2 of `build/ballottool
words`. These points are `zkKey i G` (the keys of `examples/ring.lang`
before the tweak), and the eval row `membersAreKeys` checks this. Poll 0 is
the DAO poll with the id `daoPoll = hash daoTag deployment`. The dispute of
market m is poll m + 1 with the id `hash deployment m`. The domain is in a
different position in the two forms, thus the poll 0 id is not a dispute
id. The tags are `tweakTag` 1u, `numsTag` 2u and `daoTag` 3u.

The size. The first draft had 29266 runtime bytes, more than EIP-170
(24576). The USER ruled "measure first", then "B + more keep" (Q-S7-10).
The probes are scratch files in `~/Documents/resolve-lang-work/S7-s3/`:

| Probe | Runtime bytes | Change |
|---|---|---|
| draft | 29266 | the first draft |
| trimA | 27815 | one `ecAdd` value for each tally point (`setAt`, the curve memo); the rule, the outcome and the pass test bound one time |
| B | 24553 | trimA and the `keep` idiom |
| C | 23348 | B without poll 0 |
| D | 22106 | B with one market |
| E | 21104 | C and D |
| F | 24706 | B and more `keep` sites in `claim` and `take` (larger) |
| G | 24511 | B without the test `u256Le q 2u` in `castSig` and `openTally` |

The contract starts from probe G. After the deadline snapshot fix below,
it has 24441 runtime bytes and 24471 initcode bytes, 135 bytes below
EIP-170. The entries of probe B: `castSig` 9156, `castSlot`
3670, `castSeal` 3905, `openTally` 3597, `claim` 745, `take` 814,
`challenge` 713, `finalize` 710, `propose` 573, the views 260 and the base
458.

The `keep` idiom. `keep env x = flagIf (u256Le 0u (block env)) x 0u` is an
IF whose test holds at each entry. The `flagIf` memo of Q-S7-9 (a) uses the
`Value` pointer as its key, thus the entry computes x one time, and each
other use reads the local. A word is one `Value` only when the entry binds
it one time through a helper parameter. Thus `castSigAt`, `slotN`,
`slotAt`, `sealN`, `sealAt` and `openAt` take the kept nullifier N or the
kept points as their first parameters, and they are not entries. A `keep`
costs one IF (about 25 bytes). It pays only for a word with 3 or more uses
or with a costly key (probe F).

The test `u256Le q 2u`. `pollOpen` and `pollShut` give `flagNo` for q of 3
or more: field 4 of market q - 1 is 1 only after `challenge`, `challenge`
needs a proposal, and `propose` needs `known m`. Thus probe G keeps the
semantics of probe B. The ballottool mode for the contract words is s3b
part 2, and the chain test and the size rows are s3c. If s3c must make the
contract larger than 24576 bytes, Q-S7-10 opens again.

Review fix (2026-10-25): proposals store their last challenge block in
field 2, and challenges store their last voting block in field 6. Each
deadline uses the DAO window at creation. Later DAO updates apply to new
proposals and challenges. Previously these fields held creation blocks,
and each deadline check added the current window. A pass of poll 0 could
therefore reopen a closed challenge or voting window, accept a challenge
after finalization, or postpone a tally opening. The 11 additional eval
rows cover both deadlines, finalization, and future use of updated windows.

S7 s3b part 2 (2026-10-25): `build/ballottool contract` prints the cast
and opening words of the contract, one `NAME 0x<word>` per line. It uses
the ids of the contract: deployment = hash(1, receiver), poll 0 =
hash(daoTag 3, deployment), poll 1 = hash(deployment, 0), and the tweak
t = hash(tweakTag 1, id) mod r of each poll. Poll 0 (prefix `q0`) has the
ring p_v + t0 G and the casts of voters 0, 1 and 2 (slots 1, 1, 0). Its
T1 opens to 2 of 3 casts (a pass). Member 1 has a stake in market 0, thus
poll 1 (prefix `q1`) has the ring p0 + t1 G, `nums 1`, p2 + t1 G and the
casts of voters 0 and 2 (slots 1, 0). Its T1 opens to 1 of 2 casts (a
tie). The opening `q1w1` has the cast of voter 0 only (1 of 1, a pass).
The no-arg run also prints "contract regressions: passed": each cast
verifies in its poll and not in the other poll, and each T1 opens to its
count. The 14 eval rows at the end of the contract file check the printed
words with the contract helpers. The runtime stays 24441 bytes, because
the eval definitions are not entries.

S7 s3c (2026-10-25): `test/resolvekit.sh` (the form of the intent-lang DAO
chain gate) deploys the contract and runs 62 chain steps. The size rows:
the runtime is 24441 bytes (EIP-170 limit 24576) and the initcode is 24471
bytes (EIP-3860 limit 49152), thus Q-S7-10 stays closed. A step at block 0
is `evm run`. A step at a block more than 0 is a t8n step, because
`Env.block` is NUMBER. Poll 0: the four-call casts of voters 0, 1 and 2. A
seal with no slot 1 proof reverts, and a second castSig after the seal
reverts. The T1 words of the tally equal the host sum. The opening at block
10 reverts. The opening at block 11 (2 of 3, a pass) sets the windows 8 and
6. Market 0: a1 stakes 7 on outcome 0 at block 0, with the `asmtool mock`
token at 0x..ee (mode 0). The proposal at block 12 stores 20 in field 2.
The L5 challenge and a challenge at block 21 revert. The challenge at block
13 stores 19 in field 6. Poll 1: a cast at block 20 reverts, and voters 0
and 2 cast at block 15. The opening `q1w1` reverts, because it is not the
tally. The tie `q1t1` at block 20 keeps the proposal (field 8 is 0). Then
finalize, and claim pays 7 to a1. A second claim reverts. `test/gate.sh`
runs the test and adds one failure on a nonzero exit.

S7 s4 (2026-10-26, Q-S7-8 (a)): `test/run/resolvekit.script` has 49 rows.
The poll 1 words of `ballottool contract` need the stake of a1 in market 0
(N_1 in slot 1), thus the layout changes. Market 1 has the payout rows of
the old script with the same numbers (deadline 20, `ruleOf 1 r` is 0 for r
at most 30). Market 0 and polls 0 and 1 have the tie row and the key image
rows. The windows are 5 and 5 (no opening of poll 0), thus field 2 is 15
and field 6 is 17. The same-outcome row (L5) was in the old script
(`challenge 0u 60u` after `propose 0u 50u`), and it stays. `test/evm.sh`
does not run this script: a t8n step is from the key address, and `take`
and `claim` need the mock token. The chain side of the two rows is
`test/resolvekit.sh`: L5 at `call revert challenge 13 0u 50u`, and the tie
at `openTally 20 q1t1` (field 8 is 0). `examples/ring.lang` has no clear
`ballot` and `count`, and its `State` has only `position`.
`test/run/ring.script` has the two `take` rows.

### 4.8 The S8 plan (S8 s1)

S8 s1 (2026-10-26): STEP 0 at the USER commit a75a059 (parent 149e8a3).
Its tree is 259e873c, the S7 s4 tree. The USER wrote a different message,
and the commit has no Signed-off-by line. The gate
(`~/Documents/resolve-lang-S8-step0-gate.log`) is EXIT 0, byte for byte
the S7 s4 log (120 lines). Docs only.

The S8 hits of section 11 are options that the USER did not take:
Q-S7-5 (c) (the DAO entry), Q-S7-7 (c) (`claim`) and poll 0 of Q-S7-10.
S7 built all three. The one S8 item from them is the `Params` proposal
entry: Q-S7-5 (a) keeps the proposed `Params` as an `init` constant
(Q-S8-7). The items of section 10 are RULED or kept. O6 (one round) and
O13 (ecrecover) go to the limits in STATUS and SPEC.

**Mutants.** One mutant for each law row of `examples/resolvekit.lang`.
A mutant of a `.lang` file needs no rebuild: `langc` reads the file at
each run. The gate rows are `test/run.sh` (the guest run of
`test/run/resolvekit.script` against `test/run/resolvekit.out`) and
`test/resolvekit.sh` (the EVM chain test). "Run row n" is the row with
the number n in the script. The rows below are predictions from the
source; s2 runs each mutant and records the rows that fail.

| Mutant | Law row | Site | Change | Rows that must fail |
|---|---|---|---|---|
| M1 | L5 the same outcome | `challenge`, line 218 | `u256Eq (ruleOf m t) (field s m 1u)` to `flagNo` | run rows 14 and 39 (revert to ok); chain `call revert challenge 13 0u 50u` |
| M2 | the tie (Q-S7-8 (a)) | `openAt`, line 289 | `u256Le n (u256Sub casts n)` to `u256Le (u256Add n 1u) (u256Sub casts n)` (a tie passes) | run row 31 (`pollWord 1u 9u`: 1 to 2), rows 33 and 34; chain `openTally 20 q1t1` (field 8) |
| M3 | the used key image | `castSigAt`, line 224 | `mapGet (used s) n` to `flagNo` | run row 24 (revert to ok); chain `call revert castSig 0 $(sig 0 0)` |
| M4 | field 2 (the last challenge block) | `challenge`, line 218 | `u256Le (block env) (field s m 2u)` to `u256Le (block env) (u256Add (field s m 2u) 1u)` | run row 42 (BLOCK 26 is field 2 + 1: revert to ok) |
| M5 | field 6 (the last voting block) | `pollOpen`, line 180 | `(field s (u256Sub q 1u) 6u)` to `(u256Add (field s (u256Sub q 1u) 6u) 1u)` | chain `call revert castSig 20 $(sig 1 0)` (BLOCK 20 is field 6 + 1); no run row casts after field 6 |
| M6 | the claim once | `claim`, line 321 | `withBook s (mapSet (book s) ... 0u)` to `s` | run rows 35 and 44 (the second claim: revert to ok); the chain second claim |
| M7 | L8 the masked ring | `mslot`, line 154 | `(nums i)` to `(tweaked (disputeOf m) p)` (no mask) | run rows 16 to 23 (ok to revert); the chain casts of poll 1 |
| M8 | the domain (O10, Q-S7-6 (a)) | `here`, line 160 | `u256Eq (domainOf (chain env) (self env)) deployment` to `u256Eq deployment deployment` | none (Q-S8-2) |

Notes on the table:

- M7: the fixtures kill M7, because `build/ballottool contract` signs
  over the masked ring of poll 1. No row casts as the staked member a1
  (Q-S8-3).
- M8: no gate row calls a contract entry with another chain id or
  another address. `test/run/chains.script` rows 2 and 3 check the `Env`
  fields on `onlyAt`, not on the contract. Thus M8 survives (Q-S8-2).
- A mutant changes the bytecode. A size row of `test/resolvekit.sh` that
  fails is not a kill: s2 reads the names of the rows that fail.
- The runner: save the unmutated input and first check that both runners
  pass. For each mutant, restrict the edit to the named definition,
  require exactly one replacement, and inspect the diff before running.
  In particular, M3's text also occurs in `sealN`, line 269: that guard
  must stay unchanged.
- For guest row evidence, also run `build/langc --kit run
  examples/resolvekit.lang test/run/resolvekit.script`, keeping its full
  stdout and stderr in files. Compare stdout with `test/run/resolvekit.out`
  using `diff -u`, and record the numbered calls whose results change.
  `test/run.sh` reports only the script that mismatches and removes its
  temporary output, so its FAIL lines cannot identify the run rows.
  A difference only in the final `state` line is not a law-row kill.
- Run `test/run.sh` and `test/resolvekit.sh` in the background, retain
  both full logs and exit statuses, and wait for both before restoring
  the saved input. Record the failing chain calls as well as the guest
  row differences. Verify `git diff --quiet -- examples/resolvekit.lang`
  after restoration. A mutant of `src/*.c` (Q-S8-4) needs `make -B`
  before its run and after restoration (make 3.81 compares mtimes to the
  second).

**The S8 s2 result (2026-10-26).** STEP 0 at the USER commit 3972f71
(tree 921bde73: the S8 s1 tree and the USER edit of the runner notes
above). The gate is EXIT 0, byte for byte the S8 s1 log. The runner
(`~/Documents/resolve-lang-work/S8-mutants.sh`) replaces the old text one
time, on the named line, in the named def. All eight mutants pass
`langc --kit check`: no mutant is bad. Run 1 used the S7 s4 rows. M1 to
M7 were KILLED, and M8 survived, as predicted. Then s2 added the new rows
(Q-S8-2 (a), Q-S8-3 (a), the two findings below). Run 2 (base, M7, M8) and
run 3 (M1 to M6) used the new rows. The chain steps in the table have the
numbers of the new rows (65 steps). "Run row n" is a row of
`test/run/resolvekit.script`, which did not change.

| Mutant | Predicted rows | Real run rows | Real chain steps that fail | Result |
|---|---|---|---|---|
| M1 | run rows 14, 39; the chain L5 challenge | 14 and 39 (revert to ok), as predicted; also 27, 28 (revert to ok) and 15, 30, 32, 41, 43, 45 (ok to revert); `resolvekit.a1.script` (it has row 14) | 34 (the L5 challenge: want revert, got ok), 36 (the challenge of 0: want ok, got revert) | KILLED |
| M2 | run rows 31, 33, 34; the chain field 8 | 31 (`pollWord 1u 9u`: 1u to 2u), 33 (field 8: 0u to 1u), 34 (claim: ok to revert), as predicted | 58 (pollWord: want 1, got 2), 62 (field 8: want 0, got 1), 64 (claim: want ok, got revert), the mock balance of a1 (want 7, got none) | KILLED |
| M3 | run row 24; the chain second castSig | 24 (revert to ok), as predicted; `resolvekit.a1.script` (it has row 24) | 6 (castSig: want revert, got ok) | KILLED |
| M4 | run row 42 | 42 (revert to ok), as predicted | 35 (the challenge after field 2: want revert, got ok), not predicted; then 36, 37 (field 2: want 13, got 1b), 39, 57, 58, 60, 61, 64 and the mock balance of a1 | KILLED |
| M5 | the chain castSig at BLOCK 20 | none, as predicted | 39 (castSig at field 6 + 1: want revert, got ok) | KILLED (chain only) |
| M6 | run rows 35, 44; the chain second claim | 35 and 44 (revert to ok), as predicted | 65 (the second claim: want revert, got ok) | KILLED |
| M7 | run rows 16 to 23; the chain casts of poll 1 | 16 to 23 (ok to revert), as predicted; also 26 and 31 (pollWord to 0u), 30, 32, 34 (ok to revert); row 25 of `resolvekit.a1.script` (revert to ok) | 40 to 47 (the casts of poll 1: want ok, got revert), 48 (the a1 castSig: want revert, got ok), then 49 to 53, 57, 58, 60, 61, 64 and the mock balance of a1 (20 FAIL lines) | KILLED |
| M8 | none (Q-S8-2) | run 1: none (M8 survived); run 2: row 1 of `resolvekit.chain.script` and of `resolvekit.self.script` (revert to ok) | run 1: none; run 2: 26 and 27 (the two domain takes: want revert, got ok), 29 (stakeOf: want 7, got 15), the mock balance of a1 (want 7, got 15) | KILLED by the new rows |

Notes on the result:

- Each mutant changes the size rows of `test/resolvekit.sh`. This is not
  a kill. Each guest diff with a changed `state` line also has a changed
  numbered row.
- M4: chain step 35 kills M4 directly. The 4.8 table did not predict it:
  the chain test has the row "a challenge after field 2" (4.7, s3c).
- M7: the a1 row kills M7 directly. Under M7, the fixture rows 16 to 23
  revert first, but row 25 of `resolvekit.a1.script` and chain step 48
  change from revert to ok. Thus the a1 row is a kill now and a guard for
  a future fixture.
- Finding 1: the run reader takes one `env` line, before the first call
  (`src/front/check.c`, line 5012). Thus a domain row cannot follow row
  49 of `resolvekit.script`. s2 added two one-row scripts:
  `test/run/resolvekit.chain.script` (env chain 2u, the receiver address)
  and `test/run/resolvekit.self.script` (env chain 1u, the address
  0x...c1). Row 1 of each is the take of run row 1 (`take 1u 0u 3u` at
  BLOCK 1u from 0x...bb). Each prints `1 take revert`. `test/run.sh` runs
  `examples/NAME.lang` for `test/run/NAME.TAG.script`.
- Finding 2: after row 49, poll 1 has its tally. An a1 cast there reverts
  for a different reason, and a new row changes the numbers of the rows
  after it. Thus `test/run/resolvekit.a1.script` is rows 1 to 24 of
  `resolvekit.script` and row 25: the a1 cast over the ring of poll 1
  with no mask (the words q1ab1 of `build/ballottool contract`) at BLOCK
  13u. It prints `25 castSig revert`. `resolvekit.script` and its `.out`
  do not change, and the row numbers of the 4.8 table stay.

**SPEC.md.** SPEC.md is the intent-lang text with the four name edits of
section 6. It has no word of the market, the dispute or the contract. The
SPEC items of this plan are the non-goal of 4.3 (a stake through another
wallet, venue or hedge is outside the proof) and the reference to SPEC
"choice (ii)" in 4.6 (the text elaboration). Q-S8-5 gives the form.

**docs/VALIDATION.md and docs/STATUS.md.** VALIDATION.md is the
intent-lang text. Its last section is the ring gas table that
`test/gate.sh` (line 232) cites, and it stays. It has no section for the
resolution contract (Q-S8-6). STATUS.md stops at S5: S8 adds the S6 items
(the encrypted dispute ballots, L9, L10, `Params`) and the S7 items (the
contract writer, NUMBER, CHAINID and ADDRESS, `u256Mul` and `u256Div`, the
contract, the chain test, the size rows), and the limits (O6, O13, the
`Params` init constant, 135 bytes of room under EIP-170).

**The S8 s3 result (2026-10-26).** STEP 0 at the USER commit 9fec6af
(tree b77d4b2b). The gate is EXIT 0, byte for byte the S8 s2 log. s3 wrote
SPEC.md sections 1 and 9 to 16 (Q-S8-5 (a)), the resolution section of
docs/VALIDATION.md after the ring gas table (Q-S8-6 (a)), the S6 to S8
items and the limits of docs/STATUS.md, and the status of README.md. No
file in `src/`, `test/` or `examples/` changes. The close gate is byte for
byte the STEP 0 log. The plan is CLOSED (S8 s3, 2026-10-26).

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
- `examples/contest-ends.lang` (L3, L4) and `examples/contest-neutral.lang`
  (L6, and `swap` is an involution): by `refl`. They are examples, because
  the gate checks a file that passes only under `examples/`.
  `test/check/contest-wrong-end.lang`: a wrong end gives `PATH_END`. Eval
  rows evaluate `verdictAt` at `left` and at `right`, and `swap`.
- The cell rows: a program cannot declare a family (`REFUSE_DATA`), so two
  fronttool `domain` rows (the family `Rival`) check that the `Contest`
  shape passes the cell-signature check and that a variant with
  `rivalPath (rivalA : A) ...` gives `REFUSE_CELL`.
- Run scripts with the block column: a `take` at the deadline reverts; a
  dispute with the same outcome is refused; a ballot from a member with a
  stake fails the ring check; a second ballot with the same key image is
  refused; a tie keeps the first proposal.
- Ring rows: the same member in two disputes gives two different key
  images (O10). Include two contracts with local market index 0 and
  eligible sets `{K_0, K_1}` and `{K_0, K_2}`: both signatures verify and
  their key images differ. Repeat across chains and redeployments. S7
  checks that a contract compiled for one deployment domain refuses a
  different chain or contract instance; the wallet rejects a domain
  mismatch before signing (4.3).
- As built (S5): `test/run/ledger.script`: a `take` at the deadline of
  each market reverts, and a `take` in an unknown market reverts.
  `test/run/ring.script`: a ballot before the deadline reverts; a ballot
  from member 1, who has a stake, fails the check over the masked ring; a
  second ballot with the same key image reverts; a `take` after the
  deadline reverts; one ballot in each of two disputes counts. The ring
  eval rows: member 0 signs in market 0 of deployments A (this contract,
  `{K_0, K_1}`), B (a different contract, `{K_0, K_2}`), C (a different
  chain) and D (a redeployment). Each signature verifies, and the key
  image in A differs from the key image in B, C and D. Member 0 has two
  key images in markets 0 and 1 of A. The market-only form `d = m` and
  the untweaked key each give the same key image (the leak). One row
  checks `modR` of the largest word. The rows of a dispute with the same
  outcome and of the tie are for S6 and S7.
- As built (S6): `examples/tally.lang` (guest): `tieLeft` and `tieRight`
  open the tie of two encrypted ballots to one vote each, and `tieVerdict`
  gives `left` under `trunc1`. `vTie`, `vTieR` (the tie in the two orders)
  and `v3L` give `left`; `vRR` and `v3` give `right` (P4). `kept` (a tie
  keeps the old `Params` (1, 2)), `taken` (the majority takes the new
  `Params` (2, 1)) and `takenVote` are the `decide` of Q-S6-4 (a).
  `test/check/tally-leak.lang`: a def that opens one ballot gives
  `REFUSE_LAW` (L10). `examples/ballot.lang` (kit): `ctxGood`,
  `slotBoundGood`, `slotBound1Good`, `sumBoundGood` and `sigGood` give 1;
  `slotCopied` and `sigTampered` give 0; `imageGood` gives 1 (4.4);
  `tallyOpenLeft` and `tallyOpenRight` give 1 (the quorum {1, 2});
  `verdictOpened` gives `1u` and `verdictTie` gives `0u`.
  `openZero` and `openLastScalar` give 1; `openOrder`, `openAlias` and
  `tallyOpenLeftAlias` give 0, including the full threshold opening with
  a claimed count of `r + 1` instead of 1.
  `test/precompile.sh`: 14 rows over the ballot views (the 9 rows of
  intent-lang with the new words, and the `verdict` view at (1, 2) and at
  (1, 1), plus the zero, `r` and `r + 1` opening cases).
  `test/ballottool.c` computes the words and checks them ("ballot
  regressions: passed"). The run rows of a dispute with the same outcome
  and of the tie are S7 (Q-S6-5 (a)).
- As built (S7 s2 b1): `test/run/blocks.script` runs on the t8n route of
  `test/evm.sh` at NUMBER 42 (one evm step), and the state gets 42u.
  `test/lower/env-block.lang` is not a refusal row now: `Env.block` lowers.
- As built (S7 s2 b4): `examples/words.lang` has 7 `refl` laws of
  `u256Mul` and `u256Div` (6 * 7 = 42, 2^64 * 2^64 = 2^128,
  2^255 * 2 = 0, max * max = 1, 7 / 2 = 3, 7 / 0 = 0,
  max / 2^128 = 2^128 - 1) and 6 eval rows (`wMulWrap` and `wDivZero`
  give `0u`; `mulWraps` at 2 and 1, `divGivesZero` at 0 and 2). An entry
  that gives U256 is not an entry for `langc eval` (`EVAL_ARGS`), thus the
  two entries give a Flag. `test/emittool.c` has 3 emit rows: `word-mul`,
  `word-div` and `word-div-zero` (9 / 0 gives 0, no trap).
- As built (S7 s2 b3): `examples/chains.lang` (kit) has 4 eval rows
  (`chainIs` at 1 and 2, `selfIs` at the receiver address and at 193).
  `test/run/chains.script` runs `stamp` and `onlyAt` with the env line
  `env 1u` and the receiver address (`test/run/chains.out`).
  `test/run.sh` has 3 `RUN_SCRIPT` rows: an env line with no address, a
  chain id that is not a word, and an env line after a call.
  `test/evm.sh` runs the script on the chain.
- As built (S7 s2 b2): `test/gate.sh` has the 2 `selected ring` rows.
  p2-elem (`examples/ballot.lang` and the view `p2View` over the ring
  element `flagIf (u256Eq sel 0u) (pair p0x p0y) (pair p1x p1y)`) builds
  below 17422 runtime bytes (16368 bytes). p2-arg (a ring point from an
  argument) gives `REFUSE_LOWER`. `examples/zksel.lang` (kit) is
  `examples/zkcast.lang` with the entry `cast` over the ring `selRing
  sel`: (p0, p1) at sel 0u, else (p2, p1). `okA` and `okB` give 1,
  `crossA` and `crossB` give 0, and `sigA` and `sigB` give the words.
  `test/precompile.sh` has 6 rows over the zksel contract: each signature
  reverts at the other sel and enters at its own sel, `count 1u` reads 2,
  and the used key image of A reverts.
- As built (S7 s3a): the `selected ring` line of `test/gate.sh` prints
  the p2-elem runtime with the `flagIf` word memo (15478 bytes, was
  16368). The row compares it with p2-sel (17422 bytes). Without the
  memo the line prints 16368 again, thus the line detects a removal of
  the memo.
- As built (S7 s3b part 1): `examples/resolvekit.lang` (kit) has 24 eval
  rows: `ruleIs` (the two rules at their bounds, 4 rows), `pollSame` (the
  poll 0 id and the two dispute ids are different, 4 rows), `knownIs` at 1
  and 2, `deadlineIs` of markets 0 and 1, and `membersAreKeys` (p0, p1 and
  p2 are `zkKey i G`), plus the 11 deadline snapshot regressions above.
  `test/run/resolvekit.script` covers the stake freeze, duplicate proposals,
  same-outcome challenges, finalization boundaries, proportional payouts
  (stakes 3 and 1 split a pool of 8 as 6 and 2), and repeated claims.
  The contract builds with 24441 runtime bytes and 24471 initcode bytes.
  The size rows are s3c.
- As built (S7 s3b part 2): `test/ballottool.c` has the mode `contract`
  (4.7) and the no-arg line "contract regressions: passed". The contract
  file has 14 more eval rows over the printed words: `castAt0` and
  `castAt1` (the ring signature of voter 0 in its poll), `cast0At1`,
  `cast1At0` and `cast1Unstaked` (a cast at the other poll, and a cast of
  poll 1 on the ring with no stake, give 0), `slotsAt0`, `sumAt0`,
  `slotsAt1` and `sumAt1` (the slot and sum proofs under `ctxOf`),
  `slotAtOther` (a slot proof under the ctx of the other poll gives 0),
  `openAt0`, `openAt1` and `openWin1` (the T1 openings), and `openAt0Off`
  (a wrong count gives 0).
- As built (S7 s3c): `test/resolvekit.sh` runs 62 chain steps on evm (4.7,
  the s3c note). It prints the size rows (runtime 24441 bytes, initcode
  24471 bytes) and a gas line that the gate does not check. The first run
  had no mock token: `take` reverted, and the rows of poll 1 failed (20
  failures). Thus the poll 1 rows detect a ring with no stake of a1.
- As built (S7 s4): `test/run/resolvekit.script` has 49 rows (4.7, the s4
  note). Market 0: a1 takes 7, and voter 0 casts in poll 0 at block 5.
  After the proposal of 50, a castSig of poll 1 (not open) and a castSig
  of poll 0 (after its end) revert. The L5 challenge of 60 reverts, and
  the challenge of 0 opens poll 1. Voters 0 and 2 cast in poll 1 at block
  13. A second castSig of voter 0 reverts, because its key image is used.
  Voter 0 has one key image in each poll (`pollWord 0u 8u` is 1 and
  `pollWord 1u 8u` is 2). An opening at block 17 and a finalize at block
  18 revert. The opening `w1` reverts, because it is not the tally. The
  tie `t1` keeps the proposal (`pollWord 1u 9u` is 1, field 8 is 0). claim
  pays 7 to a1 one time. Market 1: the payout rows of the old script
  (claims of 6 and 2, the L5 challenge of 10, finalize at block 26). The
  row "a ballot from a member with a stake fails the ring check" is not in
  the script: `ballottool contract` prints no poll 1 cast of voter 1. The
  eval rows `castAt1` and `cast1Unstaked` and the poll 1 rows of
  `test/resolvekit.sh` test the mask. `test/run/ring.script` has the two
  `take` rows of S5 (a take at block 5 counts, and a take at block 12
  reverts).
- As built (S8 s2): the kill rows of M7 and M8 (4.8, Q-S8-2 (a), Q-S8-3
  (a)). `test/ballottool.c`: poll 1 with no mask (`p[2]`), a regression
  (the ballot of a1 verifies over the ring with no mask and fails over
  the masked ring), and the words q1ab1 (the a1 cast over the ring with
  no mask). Three run scripts from the generator
  `~/Documents/resolve-lang-work/S8-s2-gen-runscript.sh`:
  `test/run/resolvekit.a1.script` (rows 1 to 24 of `resolvekit.script`,
  then `25 castSig revert`), `test/run/resolvekit.chain.script` and
  `test/run/resolvekit.self.script` (`1 take revert` on chain 2u, and at
  the address 0x...c1). `test/run.sh` runs `examples/NAME.lang` for
  `test/run/NAME.TAG.script`. `test/resolvekit.sh` has 65 chain steps
  (was 62): before the mock take of a1, a take on chain 2 and a take at
  the receiver 0x...c1 (both revert, and the config is restored), and
  after `cast 1 2 15`, the a1 castSig over the ring with no mask (revert).
  `make check` runs 13 run scripts (was 10).

## 9. Slices

| Slice | Content | Status |
|---|---|---|
| S0 | generate from lang-template (tcc-evm-contract); DESIGN verbatim; this plan; README; kit gate | DONE |
| S1 | USER rules Q1-Q10; this plan records the rulings | DONE |
| S2 | port intent-lang ef5abe8 (section 6); gate = the intent-lang S7 counters | DONE: `make -B check` EXIT 0 with the intent-lang S7 counters: 49 examples, 0 failed; 19 parse, 186 check and 22 kit-only refusals; 188 evals, 2 proves; contracts 2 written and 5 refused; rings 6 built and 2 refused; 28 guest and 14 host differential rows; 5 runs, 10 run refusals; 8 asmtool; 3 builds, 16 lower refusals, 33 build checks; 20 dispatch; 43 evm steps; 14 precompile rows and 143 steps; 13 mock rows; 15 diff rows; 24 emit regressions; the 13 "regressions: passed" lines; 0 failures. The log is byte for byte the intent-lang S7 log (section 6) |
| S3 | `Env.block` in the guest (O5); the `market` form (O4): `Reading`, `Outcome`, labels, `rule`, `answers`, `deadline`; rows of 4.2 | s1 DONE (2026-10-24): b1 `Env.block` (O5) is the intent-lang S8 b1 port, and `make -B check` EXIT 0 with the S2 counters except 50 examples (`blocks.lang`), 6 runs (`blocks.script`), 11 run refusals (a bad BLOCK), 17 lower refusals and 34 build checks (`env-block.lang`). The log is byte for byte the intent-lang S8 b1 log. The market design is 4.6. s2 DONE (2026-10-24): the market build after the USER rulings Q-S3-1 to Q-S3-5 (a) (section 1): the `market` keyword and `M.x` names in a program, `parse_market`, `check_market` (text elaboration), `examples/market.lang` (Rain and Heat), five check rows, one parse row, six eval rows and a fronttool `REFUSE_DATA` row. `make -B check` EXIT 0 with the s1 counters except 51 examples, 20 parse, 191 check and 23 kit-only refusals, and 194 evals. DONE |
| S4 | `Contest` in `domain/domain.lang`; `Verdict`, `verdictAt`, `swap`; L3, L4, L6; the cell rows | DONE (2026-10-24): `Contest` (4.1) in the domain; `Verdict`, `left`, `right`, `swap` and `verdictAt` as program `def`s (the S4 note of 4.1); `examples/contest-ends.lang` (L3, L4), `examples/contest-neutral.lang` (L6), `test/check/contest-wrong-end.lang` (`PATH_END`), two fronttool cell rows and four eval rows (section 8). `make -B check` EXIT 0 with the S3 counters except 53 examples, 192 check refusals and 198 evals. The domain change moves no other row. DONE |
| S5 | the position ledger, the freeze, the masked ring, the key image for each dispute (O10) | s1 DONE (2026-10-24): STEP 0 gate EXIT 0, byte for byte the S4 log; probes P1 to P3 (4.3); the tweak form of the key image replaces `Hp(K, poll)` (4.3), Q-S5-1 to Q-S5-3 OPEN; docs only. s2 DONE (2026-10-24): Q-S5-1 to Q-S5-3 RULED (a); `examples/ledger.lang` (L7), `examples/ring.lang` (L8, O10), two run scripts and 11 ring eval rows (section 8). `make -B check` EXIT 0 with the S4 counters except 55 examples, 209 evals and 8 runs. No blsagtool, precompile, host or DAO writer row moves. DONE |
| S6 | encrypted dispute ballots: one-hot `Enc` over `Verdict`, `tallyEnc`, L9, threshold open, majority; `Params` in the DAO | s1 DONE (2026-10-25): STEP 0 gate EXIT 0, byte for byte the S5 log; probes P1 to P4 (4.4); Q-S6-1 to Q-S6-5 OPEN; docs only. s2 DONE (2026-10-25): Q-S6-1 to Q-S6-5 RULED (a) (section 11); the port of intent-lang 3df9d96 (its S9) over `Verdict`: `examples/tally.lang` (guest, L9, `verdictOf`, `Params`), `examples/ballot.lang` (kit), `test/ballottool.c`, `test/check/tally-leak.lang` (L10), 28 eval rows and 14 precompile rows (section 8). The dispute id def is `disputeId`: `dispute` is a domain constructor, so a def with that name gives `REFUSE_NAME` (rule R4). `make -B check` EXIT 0 with the S5 counters except 57 examples, 193 check refusals, 237 evals, 157 precompile steps, and 14 "regressions: passed" lines (+ `ballot regressions: passed`). O11 and O12 CLOSED. DONE |
| S7 | the contract writer: the entries of section 7; `Env.block` lowered to NUMBER; chain rows | s1 DONE (2026-10-25): STEP 0 at the USER commit 251c1ca (tree 7bf06ac3: the S6 tree and the USER change of the canonical counts, 4.4); gate EXIT 0 with the S6 counters except 237 evals and 157 precompile steps (the USER rows); probes P1 to P5 (4.7); the port source is intent-lang 79e1898 (its S10); Q-S7-1 to Q-S7-8 OPEN; docs only. s2 b1 DONE (2026-10-25): STEP 0 at the USER commit 29eaec4 (tree 80268401: the S7 s1 tree and a USER edit of the cast to four calls); the USER ruled Q-S7-1 to Q-S7-8 (a); the NUMBER port and the t8n route of intent-lang 79e1898 (4.7); gate EXIT 0 with the S7 s1 counters except 16 lower refusals, 33 lower checks and 44 evm steps. s2 b4 DONE (2026-10-25): STEP 0 at the USER commit 4571e84 (tree 25ab7a0d), gate byte for byte the b1 log; `u256Mul` and `u256Div` (Q-S7-7 (a), 4.7); gate EXIT 0 with the b1 counters except 243 evals and 27 emit regressions. s2 b3 DONE (2026-10-25): STEP 0 at the USER commit c418e33, gate byte for byte the b4 log; `Env.chain` and `Env.self` (Q-S7-6 (a), 4.7); gate EXIT 0 with the b4 counters except 58 examples, 247 evals, 9 runs, 14 run refusals and 48 evm steps. s2 b2 DONE (2026-10-25): STEP 0 at the USER commit 476d44a (tree aac47ee8: the b3 tree and a USER edit of `docs/host/README.md`), gate byte for byte the b3 log; the selected ring (Q-S7-3 (a), 4.7); gate EXIT 0 with the b3 counters except 59 examples, 253 evals, 163 precompile steps and the new line "selected ring: 2 rows, p2-elem runtime 16368 bytes". s2 DONE. s3a DONE (2026-10-25): STEP 0 at the USER commit e52bce8 (tree 011db849), gate byte for byte the s2 log; the size probe (4.7): the ring of Q-S7-5 (a) made the contract about 32 kB, over EIP-170; the USER ruled Q-S7-9 (a), the `flagIf` word memo of `src/lower.c`; gate EXIT 0 with the s2 counters except the line "selected ring: 2 rows, p2-elem runtime 15478 bytes" (was 16368). s3b part 1 DONE (2026-10-25): STEP 0 at the USER commit 77cd038 (tree 98737acb); the contract `examples/resolvekit.lang` (probe G, 24511 runtime bytes, 4.7); Q-S7-10 RULED; gate EXIT 0 with the s3a counters except 60 examples and 266 evals. USER commit 510c137 (the deadline snapshot fix: 24441 runtime bytes, 277 evals, 10 runs). s3b part 2 DONE (2026-10-25): `build/ballottool contract` (the words of polls 0 and 1, 4.7); 14 eval rows; gate EXIT 0 with the counters of 510c137 except 291 evals and "contract regressions: passed". s3c DONE (2026-10-25): STEP 0 at the USER commit 8b89bdd (tree c459a05e); `test/resolvekit.sh` (62 chain steps, the size rows: runtime 24441, initcode 24471, 4.7); gate EXIT 0 with the counters of 8b89bdd plus the 3 resolvekit lines. s4 DONE (2026-10-26): STEP 0 at the USER commit 149e8a3 (tree e4775581); `test/run/resolvekit.script` (49 rows: the tie, the L5 and the key image rows, the new layout of 4.7); `examples/ring.lang` without its clear `ballot` and `count`, `test/run/ring.script` with the two `take` rows (Q-S7-8 (a)); gate EXIT 0, byte for byte the log of 149e8a3. S7 DONE. |
| S8 | mutants, SPEC, VALIDATION, close | s1 DONE (2026-10-26): STEP 0 at the USER commit a75a059 (tree 259e873c, the S7 s4 tree; the USER message, no Signed-off-by); gate EXIT 0, byte for byte the S7 s4 log; the mutant table M1 to M8 and the plan of SPEC, VALIDATION and STATUS (4.8); Q-S8-1 to Q-S8-7 RULED (a) (section 11); docs only. s2 DONE (2026-10-26): STEP 0 at the USER commit 3972f71 (tree 921bde73: the s1 tree and the USER edit of the runner notes of 4.8), gate byte for byte the s1 log; the mutant runs (4.8): M1 to M7 KILLED by the S7 s4 rows, M8 survived; the kill rows of Q-S8-2 (a) and Q-S8-3 (a) (`test/ballottool.c` poll 1 with no mask, `test/run/resolvekit.{a1,chain,self}.script`, 3 chain steps, `test/run.sh` NAME.TAG; section 8); with the new rows M1 to M8 are all KILLED; gate EXIT 0 with the s1 counters except 13 runs and 65 chain steps. s3 DONE (2026-10-26): STEP 0 at the USER commit 9fec6af (tree b77d4b2b), gate byte for byte the s2 log; SPEC.md sections 1 and 9 to 16 (Q-S8-5 (a)), the resolution section of docs/VALIDATION.md (Q-S8-6 (a)), the S6 to S8 items and the limits of docs/STATUS.md, README.md; docs only; the close gate byte for byte the STEP 0 log. S8 DONE. |

## 10. Open items

Each item is RULED (S1, 2026-10-24) or kept as the builder call.

At the close (S8 s3, 2026-10-26): O11 and O12 are CLOSED. O6 (one dispute
round) and O13 (`ecrecover` with no use) are limits of v1 (SPEC.md section
16, docs/STATUS.md). Each other item is RULED or kept, and the build
implements it.

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
  S5 s1: the probes give the key image of a tweaked key, with no bLSAG
  kernel change (4.3, Q-S5-1). It needs a deployment-scoped dispute id;
  no hash to curve on chain requires the static route of Q-S5-2 (a).
  S5 s2: Q-S5-1 and Q-S5-2 RULED (a), built in `examples/ring.lang`.
- O11 the UAT regime of a binary verdict (4.4). CLOSED (S6 s2): the
  Arrow-Debreu regime, one verdict for each tally (4.4).
- O12 intent-lang S9 built the encrypted ballots for its DAO at 3df9d96.
  resolve-lang S6 s2 ports them for the verdict (4.4, Q-S6-2). CLOSED
  (S6 s2): Q-S6-2 (a), ported.
- O13 ecrecover comes with the port and has no use. Keep it (no removal
  work) or remove it in S2. Kept: S2 keeps ecrecover (section 6).
- O14 the guest poll id is fixed to 0 (H:310). The dispute ballot needs a
  poll id for each dispute: a change of the signature. S6 s2: the kit
  ballot `ctx` and the signature use `disputeId` in place of poll 0
  (4.4). Kept: the `ballot` entry of S7 takes the dispute id.
- O15 `claim` needs division (stake times pool over winning pool). The kit
  U256 operations need a check in S5. Kept: Q8 (a) keeps `claim`.
  S7 s1 (4.7, P4): the kit has no `u256Mul` and no `u256Div`
  (Q-S7-7). S7 s2 b4 adds them (Q-S7-7 (a)); `claim` is S7 s3.
- O16 votes in few wallets: one member, one ballot (the ring and the key
  image), not token weight. The charter decides who is a member. Kept:
  Q6 (a) gives one ballot for each member.

## 11. Questions for the USER (S1, S3, S5, S6, S7, S8)

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
- Q-S5-1 the key image for each dispute (O10, probe P3). (a) The tweak:
  the slot of an eligible member is `K_i + t_d G` with
  `t_d = hash(tag, d) mod r`, and the member signs with `x_i + t_d mod r`,
  so `I_d = (x_i + t_d) * Hp(K_i + t_d G)`. Use the deployment-scoped
  `d` of Q-S5-2. No bLSAG kernel change; the existing DAO, blsagtool and
  precompile rows do not move. The working anonymity assumptions are DDH
  in G1 and random-oracle hashes, as for bLSAG. The wallet checks the
  deployment domain and adds `t_d` to the key. (b) The original 4.3 form
  `I = x * Hp(K, d)`: `H_p` in `front/blsag.c` reads the poll. It changes
  `blsag.c`, `front/eval.c` and their rows, and the DAO writer (with
  `pollId` in the state) then needs a hash to curve on chain (MODEXP 0x05),
  or a second pair of `zkSign` and `zkVerify` ops for disputes.
  RULED: (a).
- Q-S5-2 the dispute id. (a) A deployment-scoped market id:
  `d = hash(deploymentDomain, m)` for local market index `m`. The domain
  binds the intended chain and contract instance and is fixed before
  compilation; S7 enforces that target and the wallet checks it (4.3).
  Section 7 lets a market have one proposal and at most one dispute, and
  the markets are a closed list, so `t_d`, each slot point and each `H_p`
  are compile-time constants on this static route. A redeployment or
  another chain requires a different domain and a new build. Reusing only
  the local market index repeats key images across contracts. (b) A
  deployment-scoped dispute counter in the state, for more than one
  dispute in a market: each slot then needs `H_p` for each new dispute,
  on chain unless a separate precomputation design supplies it.
  RULED: (a).
- Q-S5-3 the binding of a member to an address. (a) The charter lists each
  member as a pair of an address and a BN254 key, in the member order of
  the ring; `Eligible M k` reads the stake of that address. (b) A member
  entry binds an address to a key with a Schnorr proof by the key; the
  binding is then state, and the DAO does not list addresses.
  RULED: (a).
- Q-S6-1 the place of `Verdict`, `left`, `right`, `swap` and `verdictAt`
  (the S4 note of 4.1). (a) They stay program `def`s. No domain change and
  no row moves. Each file that uses them keeps a copy (now
  `examples/contest-ends.lang` and `examples/contest-neutral.lang`; S6 s2
  adds the tally example, S7 the contract). (b) They move into
  `domain/domain.lang`. They are then core names (rule R4), so each guest
  `def` with one of these names gives `REFUSE_NAME`:
  `examples/formers.lang` must rename its `left` and `right`, and the two
  contest examples must drop their copies. S6 s2 must also probe that the
  domain accepts these `def`s. The domain change can move the fronttool
  domain rows and the check counters.
  RULED: (a).
- Q-S6-2 the source of the ballot code (4.4, P1 to P3). (a) Port
  intent-lang 3df9d96 (its S9): `examples/tally.lang` over `Verdict`,
  `examples/ballot.lang`, `test/ballottool.c`,
  `test/check/tally-leak.lang`, and its eval and precompile rows, with
  three changes: `Choice` becomes `Verdict`, the dispute id `d` of S5
  replaces poll 0 in the ballot `ctx` and in the signature, and the ring is
  the tweaked masked ring of `examples/ring.lang`. (b) Write the ballot
  from `examples/ring.lang`, `onehot.lang` and `threshold.lang`, and add a
  new host prover. That repeats the work of intent-lang S9.
  RULED: (a).
- Q-S6-3 the majority (4.4, P4). (a) `verdictOf h` is `right` only when
  the count of `right` is more than the count of `left`. A tie and the
  empty tally keep `left` (`i0`, the first proposal, Q7 (a)). On the
  chain: `flagIf (u256Le r l)` over the opened counts. (b) The same, and
  also a minimum count of ballots in `Params`: below it the first proposal
  stays. (b) adds a DAO decision.
  RULED: (a).
- Q-S6-4 `Params` (3.3). (a) `Params` is the pair `disputeWindow`,
  `voteWindow` (in blocks), with the `decide` of intent-lang: a pass takes
  the new `Params`, and a fail or a tie keeps the old. On the chain the two
  windows are state words that a DAO entry sets (the entry is S7).
  (b) One DAO decision for each window, each with the one-field `Params`
  of intent-lang. (b) has two polls for each change.
  RULED: (a).
- Q-S6-5 the scope of S6 s2. (a) S6 s2 builds the guest tally, the kit
  ballot views and their eval and precompile rows, as intent-lang S9 did.
  The `ballot` entry with the encrypted choice, the encrypted tally in the
  state and `openTally` are S7 (the contract writer, section 9), and the
  run rows of section 8 for the tie and for a dispute with the same
  outcome go with them. `examples/ring.lang` keeps its clear ballot until
  S7. (b) S6 s2 also replaces the clear `ballot` entry of
  `examples/ring.lang` with the encrypted one and adds `openTally` and the
  tie run row. (b) changes `test/run/ring.script` and its `.out`.
  RULED: (a).
- Q-S7-1 the entry name of `dispute M s` (4.7, P1). `dispute` is a domain
  constructor, thus a `def` with this name gives `REFUSE_NAME` (rule R4).
  (a) `challenge`. It is a short ABI name, and it does not repeat a domain
  name. Section 7 and the event `Disputed` keep the word "dispute".
  (b) `disputeEntry`, with the form of `disputeId` (S6).
  RULED: (a).
- Q-S7-2 the port source and the form of the contract (4.7, survey).
  (a) Port intent-lang 79e1898 (its S10): the NUMBER lowering (the `src/`
  diff applies to HEAD with no fuzz, P3), the `evm t8n` route of
  `test/evmchain.sh` and `test/evm.sh`, a `ballottool` mode for the
  contract constants, and a chain test with the form of `test/dao.sh`,
  including the four-call cast and refusal to seal with a missing slot
  proof. The contract is a kit file written by hand from the host constants
  (`examples/resolvekit.lang`). `src/front/writer.c` and its rows do not
  change. (b) `writer.c` gets an encrypted mode that writes the contract
  from the program. (b) has no source to port.
  RULED: (a).
- Q-S7-3 the masked ring in the contract (4.7, P2). K4c lowers `zkVerify`
  only over a closed ring, and one verifier is about 3.5 kB. With 2^n rings
  for each market, the contract is over EIP-170. (a) Extend the K4c
  lowering: a ring element can be a tree of `flagIf` over closed points.
  Each leaf is closed, thus each `H_p` is a build constant. The verifier
  selects the point and the `H_p` of each slot at run time, and there is
  one verifier. New lower rows (one that lowers, one that refuses a point
  from an argument) and precompile rows over a selected ring. (b) One
  contract for each market and 2 members (4 rings): about 16.7 - 3.5 + 14
  = 27 kB, also over EIP-170. (c) The contract ring has all tweaked keys
  and no mask, and L8 comes from another route. (c) changes the design
  (4.3).
  RULED: (a).
- Q-S7-4 the split of S7 (4.7, P5). (a) Three build sessions. s2: the
  compiler: the NUMBER port and the t8n route, the ring lowering of Q-S7-3,
  the `Env` fields of Q-S7-6 and the U256 operations of Q-S7-7, with their
  lower, eval, evm and precompile rows. s3: the contract
  `examples/resolvekit.lang`, the `ballottool` mode, the chain test and the
  size rows (over EIP-170: STOP and ask). s4: the run rows of section 8,
  the change of `examples/ring.lang` and `test/run/ring.script`, and the
  S7 close. (b) Two build sessions: s2 the compiler and the contract, s3
  the run rows. (b) puts about two times the work of intent-lang S10 in
  one session.
  RULED: (a).
- Q-S7-5 the `Params` DAO entry (4.7, P4). (a) The DAO poll is poll 0 of
  the same cast entries, and the dispute of market m is poll m + 1. The
  tally words, `casts` and the stage of a key image are maps keyed by the
  poll. The ring of poll 0 is the ring of the member keys tweaked by the
  poll 0 id, with no mask (with Q-S7-3 (a) the poll selects the leaves).
  `openTally 0` opens the DAO tally and sets `disputeWindow` and
  `voteWindow` by `decide`: a pass takes the new `Params`, a fail or a tie
  keeps the old. The proposed `Params` is an `init` constant, as in
  daokit. A proposal entry is not in S7. (b) A second contract for the
  DAO (the daokit port with two window words), and the market contract
  reads the windows by a view call. The kit has no view call to another
  contract. (c) The windows are build constants, and the DAO entry is S8.
  RULED: (a).
- Q-S7-6 the row "a contract for one deployment domain refuses another
  chain or contract instance" (section 8). The domain is a build constant
  (Q-S5-2 (a)), and the kit `Env` has no chain id and no contract address
  (4.7, P4). (a) Two new `Env` fields, lowered to CHAINID (0x46) and
  ADDRESS (0x30). Each entry reverts when `domainOf (chain env) (self
  env)` is not `deployment`. The run env gets the chain id and the
  contract address from a script header line, thus the other scripts do
  not change. Rows: a call with another chain id reverts, and a call to
  another contract address reverts. (b) No check at run time. The row is a
  ballot signed for another domain: the tweak is different, thus the ring
  check fails. A copy of the bytecode on another chain or at another
  address is not refused, and its key images repeat the key images of the
  first contract (a limit in the docs).
  RULED: (a).
- Q-S7-7 `claim` and U256 division (O15, 4.7, P4). The kit has no
  multiplication and no division. (a) Add `u256Mul` (EVM MUL, modulo
  2^256) and `u256Div` (EVM DIV, x / 0 = 0) as kit operations in the
  evaluator, the checker and the lowering, with eval and evm rows.
  `claim` pays floor(stake * pool / winPool), and it reverts when the
  product wraps (the check: the product divided by the stake is the pool).
  (b) `claim` pays back the stake only. (b) changes Q8 (a). (c) `claim` is
  S8.
  RULED: (a).
- Q-S7-8 the tie row, the same-outcome row and `examples/ring.lang`
  (section 8, Q-S6-5 (a)). (a) Both rows are in the run script of the
  contract (`test/run/resolvekit.script`, on the guest and on the EVM
  chain): a tie of the opened tally (1 left, 1 right) keeps the first
  proposal, and `challenge M s` with `rule M s == rule M r` reverts (L5).
  `examples/ring.lang` drops its clear `ballot` and `count`.
  `test/run/ring.script` keeps the `take` rows, the key image rows move to
  the run script of the contract, and `test/run/ring.out` changes.
  (b) `examples/ring.lang` and `test/run/ring.script` do not change. They
  stay the S5 guest reference of L8, and only the contract script gets the
  new rows.
  RULED: (a).
- Q-S7-9 the size of the selected verifier (4.7, the S7 s3a note). The
  ring of Q-S7-5 (a) for 3 members and 2 markets makes the contract about
  32 kB, over EIP-170. (a) A memo in `src/lower.c` for a shared word term,
  as the curve memo `memo_add`. All other build rows keep their bytes.
  (b) D as one `flagIf` over the closed ring digests (17 for 3 members and
  2 markets). Without a memo, D is still lowered at each of its uses:
  about 26 kB (an estimate). (c) Fewer markets: with 1 market the
  forecast is 25276 bytes and more, also over EIP-170.
  RULED: (a).
- Q-S7-10 the size of the contract (4.7, the S7 s3b note). The first draft
  has 29266 runtime bytes, more than EIP-170. The trims (one `ecAdd` value
  for each tally point, and one binding for each repeated word) give 27815
  bytes, also more. USER ruling 1: measure first (probes C, D and E:
  without poll 0, with one market, and both). USER ruling 2, with the probe
  numbers: "B + more keep", thus all S7 features stay with the `keep`
  idiom (probe B, 24553 bytes). More `keep` sites made it larger (probe F,
  24706 bytes), thus the base is probe B. Probe G removes two tests that
  have no effect (24511 bytes). If s3c must make the contract larger than
  24576 bytes, the question opens again with these options: poll 0 to S8
  (probe C, 1228 bytes of room), or a word memo in `src/lower.c` for a word
  that the kit inlines at more than one use.
  RULED: measure first, then probe B with the `keep` idiom (the USER,
  2026-10-25).

S8 s1 (2026-10-26) asks Q-S8-1 to Q-S8-7 (4.8). Each has a recommendation
(a). All seven are RULED (a) (the USER, 2026-10-26: "Take recommendations
for all").

- Q-S8-1 the split of S8 (4.8). (a) Two build sessions. s2: the mutant
  runs M1 to M8, the rows of Q-S8-2 and Q-S8-3, the runner in
  ~/Documents/resolve-lang-work, the results in 4.8 and section 8. s3:
  SPEC.md, docs/VALIDATION.md, docs/STATUS.md, README.md, the S8 row and
  the close gate. (b) Three build sessions: s2 the mutants, s3 the docs,
  s4 the close. (c) One build session for all of S8.
  RULED: (a).
- Q-S8-2 M8 survives (4.8): no gate row calls the contract from another
  domain. (a) Two revert rows on each side: a `take` with chain id 2, and
  a `take` at another contract address. The guest rows go in the run
  script (a second `env` line, or a second script: s2 checks what the run
  reader accepts). The chain rows go in `test/resolvekit.sh` (another
  chain id in the t8n env, and a copy of the runtime at another address).
  (b) The guest rows only. (c) No rows: STATUS records M8 as a survivor,
  and the `Env` rows of `test/run/chains.script` are the evidence.
  RULED: (a).
- Q-S8-3 the M7 kill (4.8). (a) A `ballottool` mode that signs as a1
  over the ring of poll 1 with no mask (slot 1 is the tweaked key of a1),
  and one revert row in the run script and one in the chain test. The
  contract ring has `nums 1` in slot 1, thus the ring check fails. With
  M7 the row is ok, thus the row kills M7 by the law and not by the
  fixtures. (b) The fixture kill is sufficient, and STATUS records it.
  RULED: (a).
- Q-S8-4 mutants of `src/*.c`. (a) None: the law rows are in the
  contract text, and the S7 lower, evm and precompile rows cover the
  lowering. (b) Two more: the CHAINID and ADDRESS opcodes, and the
  `u256Div` lowering (x / 0 = 0). Each needs `make -B`.
  RULED: (a).
- Q-S8-5 SPEC.md (4.8). (a) New sections for resolve-lang: the `market`
  form and its elaboration (4.6, "choice (ii)"); `Contest`, `Verdict` and
  the laws L1 to L11 (section 5); the contract entries and their state
  fields (section 7, 4.7); the `Env` fields `block`, `chain` and `self`,
  and `u256Mul` and `u256Div`; the non-goal of 4.3; the limits (O6, the
  `Params` init constant). Sections 1, 9 and 10 change to the resolve-lang
  purpose, open items and milestones. The intent-lang sections stay as the
  base language. (b) One short section with pointers to PLAN sections 4
  to 7.
  RULED: (a).
- Q-S8-6 docs/VALIDATION.md (4.8). (a) A new section for the resolution
  contract: the size rows (24441 runtime bytes, 24471 initcode bytes), the
  gas of each entry from the chain test (the `gasUsed` of each t8n step,
  printed by `test/resolvekit.sh`), the gate counters of S3 to S7 and the
  S8 mutant table. (b) Sizes, counters and mutants, no gas.
  RULED: (a).
- Q-S8-7 the `Params` proposal entry (Q-S7-5 (a): "A proposal entry is
  not in S7"). The contract has 135 bytes of room under EIP-170. (a) Not
  in v1: SPEC and STATUS record the `init` constant as a limit. (b) Build
  it in S8; if the contract goes over EIP-170, STOP and ask.
  RULED: (a).
