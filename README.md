# resolve-lang

resolve-lang is a Cubical TT language for prediction-market resolution. A
market question is a typed term over named data sources and a deadline. A
question that has no answer for some outcome does not type-check. A dispute
is a path between proposed outcomes. A voter must give a zero-knowledge
proof that they hold no position in the market. A zero-knowledge,
homomorphically encrypted, multi-party self-referential DAO (the DAO of
MavenRain/orbit-lang) governs the protocol. The only type constructors are
cell monads and their duals. The host is TinyCC. The compiler writes EVM
bytecode.

resolve-lang comes from lang-template with the tcc-evm-contract host.

Status (2026-10-26): the slices S0 to S9 of `docs/PLAN.md` are DONE, and
the plan is CLOSED. The reference contract is `examples/resolvekit.lang`:
two markets, the dispute, the encrypted ballots over a masked ring, the
threshold open and the claim. `test/resolvekit.sh` runs it on an EVM chain
(geth `evm`).

The gate: `make -B check` builds the tools and runs `test/gate.sh` and the
other test scripts. `make check-clang` runs the strict C syntax check
only.

- `design/DESIGN.md`: the request and the domain design, verbatim. It is the
  only source of the core types and the core operations.
- `docs/PLAN.md`: the rulings, the reading of the type-former ruling, the
  minimal base signature, the readings of the design on Cubical TT, the
  laws, the kernel route, the contract, the slices, the open items and the
  questions.
- `SPEC.md`: the specification. Sections 2 to 8 are the base language of
  intent-lang. Sections 11 to 16 give the market form, `Contest` and the
  laws, the contract, the `Env` fields, the non-goals and the limits.
- `formers/FORMERS.md`: the type formers. `formers/tcc-evm-contract.md` gives their
  status on the tcc-evm-contract host.
- `probe/CAPABILITY.md`: the host probe.
- `docs/STATUS.md` and `docs/VALIDATION.md`: the status and the gate results.
- `docs/host/README.md`: how to build and test the host kit, and how to
  replace the sample domain in `domain/`.
