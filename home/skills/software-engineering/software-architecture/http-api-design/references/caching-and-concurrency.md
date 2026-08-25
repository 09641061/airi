# Step 5 — Cache-Control, ETag & If-Match optimistic concurrency

## 1. HTTP Caching Mechanics (RFC 9111)

HTTP caching allows browsers, edge CDNs, and reverse proxies to serve repeated read requests without querying origin database servers.

```mermaid
sequenceDiagram
    autonumber
    actor Client
    participant Proxy as CDN / Reverse Proxy
    participant Server as Origin API Server

    Note over Client,Server: Initial Request (Cache Miss)
    Client->>Server: GET /v1/products/prd-456
    Server-->>Client: 200 OK<br/>ETag: "w/33a-k98"<br/>Cache-Control: public, max-age=3600<br/>{ "id": "prd-456", "name": "Laptop", ... }

    Note over Client,Server: Subsequent Request (Conditional Validation)
    Client->>Proxy: GET /v1/products/prd-456<br/>If-None-Match: "w/33a-k98"
    Proxy->>Server: GET /v1/products/prd-456<br/>If-None-Match: "w/33a-k98"
    alt Resource Unmodified
        Server-->>Proxy: 304 Not Modified<br/>ETag: "w/33a-k98"
        Proxy-->>Client: 304 Not Modified (No body payload transferred)
    else Resource Modified
        Server-->>Client: 200 OK<br/>ETag: "w/44b-m12"<br/>{ "id": "prd-456", "name": "Laptop Pro", ... }
    end
```

### Cache-Control Directives
Configure `Cache-Control` explicitly on **every** response:
* **Private / Sensitive / Dynamic data**:
  `Cache-Control: private, no-cache, no-store, must-revalidate`
* **Public / Cacheable data**:
  `Cache-Control: public, max-age=300, stale-while-revalidate=60`
* **Immutable static assets**:
  `Cache-Control: public, max-age=31536000, immutable`

---

## 2. Optimistic Concurrency with ETag and If-Match

The **lost-update problem** occurs when two clients read the same resource simultaneously and overwrite each other's changes. HTTP solves this natively without pessimistic database locks.

```mermaid
sequenceDiagram
    autonumber
    actor Alice
    actor Bob
    participant Server as API Server

    Alice->>Server: GET /v1/accounts/10
    Server-->>Alice: 200 OK (ETag: "v1", balance: 100)

    Bob->>Server: GET /v1/accounts/10
    Server-->>Bob: 200 OK (ETag: "v1", balance: 100)

    Alice->>Server: PUT /v1/accounts/10 (If-Match: "v1", balance: 150)
    Server-->>Alice: 200 OK (ETag: "v2", balance: 150)

    Bob->>Server: PUT /v1/accounts/10 (If-Match: "v1", balance: 200)
    Server-->>Bob: 412 Precondition Failed (ETag mismatch: current server ETag is "v2")
```

### Concurrency Protocol Rules:
1. **Server ETag Generation**: Generate the `ETag` from the entity's monotonic version number or a SHA-256 hash of its representation state.
2. **Client Mutation**: The client transmits the current version in the `If-Match: "<ETag>"` header on `PUT`, `PATCH`, or `DELETE`.
3. **Precondition Enforcement**: If the incoming `If-Match` does not match the database version, abort the transaction immediately and return `412 Precondition Failed` (or `428 Precondition Required` if the header was omitted).

---

## 3. Dynamic Hypermedia Controls (HATEOAS)

When targeting Richardson Maturity Model Level 3, the representation contains embedded hypermedia links (`_links`) communicating legal, state-dependent actions:

```json
{
  "id": "ord-8812",
  "status": "APPROVED",
  "totalAmount": 250.00,
  "_links": {
    "self": { "href": "/v1/orders/ord-8812" },
    "payment": { "href": "/v1/orders/ord-8812/payment", "method": "POST" },
    "cancel": { "href": "/v1/orders/ord-8812/cancellation", "method": "POST" }
  }
}
```

* **State-Dependent Links**: If the order moves to `PAID`, the server removes the `payment` and `cancel` links and emits a `shipment` link instead.
* **Benefit**: Business workflow rules stay encapsulated on the server rather than hard-coded into client application logic.
