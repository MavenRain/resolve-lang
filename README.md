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

- `design/DESIGN.md`: the request and the domain design, verbatim. It is the
  only source of the core types and the core operations.
- `docs/PLAN.md`: the rulings, the reading of the type-former ruling, the
  minimal base signature, the readings of the design on Cubical TT, the
  laws, the kernel route, the contract, the slices, the open items and the
  questions.
- `SPEC.md`: the specification. Fill each section.
- `formers/FORMERS.md`: the type formers. `formers/tcc-evm-contract.md` gives their
  status on the tcc-evm-contract host.
- `probe/CAPABILITY.md`: the host probe.
- `docs/STATUS.md` and `docs/VALIDATION.md`: the status and the gate results.
- `docs/host/README.md`: how to build and test the host kit, and how to
  replace the sample domain in `domain/`.
