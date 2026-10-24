# resolve-lang domain design

> Paste the domain design below the line, verbatim. Do not edit it.

This file is the only source of the core types and the core operations of
resolve-lang. `SPEC.md` sections 5 and 6 cite its sections. Do not add a core
type or a core operation that this file does not give.

When the design changes, paste the new version. Then record the change as an
open item in `SPEC.md` section 9.

---

## The request (verbatim, 2026-10-24)

I want to write a programming language with the following features:

For type constructors and higher-kinded types, admit only the following: cell monads and their duals in a locally presentable locally cartesian closed \((\infty,1)\)-category, as represented computationally in Cubical Type Theory

For base types and operations, admit the minimum required to satify the following description:

[the pasted design below]

Finally, a ZK FHE MPC UAT-compliant self-referential DAO should govern, and the host language shall be TinyCC

## The pasted design (verbatim)

resolve-lang: prediction-market resolution

  - Activity: CNBC (Sept 30) questioned Kalshi and Polymarket trading volumes.
    New York and Polymarket are suing each other (Sept 28). Secondary sources
    report:
    - over 1,150 disputed Polymarket markets in the first half of 2026
    - nine wallets holding about half of the UMA token votes that settle
      Polymarket disputes
    - in a Wall Street Journal finding cited second-hand, about 20% of disputed
      outcomes involved voters who held stakes in the market
  - The language:
    - A market question is a typed term over named data sources and a deadline.
    - Every outcome needs a branch, so a question with no answer for some
      outcome doesn't type-check.
    - A dispute is a path between proposed outcomes.
    - To vote, a voter must give a ZK proof that they hold no position in that
      market.
    - An orbit-lang DAO governs the whole thing.
  - Fit: The same mechanism-design ground as sealed-lang and auction-lang.
