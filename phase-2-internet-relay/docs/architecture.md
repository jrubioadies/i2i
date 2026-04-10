# Phase 2 Architecture - Internet Relay

## Problem

The current MVP uses `MultipeerConnectivity`, which is excellent for nearby devices but not intended for devices on different networks.

To support communication over the internet, both devices need a shared reachable coordination point.

## Recommended Phase 2 Architecture

```text
iPhone A
  -> encrypts message for iPhone B
  -> sends envelope to relay over WebSocket

Relay server
  -> reads routing metadata
  -> forwards encrypted envelope to iPhone B

iPhone B
  -> receives envelope
  -> decrypts locally
  -> persists message
```

## Core Components

- `InternetRelayTransport`: Swift implementation of `TransportProtocol` using WebSocket.
- `RelayEnvelope`: transport payload with sender ID, receiver ID, timestamp, message ID, and ciphertext.
- `RelayServer`: small backend that maintains online device connections and forwards envelopes.
- `TransportRouter`: future app-level component that chooses between local and internet transport.

## Security Direction

The relay must be treated as untrusted infrastructure.

During local development, the iOS project allows non-TLS `ws://` connections so physical devices can connect to a relay running on the Mac. Production builds should use `wss://` and remove broad arbitrary-load allowances.

The server can know:

- Sender device ID.
- Receiver device ID.
- Message timestamps.
- Envelope size.

The server should not know:

- Message body.
- Decrypted payload contents.
- Private keys.

The encryption layer should use the public keys already exchanged during QR pairing.

## First Implementation Milestones

1. Define `RelayEnvelope`.
2. Build a minimal WebSocket relay.
3. Add `InternetRelayTransport` in Swift.
4. Send plaintext envelopes only in a local dev prototype if needed.
5. Replace plaintext body with encrypted payload.
6. Add reconnection and offline delivery behavior.
7. Add UI state for local, relay, and offline connection modes.

## Current Envelope Status

Relay messages now use the `body` field as a base64-encoded ChaChaPoly sealed box. The relay forwards the envelope but does not need to decrypt it.

Peers that were paired before phase 2 encryption need to be paired again so both devices exchange `encryptionPublicKey`.

Device relay registration is signed with the local Ed25519 identity key. The relay uses a trust-on-first-use registry to pin each `deviceId` to its first valid signing public key.
