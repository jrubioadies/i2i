import http from "node:http";
import { createPublicKey, verify } from "node:crypto";
import { existsSync, mkdirSync, readFileSync, renameSync, writeFileSync } from "node:fs";
import { dirname } from "node:path";
import WebSocket, { WebSocketServer } from "ws";

const port = Number(process.env.PORT ?? 8080);
const maxQueuedMessagesPerDevice = Number(process.env.MAX_QUEUED_MESSAGES_PER_DEVICE ?? 100);
const queueFilePath = process.env.RELAY_QUEUE_FILE ?? "./data/offline-queue.json";
const deviceKeysFilePath = process.env.RELAY_DEVICE_KEYS_FILE ?? "./data/device-keys.json";
const maxRegistrationSkewMs = Number(process.env.MAX_REGISTRATION_SKEW_MS ?? 5 * 60 * 1000);
const ed25519SpkiPrefix = Buffer.from("302a300506032b6570032100", "hex");
const clientsByDeviceId = new Map();
const queuedMessagesByDeviceId = loadQueue();
const publicKeysByDeviceId = loadDeviceKeys();

const server = http.createServer((request, response) => {
  if (request.url === "/health") {
    response.writeHead(200, { "content-type": "application/json" });
    response.end(JSON.stringify({
      ok: true,
      clients: clientsByDeviceId.size,
      queuedMessages: countQueuedMessages(),
      queuedDevices: queuedMessagesByDeviceId.size
    }));
    return;
  }

  response.writeHead(404, { "content-type": "application/json" });
  response.end(JSON.stringify({ error: "not_found" }));
});

const wss = new WebSocketServer({ server, path: "/ws" });

wss.on("connection", (socket) => {
  let registeredDeviceId;

  socket.on("message", (rawMessage) => {
    let payload;
    try {
      payload = JSON.parse(rawMessage.toString());
    } catch {
      send(socket, { type: "error", code: "invalid_json" });
      return;
    }

    if (payload.type === "register") {
      const registrationResult = verifyRegistration(payload);
      if (!registrationResult.ok) {
        send(socket, { type: "error", code: registrationResult.code });
        socket.close(1008, registrationResult.code);
        return;
      }

      registeredDeviceId = payload.deviceId;
      clientsByDeviceId.set(registeredDeviceId, socket);
      console.log(`[relay] registered ${registeredDeviceId}`);
      send(socket, { type: "registered", deviceId: registeredDeviceId });
      deliverQueuedMessages(registeredDeviceId, socket);
      return;
    }

    if (payload.type === "message") {
      const receiver = clientsByDeviceId.get(payload.receiverDeviceId);
      if (!receiver || receiver.readyState !== WebSocket.OPEN) {
        queueMessage(payload.receiverDeviceId, payload);
        send(socket, {
          type: "delivery",
          messageId: payload.messageId,
          status: "queued_offline",
          receiverDeviceId: payload.receiverDeviceId
        });
        return;
      }

      send(receiver, payload);
      send(socket, {
        type: "delivery",
        messageId: payload.messageId,
        status: "delivered_to_relay",
        receiverDeviceId: payload.receiverDeviceId
      });
      return;
    }

    send(socket, { type: "error", code: "unknown_type" });
  });

  socket.on("close", () => {
    if (registeredDeviceId && clientsByDeviceId.get(registeredDeviceId) === socket) {
      clientsByDeviceId.delete(registeredDeviceId);
      console.log(`[relay] disconnected ${registeredDeviceId}`);
    }
  });
});

server.listen(port, () => {
  console.log(`[relay] listening on http://0.0.0.0:${port}`);
  console.log(`[relay] websocket path ws://0.0.0.0:${port}/ws`);
});

function send(socket, payload) {
  socket.send(JSON.stringify(payload));
}

function verifyRegistration(payload) {
  if (!payload.deviceId || !payload.publicKey || !payload.timestamp || !payload.signature) {
    return { ok: false, code: "invalid_registration" };
  }

  const now = Date.now();
  const timestampMs = Number(payload.timestamp);
  if (!Number.isFinite(timestampMs) || Math.abs(now - timestampMs) > maxRegistrationSkewMs) {
    return { ok: false, code: "stale_registration" };
  }

  const knownPublicKey = publicKeysByDeviceId.get(payload.deviceId);
  if (knownPublicKey && knownPublicKey !== payload.publicKey) {
    return { ok: false, code: "device_key_mismatch" };
  }

  try {
    const publicKey = createPublicKey({
      key: Buffer.concat([ed25519SpkiPrefix, Buffer.from(payload.publicKey, "base64")]),
      format: "der",
      type: "spki"
    });
    const signedPayload = Buffer.from(`${payload.deviceId}|${payload.timestamp}`);
    const isValid = verify(null, signedPayload, publicKey, Buffer.from(payload.signature, "base64"));

    if (!isValid) {
      return { ok: false, code: "invalid_signature" };
    }

    if (!knownPublicKey) {
      publicKeysByDeviceId.set(payload.deviceId, payload.publicKey);
      persistDeviceKeys();
    }

    return { ok: true };
  } catch (error) {
    console.error("[relay] registration verification failed:", error);
    return { ok: false, code: "registration_verification_failed" };
  }
}

function queueMessage(receiverDeviceId, payload) {
  const queue = queuedMessagesByDeviceId.get(receiverDeviceId) ?? [];
  queue.push(payload);

  if (queue.length > maxQueuedMessagesPerDevice) {
    queue.splice(0, queue.length - maxQueuedMessagesPerDevice);
  }

  queuedMessagesByDeviceId.set(receiverDeviceId, queue);
  persistQueue();
  console.log(`[relay] queued message ${payload.messageId} for ${receiverDeviceId}`);
}

function deliverQueuedMessages(deviceId, socket) {
  const queue = queuedMessagesByDeviceId.get(deviceId) ?? [];
  if (queue.length === 0) {
    return;
  }

  console.log(`[relay] delivering ${queue.length} queued message(s) to ${deviceId}`);
  for (const payload of queue) {
    send(socket, payload);
  }
  queuedMessagesByDeviceId.delete(deviceId);
  persistQueue();
}

function countQueuedMessages() {
  let count = 0;
  for (const queue of queuedMessagesByDeviceId.values()) {
    count += queue.length;
  }
  return count;
}

function loadQueue() {
  return loadMapFromFile(queueFilePath, "offline queue");
}

function persistQueue() {
  persistMapToFile(queueFilePath, queuedMessagesByDeviceId);
}

function loadDeviceKeys() {
  return loadMapFromFile(deviceKeysFilePath, "device keys");
}

function persistDeviceKeys() {
  persistMapToFile(deviceKeysFilePath, publicKeysByDeviceId);
}

function loadMapFromFile(filePath, label) {
  if (!existsSync(filePath)) {
    return new Map();
  }

  try {
    const raw = readFileSync(filePath, "utf8");
    const parsed = JSON.parse(raw);
    return new Map(Object.entries(parsed));
  } catch (error) {
    console.error(`[relay] failed to load ${label} from ${filePath}:`, error);
    return new Map();
  }
}

function persistMapToFile(filePath, map) {
  const directory = dirname(filePath);
  mkdirSync(directory, { recursive: true });

  const snapshot = Object.fromEntries(map);
  const tempPath = `${filePath}.tmp`;
  writeFileSync(tempPath, JSON.stringify(snapshot, null, 2));
  renameSync(tempPath, filePath);
}
