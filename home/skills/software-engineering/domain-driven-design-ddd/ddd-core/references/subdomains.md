# Step 1 — Domain discovery and subdomain classification

## Problem space vs. solution space

DDD keeps a rigorous separation between analysing the business and designing the architecture.

| Dimension | Problem space | Solution space |
| :--- | :--- | :--- |
| **Definition** | Analysis and understanding of the business reality: challenges, goals, competitive advantage. | Conceptual and engineering design of the software that solves the identified problems. |
| **Key artifacts** | Domain, business vision, subdomains (core / supporting / generic). | Bounded contexts, ubiquitous language, context maps, source code. |
| **Perspective** | What the business needs and why. | How software will structure and implement the required capabilities. |
| **Relationship** | Technology-independent; exists even with no software. | Depends on architectural decisions and organizational boundaries. |

Never discuss microservices, SQL vs. NoSQL, or Kubernetes before the subdomains are classified and the core domain identified.

## Discovery: EventStorming and Domain Storytelling

Run a collaborative workshop with domain experts, architects, and developers.

**EventStorming** — explore the domain along a timeline:
- Map every **domain event** (orange, past tense: `OrderPlaced`, `CargoBooked`, `CargoHandled`).
- Identify the **commands** (blue: `BookCargo`, `AssignRoute`) and **actors** (small yellow) that trigger them.
- Identify **policies / reactions** (purple: `When CargoBooked then CalculateRoute`).
- Mark friction, doubts, and semantic inconsistencies as **hotspots** (red).
- Cluster events and commands into candidate **aggregates / entities** (yellow).

**Domain Storytelling** — draw how human actors and systems collaborate by exchanging domain messages and documents; derive user stories and Given-When-Then scenarios straight from the recorded stories.

Repeat these workshops when a new business line arrives or a conceptual bottleneck appears — discovery is not a one-off phase.

## The three subdomain types

**Core domain**
- The activity that differentiates the company and creates direct competitive advantage.
- Complexity: high; the logic keeps changing with the market.
- Engineering strategy: build in-house with the strongest engineers, strict tactical DDD, rigorous testing.

**Supporting subdomain**
- Necessary and business-specific, but not a differentiator.
- Complexity: medium or low; known, stable rules.
- Engineering strategy: simplified in-house build, standard libraries, or outsourcing. Does not justify tactical over-engineering.

**Generic subdomain**
- Universal capability, identical in any industry (authentication, standard e-invoicing, payment gateways, payroll).
- Complexity: high in technical specification, standard in business rules.
- Engineering strategy: buy COTS/SaaS or adopt a consolidated open-source library.

Spending rich tactical design on a generic subdomain is the most expensive mistake in strategic design.

## Subdomain matrix template

| Subdomain | Type | Business justification | Complexity | Implementation strategy | Owning team |
| :--- | :--- | :--- | :--- | :--- | :--- |
| *[name]* | Core / Supporting / Generic | Does it create direct competitive advantage? | High / Medium / Low | Build / Buy (SaaS) / Outsource | *[team]* |

Guiding questions:
- **Type**: if a competitor had this exact component, would we lose customers? Yes → **core**. No, and it is an industry standard → **generic**. No, but it is specific to our operation → **supporting**.
- **Complexity**: do the rules change monthly because of internal commercial strategy (high), or are they fixed by law or technical standards (medium/low)?
- **Strategy**: is there a commercial cloud product that solves 80%+ of the problem? If yes and the subdomain is generic → **buy**.

## Worked classification (global freight platform)

| Subdomain | Classification | Justification | Complexity | Strategy |
| :--- | :--- | :--- | :--- | :--- |
| **Routing** (route/voyage optimization) | **Core** | Proprietary itinerary algorithms; the market differentiator. | Very high | In-house, advanced tactical DDD. |
| **Booking** | **Core** | Real-time quoting, route specification, destination changes, cancellation. | High | In-house, hexagonal architecture. |
| **Handling** (port operations, inspection) | **Supporting** | Recording physical operations and customs inspections along the route. | Medium | Simplified event-driven in-house build. |
| **Tracking** | **Supporting** | Consolidated, up-to-date cargo status for end customers. | Medium | In-house with optimized read views. |
| **Billing** | **Generic** | Standard invoicing, payments, accounting. | Medium | Integrate the commercial ERP. |
| **Identity & access (IAM)** | **Generic** | Authentication, authorization, MFA, SSO. | High (technical) | Specialized SaaS (Auth0 / Keycloak). |

## When DDD does not pay

- Simple, data-oriented CRUD systems with no complex business rules.
- Projects whose complexity is technical rather than business (compilers, drivers, graphics engines).
- Throwaway prototypes and quick proofs of concept.
- Organizations with no access to domain experts — without them the ubiquitous language cannot be built and DDD loses its effectiveness.

## Checklist

- [ ] Collaborative workshops (EventStorming or equivalent) were run with domain experts and engineers.
- [ ] Key business events are documented in chronological order.
- [ ] Conceptual conflict points (hotspots) were marked and resolved.
- [ ] Every subdomain is classified as core, supporting, or generic.
- [ ] The core domain is clearly identified and gets priority allocation of senior engineering.
- [ ] Generic subdomains use market solutions or standard libraries instead of bespoke development.
