# i2i MVP Development

## Goal
Ship the first iPhone MVP proof of flow:
1. create a local device identity
2. pair two devices explicitly
3. exchange one minimal text message

This document turns the current decisions into a practical build order.

## Frozen decisions for this scaffold
- No IMEI anywhere in the architecture.
- No account system, phone number, blockchain, or onion routing in MVP.
- Identity is generated locally per app install.
- Pairing is explicit and lightweight.
- Communication is local/nearby-first.
- UI should stay minimal and debug-friendly.

## Suggested build order

### 1. Core models and protocols
Create the shared models and interfaces first so implementation can stay modular.
- `DeviceIdentity`
- `PeerRecord`
- `MessageEnvelope`
- `IdentityRepository`
- `PeerRepository`
- `PairingCoordinator`
- `TransportClient`

Outcome:
- the app structure is defined before transport or UI details grow

### 2. Identity foundation
Implement first-launch identity generation and secure persistence.
- generate local key material
- derive stable internal `deviceId`
- store private material securely
- expose editable display alias

Definition of done:
- reinstall aside, the same install keeps the same identity across relaunches

### 3. Trusted peer storage
Implement persistence for paired peers.
- add/list/remove peer records
- store pairing date and trust status
- keep peer display name separate from authoritative identity

Definition of done:
- a paired peer survives app restart

### 4. Pairing v1
Implement one clear pairing path first.
- primary recommendation: QR payload generation + QR import/scanning
- keep manual short code as a documented extension point
- persist trust only after explicit confirmation

Definition of done:
- device A can export pairing data and device B can import it to create a trusted peer record

### 5. Messaging v1
Implement the minimum communication contract.
- send one text payload to one trusted peer
- receive and render one text payload
- keep transport behind a protocol so it can change later

Definition of done:
- one paired device can send a message and the other can show it

### 6. Minimal UI shell
Add only the screens needed to prove the flow.
- home / identity summary
- pairing screen
- trusted peers list
- message test screen
- lightweight debug state / error display

Definition of done:
- a human tester can complete the end-to-end flow without developer-only steps

## First sprint tasks

### Sprint objective
Reach a repo state where implementation can start immediately without reopening architecture debates.

### Must do this sprint
- [ ] Confirm the scaffolded module boundaries in `src-structure.md`
- [ ] Define shared models for identity, peer, and message
- [ ] Define protocols for identity storage, peer storage, pairing, and transport
- [ ] Decide the initial QR payload fields and keep them minimal
- [ ] Decide where secure private key storage will live in iOS implementation
- [ ] Add placeholder view models for Identity, Pairing, and Messaging flows
- [ ] Document success criteria for the first two-device demo

### First implementation tickets
- [ ] Ticket 1: scaffold shared models and repository protocols
- [ ] Ticket 2: implement local identity generation and load-on-launch
- [ ] Ticket 3: implement secure identity persistence
- [ ] Ticket 4: implement peer repository add/list/remove
- [ ] Ticket 5: implement QR pairing payload encode/decode
- [ ] Ticket 6: implement trust persistence after pairing
- [ ] Ticket 7: implement message send/receive contract
- [ ] Ticket 8: wire minimal SwiftUI screens to placeholder state

## Demo definition
The MVP is considered real when:
1. iPhone A launches and creates identity.
2. iPhone B launches and creates identity.
3. A and B pair intentionally.
4. A sends one text message.
5. B receives it.
6. Relaunch preserves identity and trusted peers.

## Notes for implementation
- Prefer explicit state over hidden automation.
- Keep raw identifiers mostly internal.
- Separate trust identity from transport details.
- Optimize for debuggability, not polish.
- If transport proves awkward, keep the protocol stable and swap the implementation later.
