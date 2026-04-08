# i2i - Implementation Plan v1

## Goal

Build the first working prototype of i2i with these three capabilities:
- local device identity
- explicit pairing between two devices
- minimum message exchange

This plan is intended to take the project from concept documents into executable implementation work.

## Scope of v1

### Included
- app-generated identity on first launch
- secure local storage of identity material
- user-visible device alias
- peer pairing flow
- trusted peer persistence
- minimum text message exchange
- minimal UI to demonstrate the flow

### Excluded
- account system
- IMEI-based logic
- blockchain
- onion routing
- advanced remote infrastructure
- group chat
- attachments/media
- recovery flows
- production-grade backend

## Working definition of done

The prototype is successful when:
1. iPhone A creates its identity.
2. iPhone B creates its identity.
3. A and B complete a pairing flow.
4. A sends a simple message to B.
5. B receives the message.
6. Restarting the app preserves identity and trusted peer state.

## Recommended implementation style

### Product style
- keep the first version brutally simple
- optimize for proof of flow, not polish
- prefer explicit state over hidden magic
- make debugging easy

### Engineering style
- separate identity, pairing, transport, and UI concerns
- define simple protocols/interfaces early
- keep transport swappable
- avoid premature generalization

## Suggested high-level stack

Assumption for v1:
- native iPhone app
- Swift / SwiftUI
- secure local storage for private identity material
- local/nearby-first communication path

If later needed, this can evolve, but v1 should stay native and simple.

## Proposed module breakdown

### 1. Identity module

Responsibilities:
- generate local device identity on first launch
- persist identity securely
- expose public-facing identity data needed for pairing
- support editable display alias

Data model:
- deviceId
- public identity material
- secure private identity material
- displayName
- createdAt

Core deliverables:
- identity creation service
- identity repository
- identity view model

### 2. Peer module

Responsibilities:
- represent paired devices
- store trusted peers
- load and update peer state

Data model:
- peerId
- peerDisplayName
- peerPublicIdentity
- pairingDate
- trustStatus
- lastSeen optional later

Core deliverables:
- peer repository
- peer list model

### 3. Pairing module

Responsibilities:
- create a pairing payload
- accept a pairing payload
- validate and persist trust relationship
- provide user-visible pairing state

v1 recommendation:
- support QR as primary flow
- keep short-code/manual flow as a later extension unless implementation is trivial

Core deliverables:
- pairing payload generator
- pairing payload parser
- pairing coordinator
- trust establishment logic

### 4. Transport module

Responsibilities:
- establish local communication path between paired devices
- send minimum messages
- receive minimum messages
- surface message delivery events to UI

v1 message model:
- messageId
- senderPeerId
- receiverPeerId
- timestamp
- messageBody
- status local-only if needed

Core deliverables:
- transport interface
- v1 concrete transport implementation
- message send/receive service

### 5. UI module

Responsibilities:
- display local identity
- start pairing flow
- show trusted peers
- send and receive simple messages

Minimum screens:
1. Home / identity screen
2. Pairing screen
3. Trusted peers list
4. Message test screen

## Delivery order

### Phase 1. Project skeleton

Create the app structure and define modules:
- App shell
- Identity
- Pairing
- Peer store
- Transport abstraction
- Test messaging UI

Outcome:
- project builds
- modules compile
- placeholder screens exist

### Phase 2. Identity foundation

Implement:
- first-launch identity generation
- secure storage
- local identity loading on app start
- editable display name

Outcome:
- each install has a persistent local identity

### Phase 3. Peer model and storage

Implement:
- paired peer data model
- trusted peer storage
- peer list loading

Outcome:
- app can remember paired devices

### Phase 4. Pairing flow

Implement:
- pairing payload generation from local identity
- QR rendering for local pairing offer
- QR scanning or payload import path
- trust save on successful pairing

Outcome:
- two devices can establish a trusted relationship

### Phase 5. Minimum transport

Implement:
- basic communication service between paired devices
- send minimum text payload
- receive and render incoming payload

Outcome:
- one device can send a test message to another

### Phase 6. Message UI

Implement:
- choose paired peer
- send test message
- display received test message

Outcome:
- full end-to-end demo flow

## Recommended first coding backlog

### Ticket 1. Create iOS project skeleton
Acceptance criteria:
- project created
- app launches
- placeholder screens wired
- base folders/modules created

### Ticket 2. Implement local identity generation
Acceptance criteria:
- first launch generates identity
- relaunch reuses same identity
- display name can be shown

### Ticket 3. Implement secure identity persistence
Acceptance criteria:
- identity survives app relaunch
- sensitive material is not stored in plain presentation state

### Ticket 4. Define peer model and repository
Acceptance criteria:
- peer records can be saved and loaded
- repository supports add/list/remove

### Ticket 5. Implement pairing payload generation
Acceptance criteria:
- app can generate a payload representing pairing intent
- payload contains only what is required

### Ticket 6. Implement QR-based pairing UI
Acceptance criteria:
- one device can display pairing QR
- another can scan/import it

### Ticket 7. Persist trust after pairing
Acceptance criteria:
- paired peer appears in trusted peer list
- trusted state survives relaunch

### Ticket 8. Implement minimum message transport abstraction
Acceptance criteria:
- sending service exists
- receiving callback exists
- transport is abstracted from UI

### Ticket 9. Implement test message flow
Acceptance criteria:
- select peer
- send text message
- receive text message on paired device

## Suggested folder structure

Example structure for the codebase:

- `App/`
- `Features/Identity/`
- `Features/Pairing/`
- `Features/Peers/`
- `Features/Messaging/`
- `Core/Models/`
- `Core/Storage/`
- `Core/Transport/`
- `Core/Security/`
- `UI/Shared/`

The exact layout can vary, but the separation should remain.

## Testing strategy for v1

### Must test manually
- first launch identity creation
- relaunch identity persistence
- pairing between two real devices
- trusted peer appears correctly
- test message round trip

### Must test logically/unit-wise where easy
- identity generation service
- repository persistence
- pairing payload serialization/deserialization
- message model serialization if applicable

## Debugging requirements

The v1 build should make it easy to inspect:
- local device identity summary
- pairing state
- list of trusted peers
- sent/received test messages
- transport errors

This is important because v1 is a flow-validation prototype.

## Risks during implementation

### Technical
- nearby/local communication behavior may differ across devices or states
- permissions and lifecycle may complicate pairing flow
- background behavior may be constrained

### Product
- pairing UX may need iteration quickly
- message exchange may work technically but feel awkward in practice

## Key decisions frozen for v1

- IMEI excluded
- blockchain excluded
- onion routing excluded
- no classic authentication
- app-generated identity included
- explicit pairing included
- minimum message exchange included

## Recommended immediate next action

Start coding with this order:
1. create project skeleton
2. build identity layer
3. build pairing layer
4. build message proof of concept

## Executive summary

The shortest realistic path to value is:
- stable local identity
- simple explicit pairing
- one minimal message delivered successfully

If that works, the project becomes real.
