# Proposed Source Structure

This is a pragmatic source layout for the first iPhone MVP. It is intentionally scaffold-level, not a full Xcode project.

## Principles
- Separate identity, pairing, messaging, and transport concerns.
- Keep shared models in one place.
- Keep protocol boundaries visible early.
- Allow the first transport implementation to change without rewriting feature code.
- Keep UI thin and driven by feature-facing view models.

## Top-level layout

```text
src/
  Core/
    Models/
    Protocols/
    Security/
    Storage/
    Utilities/
  Features/
    Identity/
    Pairing/
    Messaging/
    Peers/
  UI/
    Screens/
    Components/
    Navigation/
```

## Module details

### `Core/Models/`
Shared domain models with minimal logic.

Suggested files:
- `DeviceIdentity.swift`
- `PeerRecord.swift`
- `MessageEnvelope.swift`
- `PairingPayload.swift`

### `Core/Protocols/`
Stable interfaces that keep implementation swappable.

Suggested files:
- `IdentityRepository.swift`
- `PeerRepository.swift`
- `PairingCoordinating.swift`
- `TransportClient.swift`
- `MessageRepository.swift` (optional later)

### `Core/Security/`
Security-specific helpers for identity generation and secure persistence.

Suggested files:
- `KeypairGenerator.swift`
- `SecureIdentityStore.swift`

### `Core/Storage/`
Non-sensitive persistence helpers and local stores.

Suggested files:
- `PeerStore.swift`
- `MessageStore.swift` (optional later)

### `Core/Utilities/`
Shared helpers kept intentionally small.

Suggested files:
- `Clock.swift`
- `Logger.swift`

### `Features/Identity/`
Identity-specific app behavior.

Suggested files:
- `IdentityService.swift`
- `IdentityViewModel.swift`
- `IdentitySummaryView.swift`

Responsibilities:
- generate/load local identity
- edit display alias
- expose pairing-safe public identity summary

### `Features/Pairing/`
Explicit pairing flow and trust establishment.

Suggested files:
- `PairingService.swift`
- `PairingViewModel.swift`
- `PairingQRCodeView.swift`
- `PairingImportView.swift`

Responsibilities:
- generate pairing payload
- parse incoming pairing payload
- confirm and persist trusted peer

### `Features/Peers/`
Trusted peer listing and management.

Suggested files:
- `PeerListViewModel.swift`
- `PeerListView.swift`
- `PeerDetailView.swift` (optional later)

Responsibilities:
- list trusted peers
- remove or inspect trusted peers later

### `Features/Messaging/`
Minimum send/receive flow for the MVP.

Suggested files:
- `MessagingService.swift`
- `ConversationViewModel.swift`
- `MessageTestView.swift`

Responsibilities:
- send text payloads to a trusted peer
- receive text payloads
- expose simple delivery or error state

### `UI/Screens/`
App-level screen composition if feature views need thin wrappers.

Suggested files:
- `HomeScreen.swift`
- `PairingScreen.swift`
- `MessagingScreen.swift`

### `UI/Components/`
Reusable presentational pieces only.

Suggested files:
- `InfoCard.swift`
- `DebugStatusBadge.swift`

### `UI/Navigation/`
Very light routing for the MVP.

Suggested files:
- `AppRoute.swift`
- `RootNavigator.swift`

## Data flow sketch

```text
UI Screen
  -> Feature ViewModel
    -> Feature Service
      -> Core Protocol
        -> Concrete Store / Security / Transport implementation
```

## MVP implementation order mapped to structure
1. `Core/Models`
2. `Core/Protocols`
3. `Core/Security` + `Features/Identity`
4. `Core/Storage` + `Features/Peers`
5. `Features/Pairing`
6. `Features/Messaging`
7. `UI/`

## What is intentionally not scaffolded yet
- remote relay backend code
- group messaging
- attachments
- account or recovery flows
- advanced privacy routing

## Recommendation
If the implementation starts in SwiftUI, keep this folder shape even if Xcode groups differ. The important part is preserving the boundaries, not enforcing exact filesystem purity.
