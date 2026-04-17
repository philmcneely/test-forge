# System Integration Map

This file is organisation-specific architecture context for the test-gen prompts.
Copy and customise it for your platform. Place this file in the directory where you
run the skill -- the skills will pick it up automatically via `.test-gen.json`
`extraContext`, or you can paste it manually when prompted.

---

Use the map below to identify which downstream systems are affected by the change being
tested. For any system in the call chain touched by the ticket, generate at least one
cross-system integration scenario in Sections 6, 7, and 12.

## Entry points (client apps -> platform)

* **Web App** and **Mobile App** -> API Gateway -> Orchestration Service
* Orchestration Service is the hub for all transaction and account flows
* **Admin Portal** -- internal staff operations
* **Partner API** -- third-party integrations

## Pre-transaction checks (Orchestration Service initiates before processing)

1. Orchestration Service -> Limits Service -- rate and volume checks
2. Orchestration Service -> Compliance Service -- KYC/AML checks
3. Orchestration Service -> Risk Engine -- risk scoring
4. Orchestration Service -> Pricing Service -- fee and rate quotes

## Transaction processing chain (once pre-checks pass)

1. Orchestration Service -> Transaction Service
2. Transaction Service -> Payment Gateway -- funds-in
3. Transaction Service -> Disbursement Service -- funds-out
4. Transaction Service -> Notification Service (async)
5. Transaction Service -> Audit Service (async) -- transaction history

## Supporting services (called during or after the main flow)

* **Auth Service** -- authentication/identity
* **Audit Service** -- transaction history, aggregated limits
* **Notification Service** -- email, SMS, push notifications
* **Settlement Service** -- final settlement (async)

---

## Cross-system testing triggers

If the ticket touches any of the following areas, flag integration tests for all
connected systems listed above:

* **Limit logic** -> also test aggregated limits, compliance limit checks
* **KYC / compliance** -> also test pre-transaction gate, risk scoring
* **Pricing / fees / rates** -> also test pre-transaction quote, confirm rates survive into processing
* **Transaction routing** -> also test payment gateway, disbursement, downstream async posts
* **History / reporting** -> also test audit async post, notification async post
* **Authentication** -> also test auth service integration
* **Shared backend changes** -> flag regression risk for ALL entry points
