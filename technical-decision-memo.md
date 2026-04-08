# i2i - Technical Decision Memo

## Status

Draft v1.

## Purpose

Capture the first concrete technical decisions for the i2i MVP so development can start with a clear direction.

## Product objective

Enable communication between two iPhones:
- without SIM cards
- without classic authentication flows
- with minimal friction
- with room to evolve into a product with a real user interface

## Decision summary

### Decision 1. IMEI is not part of the architecture

Decision:
- Do not use IMEI as identity, pairing key, or communication primitive.

Reason:
- It is not practical for normal iPhone apps.
- It does not solve discovery, pairing, or transport.

Impact:
- Identity must be generated and managed by the app.

### Decision 2. Identity will be app-generated and device-based

Decision:
- Each app installation generates its own identity locally.

Reason:
- It avoids SIM dependency.
- It avoids account onboarding.
- It gives a workable trust foundation for MVP.

Implementation direction:
- generate a local keypair
- store private material securely
- derive a stable internal device identity from the keypair
- allow a user-facing alias that is editable and not authoritative

Impact:
- trust is based on paired devices, not personal accounts

### Decision 3. MVP pairing will be explicit and lightweight

Decision:
- Devices must pair intentionally, but without a classic login flow.

Candidate mechanisms:
- QR pairing
- short code pairing
- nearby discovery plus explicit user confirmation

Current recommendation:
- design the pairing layer so it supports QR and manual short-code options

Reason:
- pairing should be understandable, testable, and safe
- invisible trust is harder to debug in early versions

Impact:
- paired peers become first-class product objects

### Decision 4. MVP communication will prioritize local/nearby capability

Decision:
- First implementation should assume local or nearby communication is acceptable.

Reason:
- it is the simplest realistic path on iPhone
- it reduces infrastructure complexity in the first version
- it allows product validation before introducing remote relays

Impact:
- MVP does not need remote communication from day one
- transport abstraction should remain modular so relay support can be added later

### Decision 5. Blockchain is excluded from MVP

Decision:
- Do not use blockchain for MVP identity or trust.

Reason:
- too much complexity too early
- poor fit for the immediate pairing and communication problem
- may increase traceability rather than reduce it depending on usage

Impact:
- revisit only if a future decentralized trust requirement becomes concrete

### Decision 6. Onion-style routing is excluded from MVP

Decision:
- Do not use onion-style routing in the first implementation.

Reason:
- it addresses a later-stage privacy problem, not the immediate product problem
- it would complicate transport and debugging too early
- unnecessary for a local-first MVP

Impact:
- privacy should be handled first through good identity and metadata design
- stronger network privacy can be evaluated later if needed

## MVP scope definition

### Included in MVP
- app-generated device identity
- secure local identity storage
- explicit pairing flow
- trusted peer persistence
- message exchange proof of concept
- minimal product shell for user interaction

### Excluded from MVP
- account system
- phone-number identity
- blockchain identity
- onion routing
- advanced remote relay network
- recovery system for lost identity unless later required

## Identity model

### Core model
Each installation has:
- local private key material
- local derived device identifier
- optional display alias
- peer trust records for paired devices

### Design principles
- no personal data required by default
- no mandatory global public identity
- avoid exposing stable raw identifiers unnecessarily
- prepare for future rotation of session or discovery identifiers

## Pairing model

### Working definition
A successful pair means:
- two devices have intentionally established trust
- each device stores the other as a trusted peer
- future sessions can use that trusted relationship without traditional re-authentication

### MVP pairing requirement
Must be:
- understandable by users
- explicit
- debuggable
- testable in development

## Transport model

### MVP transport requirement
Transport must support:
- direct message exchange between paired devices
- local/nearby-first use cases
- clean abstraction for future extension

### Constraint
Do not hard-wire product identity to one transport implementation.

## Privacy position for MVP

### What we aim to reduce now
- exposure of personal identity
- permanent visible identifiers
- unnecessary metadata retention
- friction caused by account onboarding

### What we are not solving yet
- strong anonymity against a global network observer
- censorship resistance
- decentralized trust governance
- irreversible anti-correlation guarantees

## Risks

### Technical risks
- nearby/local communication on iPhone may behave differently than expected in real conditions
- background execution constraints may affect product design
- pairing UX may need iteration

### Product risks
- users may expect remote communication sooner than planned
- lack of recovery may be acceptable for prototype but weak for production
- privacy expectations may exceed MVP guarantees

## Open questions to resolve during implementation

1. Which pairing path should be implemented first, QR or short code?
2. Should trusted peers be removable and re-pairable from settings in v1?
3. Is identity disposable on reinstall, or should continuity be preserved later?
4. What exact user action defines “communication works” for the first demo?
5. Is the first useful payload text-only, signaling-only, or richer?

## Immediate build order

1. identity generation and secure storage
2. local peer model
3. pairing flow
4. communication proof of concept
5. minimal user interface

## Final recommendation

Proceed with development using this path:
- app-generated identity
- local/nearby-first communication
- explicit lightweight pairing
- privacy by design at the identity and metadata layer
- defer blockchain and onion routing until there is a proven product reason
