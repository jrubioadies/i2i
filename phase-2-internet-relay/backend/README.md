# Backend Prototype

This folder is reserved for the phase 2 internet relay backend.

The first backend should be intentionally small:

- WebSocket endpoint for device connections.
- In-memory map from `deviceId` to active connection.
- Signed device registration with trust-on-first-use public key persistence.
- Message forwarding by `receiverDeviceId`.
- Persistent offline queue for encrypted envelopes while a receiver is disconnected.
- Basic logging for connection and delivery state.

Authentication hardening and deployment automation can come after the first end-to-end test.

The offline queue is capped by `MAX_QUEUED_MESSAGES_PER_DEVICE` (default: 100) and persisted to `./data/offline-queue.json` by default. Override the path with `RELAY_QUEUE_FILE`.

Device public keys are persisted to `./data/device-keys.json` by default. Override the path with `RELAY_DEVICE_KEYS_FILE`. This is a trust-on-first-use registry: the first valid registration for a `deviceId` pins its signing public key, and future registrations must match it.

## Run Locally

```bash
npm install
npm run dev
```

The relay listens on:

```text
ws://localhost:8080/ws
```

For physical iPhones, use the Mac's LAN IP instead of `localhost`, for example:

```text
ws://192.168.1.50:8080/ws
```

## Health Check

```bash
curl http://localhost:8080/health
```

Example response:

```json
{
  "ok": true,
  "clients": 2,
  "queuedMessages": 0,
  "queuedDevices": 0
}
```

## Deploy on Render

Use a Web Service, not a static site.

If configuring it manually in Render:

```text
Root Directory: phase-2-internet-relay/backend
Build Command: npm install
Start Command: npm start
Health Check Path: /health
```

Render injects the `PORT` environment variable automatically. The server reads it with `process.env.PORT`, so do not hard-code port `8080` in Render.

After deploy, verify:

```bash
curl https://<your-render-service>.onrender.com/health
```

The iOS relay URL should use WebSocket TLS:

```text
wss://<your-render-service>.onrender.com/ws
```

## Message Privacy

The relay treats `body` as opaque ciphertext. It routes by `receiverDeviceId` and does not decrypt or inspect message content.
