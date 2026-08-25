# Step 2 — Bounded contexts and the ubiquitous language

A **bounded context** is an explicit boundary within which one domain model applies and is strictly valid. Inside it, every term of the model has a single, unambiguous meaning.

A subdomain (problem space) does not map automatically to a bounded context (solution space). The goal of this step is to make that mapping deliberate rather than accidental.

## Key properties

- **Conceptual isolation** — the same real-world object can be represented by completely different models in different contexts.
- **Consistency frontier** — invariants and business rules inside the boundary are never contaminated by foreign concepts.
- **Organizational alignment (Conway's Law)** — system structure mirrors the communication structure of the organization. A bounded context should ideally be owned by exactly one cross-functional team.

Divergent models for the same real-world concept, in a freight platform:

| Context | Model of "cargo" |
| :--- | :--- |
| **Booking** | Commercial cargo: tracking id, route specification, tariff, issuing customer, booking status. |
| **Routing** | Transport unit / itinerary: legs, assigned vessel and voyage number, origin / transshipment / destination ports, stowage requirements. |
| **Handling** | Operational event record: type (receive / load / unload / customs), port location (UN/LOCODE), timestamp, responsible operator. |
| **Tracking** | Trackable delivery status: last known event, next estimated call, misdirected flag, consolidated customer-facing status. |

## Where to draw the line

1. Analyse polysemy and linguistic ambiguity across candidate aggregates.
2. Cut where a term changes meaning, or where business rules answer to different lifecycles and change cadences.
3. Write the formal ubiquitous-language glossary for each bounded context.

Decision questions:
- Why does this business make money? That is the core; the rest is support.
- Does this term mean the same thing to everyone who uses it? If not, there are two contexts.
- Can I change this context's model without coordinating with another team? If not, the boundary is in the wrong place.
- Which parts of the system have completely divergent change and scaling cycles?
- Where are the business's transactional consistency frontiers?

## Ubiquitous language

The ubiquitous language is the shared, rigorous vocabulary co-designed by domain experts and engineers, used in conversation, documentation, specifications, diagrams and — crucially — in the source code: class, method, event, and variable names.

Rules:
1. **No technical jargon in the core.** `DTO`, `Manager`, `Helper`, `Processor`, `Record` are not part of the ubiquitous language.
2. **Strict contextualization.** A term's meaning is scoped to its bounded context. "Customer" in Sales may be "a prospect with a score"; in Support it is "a user with an active contract".
3. **Continuous evolution.** When the business learns or changes a rule, the language and the code are refactored together.

The failure mode it replaces: domain expert says "freight settlement" → analyst translates → developer writes `executeFeeBatch()` → the table is called `TBL_TX_89`. Nobody can trace a rule back to the business. With a ubiquitous language the code reads `CargoHandlingPolicy.resolveFreightCharges()` and the event is `FreightChargesLiquidated`.

Audit the language in code review, not only performance and style: check that class and method names are linguistically faithful to the agreed business vocabulary.

## Organizational alignment

- Assign each bounded context to a single responsible team (Team Topologies: stream-aligned team). One team may own several contexts; a context must never be developed concurrently by several teams without explicit agreements.
- A core-domain context goes to a stream-aligned team; a generic subdomain is maintained by a platform team.
- Align **microservices to bounded contexts, not to entities**. A microservice should encapsulate a whole bounded context or a cohesive subset of one — never one service per table.
- Decide the internal architecture per context (modular monolith, microservice, hexagonal/clean architecture).

## Anti-patterns

**Big Ball of Mud** — no perceptible boundaries; every module knows the internals of the others, sharing data models and global schemas. Minor changes break unrelated areas. Fix: draw strict bounded contexts and isolate legacy behind an anticorruption layer; do not try to clean it all at once.

**Shared database integration** — several applications read and write the same tables. The schema becomes an implicit, ungoverned shared kernel and nobody can change a column safely. Fix: each context owns its persistence absolutely; integrate through APIs or asynchronous messaging.

**Enterprise domain model fallacy** — one universal corporate schema for the whole company (a `User` class with 200 fields used by 15 departments). Produces analysis paralysis and a model that serves nobody. Fix: accept the plurality of models through independent bounded contexts.

## Checklist

- [ ] Each bounded context has an explicit boundary and its own independent data model.
- [ ] Polysemy is eliminated: homonyms with different meanings live in different contexts.
- [ ] A ubiquitous-language glossary is formalized per context.
- [ ] Class, method, domain-event and table names strictly reflect the ubiquitous language with no artificial technical jargon.
- [ ] Each bounded context has exactly one owning team.
- [ ] No bounded context shares direct read/write database schemas with another.
