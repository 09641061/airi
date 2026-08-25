# Step 7 — Worked example: enterprise loan management API

A complete, production-grade implementation of the API design standard demonstrating HAL representations, keyset pagination, RFC 9457 error details, optimistic concurrency, and a formal OpenAPI 3.1 specification.

## 1. Keyset-Paginated Collection Response (`GET /v1/loan-applications?limit=2`)

```http
HTTP/1.1 200 OK
Content-Type: application/json; charset=utf-8
Cache-Control: private, max-age=60

{
  "items": [
    {
      "id": "app-2026-9901",
      "customerId": "cus-44810",
      "requestedAmount": 25000.00,
      "currency": "USD",
      "status": "APPROVED",
      "createdAt": "2026-08-25T10:30:00Z",
      "_links": {
        "self": { "href": "/v1/loan-applications/app-2026-9901" },
        "disbursement": { "href": "/v1/loan-applications/app-2026-9901/disbursement" }
      }
    },
    {
      "id": "app-2026-9900",
      "customerId": "cus-31200",
      "requestedAmount": 15000.00,
      "currency": "USD",
      "status": "UNDER_REVIEW",
      "createdAt": "2026-08-25T10:15:00Z",
      "_links": {
        "self": { "href": "/v1/loan-applications/app-2026-9900" }
      }
    }
  ],
  "pagination": {
    "limit": 2,
    "nextCursor": "eyJpZCI6ImFwcC0yMDI2LTk5MDAiLCJjcmVhdGVkQXQiOiIyMDI2LTA4LTI1VDEwOjE1OjAwWiJ9",
    "hasMore": true
  }
}
```

---

## 2. Optimistic Mutation via JSON Merge Patch (`PATCH`)

**Request with conditional header:**
```http
PATCH /v1/loan-applications/app-2026-9901 HTTP/1.1
Host: api.bank.example.com
Authorization: Bearer eyJhbGciOiJIUzI1Ni...
If-Match: "w/e92a83f1c"
Content-Type: application/merge-patch+json
Accept: application/json

{
  "termMonths": 48
}
```

**Successful Response:**
```http
HTTP/1.1 200 OK
Content-Type: application/json; charset=utf-8
ETag: "w/f01b94e2d"
Cache-Control: private, max-age=120

{
  "id": "app-2026-9901",
  "customerId": "cus-44810",
  "requestedAmount": 25000.00,
  "currency": "USD",
  "termMonths": 48,
  "annualInterestRate": 0.152,
  "status": "APPROVED",
  "_links": {
    "self": { "href": "/v1/loan-applications/app-2026-9901" },
    "disbursement": { "href": "/v1/loan-applications/app-2026-9901/disbursement" }
  }
}
```

---

## 3. RFC 9457 Validation Error Response (`422 Unprocessable Content`)

```http
HTTP/1.1 422 Unprocessable Content
Content-Type: application/problem+json; charset=utf-8

{
  "type": "https://api.bank.example.com/errors/invalid-loan-parameters",
  "title": "Validation Error",
  "status": 422,
  "detail": "The requested loan configuration violates institutional risk policies.",
  "instance": "/v1/loan-applications/app-2026-9901",
  "invalid-params": [
    {
      "name": "termMonths",
      "reason": "termMonths must not exceed 72 for unsecured personal loans."
    }
  ]
}
```

---

## 4. OpenAPI 3.1.0 Formal Contract

```yaml
openapi: 3.1.0
info:
  title: Loan Management Service API
  version: 1.0.0
  description: Enterprise HTTP API adhering to RFC 9110, RFC 9457, and OpenAPI 3.1 standards.
paths:
  /v1/loan-applications:
    post:
      summary: Submit a new loan application
      operationId: createLoanApplication
      parameters:
        - name: Idempotency-Key
          in: header
          required: false
          schema:
            type: string
            format: uuid
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/CreateLoanApplicationRequest'
      responses:
        '201':
          description: Application successfully created.
          headers:
            Location:
              description: URI of newly created resource.
              schema:
                type: string
                example: /v1/loan-applications/app-2026-9901
            ETag:
              description: Version hash for optimistic concurrency.
              schema:
                type: string
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/LoanApplicationResponse'
        '422':
          description: Validation error.
          content:
            application/problem+json:
              schema:
                $ref: '#/components/schemas/ProblemDetails'

  /v1/loan-applications/{id}:
    get:
      summary: Retrieve a loan application by ID
      operationId: getLoanApplicationById
      parameters:
        - name: id
          in: path
          required: true
          schema:
            type: string
        - name: If-None-Match
          in: header
          required: false
          schema:
            type: string
      responses:
        '200':
          description: Resource retrieved.
          headers:
            ETag:
              schema:
                type: string
            Cache-Control:
              schema:
                type: string
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/LoanApplicationResponse'
        '304':
          description: Not Modified. Cache is fresh.
        '404':
          description: Resource not found.
          content:
            application/problem+json:
              schema:
                $ref: '#/components/schemas/ProblemDetails'

    patch:
      summary: Partially update a loan application
      operationId: patchLoanApplication
      parameters:
        - name: id
          in: path
          required: true
          schema:
            type: string
        - name: If-Match
          in: header
          required: true
          schema:
            type: string
      requestBody:
        required: true
        content:
          application/merge-patch+json:
            schema:
              $ref: '#/components/schemas/PatchLoanApplicationRequest'
      responses:
        '200':
          description: Resource updated.
          headers:
            ETag:
              schema:
                type: string
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/LoanApplicationResponse'
        '412':
          description: Precondition Failed (ETag mismatch).
          content:
            application/problem+json:
              schema:
                $ref: '#/components/schemas/ProblemDetails'

components:
  schemas:
    CreateLoanApplicationRequest:
      type: object
      required: [customerId, requestedAmount, currency, termMonths]
      properties:
        customerId:
          type: string
        requestedAmount:
          type: number
          minimum: 1000.00
        currency:
          type: string
          enum: [USD, EUR]
        termMonths:
          type: integer
          minimum: 6
          maximum: 72

    PatchLoanApplicationRequest:
      type: object
      properties:
        requestedAmount:
          type: number
          minimum: 1000.00
        termMonths:
          type: integer
          minimum: 6
          maximum: 72

    LoanApplicationResponse:
      type: object
      required: [id, customerId, requestedAmount, currency, termMonths, status, createdAt]
      properties:
        id:
          type: string
        customerId:
          type: string
        requestedAmount:
          type: number
        currency:
          type: string
        termMonths:
          type: integer
        annualInterestRate:
          type: number
        status:
          type: string
          enum: [DRAFT, UNDER_REVIEW, APPROVED, REJECTED, DISBURSED]
        createdAt:
          type: string
          format: date-time
        _links:
          type: object
          additionalProperties:
            type: object
            required: [href]
            properties:
              href:
                type: string

    ProblemDetails:
      type: object
      required: [type, title, status]
      properties:
        type:
          type: string
          format: uri
        title:
          type: string
        status:
          type: integer
        detail:
          type: string
        instance:
          type: string
          format: uri
        invalid-params:
          type: array
          items:
            type: object
            required: [name, reason]
            properties:
              name:
                type: string
              reason:
                type: string
```
