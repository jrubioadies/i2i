# i2i - Identity Architecture

## Purpose

Define an identity model for i2i that minimizes traceability, avoids classical authentication, and remains realistic for an MVP on iPhone.

## Design intent

The goal is not simply to avoid email/password or SIM dependency.
The goal is to create a system where:
- each device can participate without traditional account onboarding
- identities are lightweight and product-controlled
- users are not unnecessarily exposed to tracking or correlation
- the architecture can evolve toward stronger privacy if the product requires it

## Important distinction

“Not trackable” must be defined carefully.
It can mean several different things:

1. No phone number dependency.
2. No personal account dependency.
3. No persistent public identity visible to other users.
4. Reduced metadata exposure.
5. Reduced ability for third parties to correlate sessions.
6. Strong anonymity against network observers.

These are not equivalent.
A realistic MVP should target the first five where possible, and only move toward the sixth if the product truly needs it.

## Threat model for MVP

The MVP should try to reduce these risks:
- dependence on real-world personal identifiers
- easy correlation of a user across product interactions
- unnecessary exposure of device identity to peers
- excessive central storage of stable user identifiers

The MVP does not need, on day one, to solve:
- nation-state-level anonymity
- global network adversary resistance
- perfect deniability
- full decentralized trust architecture

## Why blockchain is not the right starting point

Blockchain may sound attractive for decentralized identity, but it is a poor first-layer choice here because:
- it adds major complexity before validating the core product
- it does not solve local pairing, transport, or good iPhone UX by itself
- it can increase metadata permanence instead of reducing traceability
- it can create architectural lock-in too early

Conclusion:
- blockchain is not selected for MVP identity.
- it may be revisited later only if a very specific decentralized trust requirement appears.

## Why onion-style routing is not the right starting point

Onion routing is a network privacy strategy, not a substitute for an identity architecture.
Starting there would be premature because:
- the immediate problem is pairing, identity, and device communication
- it increases implementation and debugging complexity substantially
- it is unnecessary if the MVP begins with local or nearby communication

Conclusion:
- onion-style routing is not selected for MVP.
- privacy-preserving relay strategies may be explored in later phases if remote communication becomes core.

## Recommended identity model for MVP

### Core principle

Use an app-generated device identity, not a personal identity.

### Identity elements

Each installation generates locally:
- a device-local cryptographic identity
- a private key stored securely on device
- a public identifier derived from that keypair
- an optional user-facing alias that is editable and non-authoritative

This gives the system:
- no SIM dependency
- no email dependency
- no mandatory personal registration
- device-based trust rather than account-based trust

## Pairing model

Pairing should be explicit and low-friction.

Recommended pairing options to evaluate:
- QR-based pairing
- short code pairing
- nearby discovery + user confirmation

Pairing should produce:
- a trusted peer relationship
- a stored peer record
- a minimal session trust model for future exchanges

## Anti-tracking principles

The MVP identity layer should follow these rules:

1. **No personal identifier by default**
   - no phone number
   - no email
   - no real name requirement

2. **No globally exposed permanent identifier unless necessary**
   - use internal identifiers
   - avoid showing stable raw identifiers to users when not needed

3. **Prefer rotating or context-bounded identifiers where possible**
   - if discovery needs a temporary identifier, it should be short-lived
   - avoid reusing the same discoverable token in every context

4. **Minimize metadata retention**
   - store only what is necessary for connection and continuity
   - avoid permanent logs of peer relationships unless product value requires them

5. **Separate product identity from transport identity**
   - the identity used for trust should not be tightly coupled to one transport layer

## Proposed architecture layers

### Layer 1. Local device identity
- generated at installation
- stored securely
- stable enough for trusted relationships

### Layer 2. Pairing identity
- used to establish a trusted relationship between devices
- can be mediated by QR, code, or proximity flow

### Layer 3. Session identity
- short-lived/session-scoped where appropriate
- can reduce linkability between interactions

### Layer 4. Future privacy enhancement layer
- optional relay privacy mechanisms
- optional identifier rotation strategy
- optional privacy-preserving routing strategy

## What we should build first

### Phase 1
- local key generation
- secure storage
- peer pairing model
- trusted peer list
- direct message exchange prototype

### Phase 2
- rotating discovery/session identifiers
- metadata minimization review
- relay-assisted communication if needed

### Phase 3
- advanced privacy routing only if justified by product need
- decentralized trust only if justified by product need

## Open architectural questions

1. Should one app install equal one identity, or should the user be able to create multiple personas?
2. Should paired peers persist forever unless manually deleted?
3. How should device reset/reinstall be handled?
4. Do we need recovery, or is identity intentionally disposable?
5. Is privacy more important than recoverability?

## Recommendation summary

For i2i, the best next-step identity strategy is:
- app-generated identity
- secure local key material
- explicit lightweight pairing
- no SIM dependency
- no classic authentication
- no blockchain in MVP
- no onion routing in MVP
- architecture prepared for stronger privacy later

## Practical conclusion

The product can still aim for strong privacy.
But the correct path is:
- first build a clean device-based identity model
- then reduce traceability with disciplined architecture choices
- then add stronger privacy layers only if the product truly needs them

That path is more realistic, more testable, and much more likely to produce a working system.
