# i2i - Viability Assessment

## Purpose

Evaluate realistic ways to establish communication between two iPhones:
- without SIM cards
- without traditional account/login flows
- with low user friction
- in a way that can later support a user interface and product iteration

## Problem statement

The original idea was to use IMEI as the unique identifier and establish communication between two iPhones from that starting point.

That approach is not suitable for a standard iPhone application environment, so the problem is reframed as:

> How can two iPhones discover each other, establish identity, and exchange data with minimal friction, without relying on SIM-based identity or classic user authentication?

## Constraints

### Product constraints

- No SIM dependency.
- Avoid classic authentication flows such as email/password, phone number verification, or mandatory account creation.
- User experience should be lightweight and easy to understand.
- The system should be able to evolve into a product with UI later.

### Technical constraints

- iOS limits access to hardware identifiers such as IMEI for normal apps.
- IMEI is not a transport mechanism and does not solve discovery or routing.
- iPhone-to-iPhone communication depends on approved iOS capabilities and network conditions.
- Any practical solution must define:
  - identity
  - discovery
  - transport
  - session establishment
  - permission model

## Discarded approach

### IMEI-based identity and communication

Status: discarded.

Why it fails:
1. IMEI is not practically available to ordinary iOS apps.
2. IMEI does not provide a communication channel.
3. IMEI does not solve discovery, pairing, or session management.
4. It creates a technically brittle foundation for a consumer product.

## Key design question

The real question is not “what hardware identifier can we use?” but:

> What lightweight identity and communication model can work natively on iPhone with minimal friction?

## Viable technical directions

### Option 1. App-generated identity + local/nearby communication

Concept:
- Each device generates its own internal identifier on first launch.
- Devices discover each other through proximity or local network methods.
- Pairing is user-driven but lightweight.

Pros:
- Does not depend on SIM.
- Does not require classical authentication.
- Fits well with privacy-first product design.
- Good candidate for MVP.

Cons:
- Discovery and usability depend on iOS capabilities and connection context.
- May be limited to local or nearby scenarios at first.

Assessment:
- Strong candidate for MVP.

### Option 2. App-generated identity + relay backend without classic login

Concept:
- Each device gets a generated app identity.
- A backend relay helps devices communicate beyond local proximity.
- No email/password login is required, but the system still manages device identities.

Pros:
- More flexible long term.
- Allows communication beyond the same local environment.
- Better product scalability.

Cons:
- More backend complexity.
- More design work around trust, pairing, abuse prevention, and recovery.
- Slightly less “purely local”.

Assessment:
- Strong candidate for phase 2, probably not the first MVP unless remote communication is essential from day one.

### Option 3. Pure local-network communication

Concept:
- Devices communicate only when on the same local network.
- Identity is app-generated, pairing is explicit.

Pros:
- Simple mental model.
- No public backend required initially.
- Easier to prototype.

Cons:
- Limited scope.
- Not enough if the product vision later requires remote communication.

Assessment:
- Good early prototype route if proximity/local-only is acceptable for the first iteration.

### Option 4. Nearby/offline-first communication model

Concept:
- Prioritize nearby discovery and direct communication between devices.
- Keep cloud dependency optional or absent in MVP.

Pros:
- Strong conceptual fit for “no SIM, low friction”.
- Differentiated product direction.

Cons:
- iOS capability limits need careful validation.
- May restrict scale and use cases.

Assessment:
- Worth exploring technically, especially if the product concept values immediacy and privacy.

## Recommended MVP direction

### Recommendation

Start with:

**App-generated identity + local/nearby communication + explicit lightweight pairing**

This is the best first-step architecture because it:
- respects the no-SIM requirement
- avoids classic authentication
- is realistic on iPhone
- lets us validate user value before building heavier backend systems

## Proposed MVP architecture

### Identity
- Generate a local device/app identifier on first launch.
- Store it securely on the device.
- Optionally attach a user-visible device name or alias.

### Pairing
- User initiates pairing between two devices.
- Pairing can be based on a short code, QR, or nearby discovery confirmation.
- No account creation required.

### Discovery
- First preference: local or nearby discovery.
- Fallback: manual pairing flow.

### Transport
- Start with local-capable communication paths.
- Keep transport abstraction clean so a relay can be added later.

### Session model
- Once paired, devices should recognize each other without re-authenticating in a traditional sense.
- Trust should be device-based, not account-based.

## Risks

### Technical risks
- Some desired iOS capabilities may be more constrained than expected.
- Background behavior may be limited.
- Discovery UX may be less smooth than imagined.

### Product risks
- “No authentication” can still hide implicit trust decisions that must be explained to users.
- Users may expect remote communication even if the MVP is local-first.
- Device loss/reinstall scenarios need future planning.

### Architecture risks
- If the MVP is too tied to one transport model, scaling later becomes painful.
- If identity is underspecified, future pairing and recovery become messy.

## Open questions

1. Must the first version work only when devices are nearby or on the same local environment?
2. Is remote communication required in the product vision, or only later?
3. Should pairing be invisible, QR-based, or short-code based?
4. Is privacy/local-first more important than reach?
5. What is the first concrete action users should perform once connected?

## Suggested next step before coding

Define a short technical decision memo covering:
- target MVP scope
- chosen discovery method
- chosen pairing method
- chosen transport abstraction
- what “connected” means in v1

## Suggested coding phase after this document

Once validated, start coding in this order:
1. identity model
2. pairing flow
3. discovery/proximity experiment
4. message exchange prototype
5. minimal UI shell

## Current recommendation summary

- Discard IMEI.
- Use app-generated identity.
- Start with local/nearby communication.
- Keep pairing lightweight and explicit.
- Build MVP first, then expand toward relay/remote communication if needed.
