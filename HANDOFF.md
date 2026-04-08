# i2i — Handoff Document

Estado del proyecto al 2026-04-08 (actualizado). Todo lo necesario para retomar desde el Mac.
**COMPLETADO:** Todas las funcionalidades MVP (Tickets 1-9).

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

## Qué hay hecho (continuación)

### Ticket 7 — Persist trust after pairing ✅
- `AppEnvironment` publica `@Published var peerChangeCount` que incrementa cuando se añade un peer.
- `PairingViewModel` inyecta `AppEnvironment` y llama a `notifyPeerChanged()` tras aceptar un pairing.
- `PeersView` observa cambios en `env.peerChangeCount` via `onChange` y recarga la lista automáticamente.
- Sin necesidad de cambiar de tab: el peer aparece en tiempo real en la lista tras un pairing exitoso.

### Ticket 8 — Minimum message transport abstraction ✅
- `MultipeerTransport`: implementación de `TransportProtocol` usando `MCSession` + `MCNearbyServiceAdvertiser` + `MCNearbyServiceBrowser`.
- `MessagePayload`: struct Codable que serializa los mensajes para transmisión por `MCSession.send()`.
- El transport maneja invitaciones automáticas y descubrimiento de pares cercanos (WiFi + BLE).
- `AppEnvironment` instancia `MultipeerTransport` en `init` y lo inicia en `bootstrap()`.

### Ticket 9 — Test message flow ✅
- `MessagingViewModel`:
  - Inyecta `AppEnvironment` para acceder a `identityService`, `peerRepository`, y `transport`.
  - `localDeviceId` usa el `deviceId` real del identity.
  - `sendTapped()` crear un `Message` y lo envía via `transport.send()`.
  - Suscribirse a `transport.onMessageReceived` para recibir mensajes en tiempo real.
- `MessagingView`:
  - Picker para seleccionar peer activo (obligatorio para enviar).
  - Lista de mensajes con estilos diferenciados (enviados vs recibidos).
  - TextField + botón Send (deshabilitado si no hay peer o draft vacío).
  - `ContentUnavailableView` si no hay peers emparejados.
  - Campo de timestamp en cada mensaje.

---

## Qué falta

### Próximas mejoras (v2 o posteriores)
- **Persistencia de mensajes**: guardar historial en SQLite o Core Data.
- **Sincronización de estado**: cuando un peer se desconecta, marcar mensajes como fallidos.
- **Encriptación end-to-end**: usar las claves públicas almacenadas para encriptar mensajes.
- **Avatar/foto de perfil**: permite al usuario subir una foto de perfil.
- **Notificaciones**: alertar cuando llega un mensaje mientras la app no está activa.
- **Typing indicators**: mostrar si el otro dispositivo está escribiendo.
- **Message receipts**: confirmación de lectura.


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
cb46252  feat(ticket-7): persist trust after pairing with real-time UI refresh
5dc5503  feat(ticket-8): implement MultipeerConnectivity transport layer
4bfc1a4  feat(ticket-9): implement message sending and receiving flow
```

**Estado:** MVP completo. El flujo de extremo a extremo (generar identidad → emparejar → enviar/recibir mensajes) está operativo.

Siguientes mejoras (v2): persistencia de mensajes, E2E encryption, notificaciones, read receipts.
