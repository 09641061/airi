# Step 3 — Context mapping: integration patterns between bounded contexts

A context map documents **how the models and the teams that maintain them relate**. It is not a deployment diagram: it describes power, dependency, and translation. Every relationship has an **upstream** (U — the supplier, whose changes propagate) and a **downstream** (D — the consumer, who absorbs them).

## Decision rule

1. Can I avoid integrating at all? → **Separate Ways**.
2. Do I control the upstream and do we share an objective? → **Partnership** or **Customer/Supplier**.
3. Is the upstream foreign, legacy, or low-quality? → **Anticorruption Layer**, always.
4. Is the upstream clean, stable, and does its model fit my domain? → **Conformist** is acceptable.
5. Am I the upstream with many consumers? → **Open Host Service + Published Language**.

## Comparison

| Pattern | Power dynamic | Coupling | Main use case | Main risk |
| :--- | :--- | :--- | :--- | :--- |
| **Shared Kernel** | Symmetric (mutual agreement) | Critical / very high | Tightly linked subdomains sharing key types or contracts. | Uncoordinated changes break several contexts at once. |
| **Partnership** | Symmetric (cooperation) | High (organizational) | Two teams that depend on each other to deliver a shared business goal. | Delivery blocks if one team slips. |
| **Customer/Supplier** | Asymmetric (negotiated) | Medium | The downstream can negotiate requirements and dates with the upstream. | Upstream delays when it does not prioritize the downstream. |
| **Conformist** | Asymmetric (subordinate) | High (foreign model dependency) | Downstream adopts the upstream model wholesale (immutable legacy, industry-standard API). | Upstream's technical debt and changes contaminate the downstream directly. |
| **Anticorruption Layer (ACL)** | Asymmetric (defensive) | Low (isolated by translation) | Downstream translates the foreign model into its own to keep it pure. | Translation code and runtime overhead. |
| **Open Host Service / Published Language** | Asymmetric (universal publisher) | Low | Upstream publishes an open, stable protocol (OpenAPI, JSON Schema, Protobuf) for many consumers. | Pressure from many consumers to change the published protocol. |
| **Separate Ways** | None | Zero | No software integration; duplication or manual processes are accepted. | Eventual data inconsistency if synchronization becomes necessary. |

## The patterns in detail

### Shared Kernel
Two or more contexts share a common subset of the domain model and source code (or database). Any change to the kernel requires absolute consensus and cross-team tests. Use with mature teams in the same time zone on tightly coupled subdomains where continuous translation is not worth its cost. Keep it minimal, or it degrades into a canonical enterprise model.

### Partnership
The teams owning two contexts coordinate planning and roadmaps; each team's success depends on the other's delivery. Justified only when neither can ship without the other — the coordination cost is high.

### Customer/Supplier
The upstream serves the downstream's requests. The downstream acts as a customer with a voice, negotiating priorities and dates inside the upstream's backlog. Typical for an internal central service supporting key operating units.

### Conformist
The downstream adopts the upstream's conceptual model and schema directly, with no translation. Happens when the supplier has no incentive to adapt. Acceptable only when the supplier's model is well designed, an undisputed industry standard, or when the ACL's cost outweighs its benefit. Choosing it out of laziness lets the foreign model colonize your core.

### Anticorruption Layer (ACL)
An intermediate architectural layer of adapters, facades, and translators that converts an external system's messages, schemas, and concepts into the consumer's native ubiquitous language. This is the default defense against legacy systems, third-party packages, and incompatible models. It costs code, and that is exactly the price of protecting your language.

Shape: `legacy raw data / RPC → integration facade → protocol adapter → domain translator → clean domain entities`. An ACL that only renames fields is an indirection layer with no value; it must translate semantics.

### Open Host Service (OHS) / Published Language (PL)
The upstream exposes a standardized, documented API (OHS) using a public, formal, versioned interchange format (PL: JSON Schema, XML, Protobuf), maintaining backward compatibility through stable contracts. Use for cross-cutting services with many simultaneous consumers.

### Separate Ways
A conscious decision not to integrate because integration cost is high, interaction is rare, or the models simply do not match. Each context solves the problem independently. Often the cheapest correct answer.

### Big Ball of Mud (anti-pattern)
No boundaries at all. Identify it, isolate anything new behind an ACL, and do not attempt to clean the whole thing at once.

## Context map matrix template

| Upstream (U) | Downstream (D) | Integration pattern | Protocol / mechanism | Justification |
| :--- | :--- | :--- | :--- | :--- |
| *[supplier context]* | *[consumer context]* | OHS/PL, ACL, Conformist, SK, ... | REST API / Kafka / gRPC / DB view | Why this coupling level was accepted. |

Guiding questions:
- Which team has more organizational influence over the contract?
- Does the upstream model contain complex structures or obsolete names that would contaminate the downstream code? Yes → **ACL**.
- Does the supplier serve many clients needing the same contract? Yes → **OHS / PL**.
- Can both teams release jointly and share repositories? Only then consider **Shared Kernel** — and cautiously.
- Which external or legacy systems threaten the cleanliness of our new model?
- Are we willing to pay for an ACL to protect the core's purity?

## Worked context map (freight platform)

1. **Booking ↔ Routing — Partnership.** Both are core. Changes in the routing algorithm immediately affect quoting and booking confirmation, so both teams coordinate delivery cycles and contracts.
2. **Handling → Tracking — Customer/Supplier with asynchronous events.** Handling emits `CargoHandled`, `CustomsCleared` whenever a container is scanned in port; Tracking consumes them to refresh delivery status without synchronous coupling to port systems.
3. **Routing → Handling — Customer/Supplier.** Routing publishes voyage specifications so terminal operators can validate the cargo is stowed on the right vessel.
4. **IAM → Booking / Handling / Tracking — OHS / Published Language.** IAM exposes standard OpenID Connect with JWTs consumed uniformly by every downstream context.
5. **Booking → Billing (legacy ERP) — Anticorruption Layer.** The ERP has a rigid relational schema and a SOAP API with obsolete fields. The ACL translates `BookingConfirmed` into ERP accounting transactions, keeping the Booking model pure.

## Relationship to other methodologies

- **Microservices** — a well-designed microservice is the technical materialization of a bounded context; DDD supplies the semantic justification for its boundaries.
- **Team Topologies** — a core bounded context maps to a stream-aligned team, a generic subdomain to a platform team; Customer/Supplier and Partnership model the team interaction modes (X-as-a-Service, Collaboration).
- **Hexagonal / Clean architecture** — strategic design defines the outer boundary of the context; hexagonal architecture organizes its interior, with the ACL and OHS living as adapters at the periphery.
- **BDD** — Gherkin specifications are written in the ubiquitous language discovered during strategic design.

## Checklist

- [ ] A current, graphical context map represents every bounded context in the system.
- [ ] Every relationship names its upstream and downstream explicitly.
- [ ] Every relationship carries a formal integration pattern.
- [ ] Protected consumers implement ACLs against legacy or uncooperative suppliers.
- [ ] The map names the owning teams, not just the systems.
- [ ] Integration happens exclusively through versioned public APIs (OHS/PL) or asynchronous event messaging.
- [ ] The context map is a living document in the architecture repository, reviewed on every integration change.
