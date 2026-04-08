# i2i — Handoff Document

Estado del proyecto al 2026-04-08. Todo lo necesario para retomar desde el Mac.

---

## Setup en el Mac

```bash
# 1. Clonar el repo
git clone https://github.com/jrubioadies/i2i.git
cd i2i/ios

# 2. Instalar xcodegen si no está
brew install xcodegen

# 3. Generar el proyecto Xcode
xcodegen generate

# 4. Abrir
open i2i.xcodeproj
```

Requisitos: Xcode 15+, iOS 17+, Swift 5.9.

---

## Qué hay hecho

### Ticket 1 — Project skeleton ✅
Estructura de carpetas y ficheros placeholder compilables. TabView con 4 tabs: Identity, Pairing, Peers, Messaging.

### Ticket 2 — Local identity generation ✅
- `IdentityService.loadOrCreate()`: primer launch genera un keypair Ed25519 con CryptoKit, relaunches cargan la identidad existente.
- La identidad se muestra en la tab Identity (ID corto, nombre, fecha).

### Ticket 3 — Secure identity persistence ✅
- Clave privada en Keychain con `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` y `kSecAttrSynchronizable=false` (no va en backups, no se exporta, no se sincroniza con iCloud).
- Datos públicos en `Application Support/identity.json` con escritura atómica.
- Si el Keychain desaparece (restore de backup), el servicio detecta la inconsistencia, borra los datos públicos y genera una identidad nueva.

### Ticket 4 — Peer model and repository ✅
- `Peer`: modelo Codable con `id`, `displayName`, `publicKey`, `pairingDate`, `trustStatus`.
- `LocalPeerRepository`: guarda en `Application Support/peers.json`; `save()` hace upsert por id; `remove()` filtra y reescribe atómicamente.
- La tab Peers muestra la lista con swipe-to-delete. Si está vacía muestra `ContentUnavailableView`.

### Ticket 5 — Pairing payload generation ✅
- `PairingPayload`: modelo mínimo (deviceId + displayName + publicKey). `encoded()` → JSON string. `decode()` → parsea el string del QR.
- `PairingService.generatePayload()`: construye el payload desde la identidad local.
- `PairingService.accept()`: valida el payload (rechaza self-pairing) y persiste el peer.
- `AppEnvironment`: contenedor compartido de servicios inyectado como `@EnvironmentObject` desde `i2iApp`. Evita múltiples instancias de `IdentityService`.

### Ticket 6 — QR-based pairing UI ✅
- `QRCodeView`: genera el QR con `CIFilter.qrCodeGenerator` (Core Image, sin dependencias externas), escalado 10x para renderizado nítido.
- `QRScannerView`: `UIViewControllerRepresentable` con `AVCaptureSession` + `AVMetadataOutput`. Gestiona el permiso de cámara.
- `PairingView`: flujo completo — "Show My Pairing QR" muestra el QR generado, "Scan Peer QR" abre el scanner como sheet. Banner de éxito/error tras el scan.

**El flujo de pairing entre dos dispositivos ya es funcional de extremo a extremo.**

---

## Qué falta

### Ticket 7 — Persist trust after pairing
**Criterios de aceptación:**
- El peer emparejado aparece en la lista de Trusted Peers.
- El estado sobrevive al relaunch.

**Nota:** `PairingService.accept()` ya llama a `peerRepository.save()`. El peer queda persistido. Lo que falta es:
- Asegurarse de que `PeersView` se refresca tras un pairing exitoso (actualmente carga en `onAppear`, lo que debería ser suficiente si el tab se visita después).
- Posiblemente añadir un `@Published` en `AppEnvironment` o usar `NotificationCenter` para notificar a `PeersViewModel` sin cambiar de tab.
- Test manual: emparejar dos dispositivos y verificar que el peer aparece en ambos tras relanzar la app.

### Ticket 8 — Minimum message transport abstraction
**Criterios de aceptación:**
- Existe un servicio de envío.
- Existe un callback de recepción.
- El transport está abstraído de la UI.

**Decisión pendiente:** el mecanismo de transporte. Opciones discutidas:
- **MultipeerConnectivity** ← recomendado para v1. WiFi + BLE automático, Apple lo gestiona, swappable después.
- Bonjour + TCP/IP: más control, más complejo.
- BLE manual: máximo control, scope mucho mayor.

**Lo que hay que implementar:**
- `MultipeerTransport`: implementación concreta de `TransportProtocol` usando `MCSession` + `MCNearbyServiceAdvertiser` + `MCNearbyServiceBrowser`.
- Serialización de `Message` para enviarlo por `MCSession.send()`.
- Añadir `MCTransport` a `AppEnvironment`.

### Ticket 9 — Test message flow
**Criterios de aceptación:**
- Seleccionar un peer.
- Enviar un mensaje de texto.
- Recibirlo en el dispositivo emparejado.

**Lo que hay que implementar:**
- `MessagingViewModel`: inyectar `IdentityService` para el `localDeviceId` real, y el transport para enviar/recibir.
- `MessagingView`: selector de peer activo, enviar mensaje, mostrar mensajes recibidos en tiempo real.
- Conectar el callback `onMessageReceived` del transport al ViewModel.

---

## Arquitectura de servicios

```
AppEnvironment (@EnvironmentObject)
├── IdentityService          → loadOrCreate(), updateDisplayName()
│   └── LocalIdentityRepository → Application Support/identity.json
│   └── KeyStore             → Keychain (clave privada)
├── PairingService           → generatePayload(), accept()
│   └── IdentityService      (compartido)
│   └── LocalPeerRepository  → Application Support/peers.json
└── [Ticket 8] MultipeerTransport → MCSession
```

## Estructura de ficheros

```
ios/
├── project.yml                         ← xcodegen spec
└── i2i/
    ├── App/
    │   ├── i2iApp.swift                ← @StateObject AppEnvironment, .task bootstrap
    │   ├── AppEnvironment.swift        ← contenedor de servicios compartidos
    │   └── ContentView.swift           ← TabView (Identity, Pairing, Peers, Messaging)
    ├── Features/
    │   ├── Identity/
    │   │   ├── IdentityView.swift
    │   │   └── IdentityViewModel.swift
    │   ├── Pairing/
    │   │   ├── PairingView.swift       ← QR display + scanner sheet
    │   │   └── PairingViewModel.swift
    │   ├── Peers/
    │   │   ├── PeersView.swift         ← lista + swipe-to-delete
    │   │   └── PeersViewModel.swift
    │   └── Messaging/
    │       ├── MessagingView.swift     ← UI de chat (pendiente conectar transport)
    │       └── MessagingViewModel.swift
    ├── Core/
    │   ├── IdentityService.swift
    │   ├── PairingService.swift
    │   ├── Models/
    │   │   ├── LocalIdentity.swift     ← Codable, publicKey: Data
    │   │   ├── Peer.swift              ← Codable, TrustStatus enum
    │   │   ├── Message.swift           ← id, senderPeerId, receiverPeerId, body, status
    │   │   └── PairingPayload.swift    ← deviceId + displayName + publicKey; encode/decode JSON
    │   ├── Storage/
    │   │   ├── IdentityRepository.swift    ← protocolo: load / save / delete
    │   │   ├── LocalIdentityRepository.swift
    │   │   ├── PeerRepository.swift        ← protocolo: loadAll / save / remove
    │   │   └── LocalPeerRepository.swift
    │   ├── Transport/
    │   │   └── TransportProtocol.swift     ← protocolo: start / stop / send / onMessageReceived
    │   └── Security/
    │       └── KeyStore.swift              ← Keychain: save / load / exists / typed CryptoKit helpers
    └── UI/Shared/
        ├── QRCodeView.swift            ← Core Image, sin deps externas
        └── QRScannerView.swift         ← AVFoundation, gestiona permiso de cámara
```

---

## Decisiones técnicas tomadas

| Decisión | Elegido | Motivo |
|---|---|---|
| Identidad | App-generated (Ed25519) | Sin IMEI, sin servidor, funciona offline |
| Almacenamiento clave privada | Keychain (device-only, no backup) | No exportable, no sincronizable |
| Almacenamiento datos públicos | Application Support / JSON | Más apropiado que UserDefaults para datos de app |
| Pairing | QR con JSON payload | Explícito, sin fricción, funciona sin red |
| Transport v1 | MultipeerConnectivity (pendiente) | Local-first, WiFi+BLE automático, swappable |
| DI de servicios | @EnvironmentObject (AppEnvironment) | Evita múltiples instancias, simple para v1 |
| Blockchain | Descartado en v1 | Complejidad prematura |
| Onion routing | Descartado en v1 | Complejidad prematura |

---

## Commits en main

```
88437bc  Initial project scaffold (tickets 1+2 base)
26a0b8c  feat(ticket-3): secure identity persistence
2bb4fde  feat(ticket-4): peer model and repository
50e5206  feat(ticket-5): pairing payload generation
519da5f  feat(ticket-6): QR-based pairing UI
```

Siguiente: ticket 7 → trust persistence, luego ticket 8 → MultipeerConnectivity transport.
