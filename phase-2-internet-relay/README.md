# i2i Phase 2 - Internet Relay

This folder contains the phase 2 workstream for connecting paired iPhones when they are not on the same local WiFi network.

The MVP in `../ios` remains focused on local-first communication with `MultipeerConnectivity`. Phase 2 adds an internet-capable transport while preserving the same identity, pairing, and trust model.

## Goal

Allow two already-paired devices to exchange messages when both have internet access, even if they are on different networks.

## Proposed Direction

Use an internet relay service as the first phase 2 transport:

- iOS opens a WebSocket connection to the relay.
- The relay routes encrypted message envelopes by receiver device ID.
- The server should not need access to plaintext message bodies.
- The existing `TransportProtocol` can gain a second implementation alongside `MultipeerTransport`.

## Folder Structure

- `backend/`: relay server prototype.
- `ios-integration/`: notes and draft Swift integration work for `InternetRelayTransport`.
- `docs/`: phase 2 architecture and implementation notes.

## MVP Compatibility

Phase 2 should not break local messaging:

- Keep `MultipeerTransport` for same-network / nearby devices.
- Add `InternetRelayTransport` for cross-network messaging.
- Later, add a transport selector that prefers local transport when available and falls back to internet relay.

