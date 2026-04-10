# i2i: de una idea local-first a una app iOS que comunica dos iPhones sin servidor

Durante los ultimos dias he estado desarrollando un prototipo llamado **i2i**: una app iOS pensada para explorar una idea sencilla, pero potente: que dos dispositivos puedan reconocerse, emparejarse y enviarse mensajes directamente, sin depender de un servidor central para la identidad ni para el transporte inicial.

El objetivo no era construir "otro chat", sino validar una arquitectura local-first: identidad generada en el propio dispositivo, confianza explicita entre pares y comunicacion cercana entre moviles usando las capacidades nativas de iOS.

Este es el resumen del proceso de diseno y programacion.

## 1. Punto de partida: identidad local, no identidad de plataforma

La primera decision importante fue separar la identidad de la app de cualquier identificador externo. No usamos IMEI, ni cuenta de usuario, ni login social, ni servidor de autenticacion.

Cada dispositivo genera su propia identidad local:

- Un `deviceId` unico.
- Un nombre visible del dispositivo.
- Un par de claves criptograficas Ed25519 usando CryptoKit.
- Una clave publica compartible.
- Una clave privada que nunca sale del dispositivo.

La clave privada se guarda en Keychain con una politica restrictiva: accesible solo cuando el dispositivo esta desbloqueado, no sincronizable y no migrable a otros dispositivos. Los datos publicos se guardan en `Application Support` como JSON.

La idea de fondo es importante: la identidad no se "asigna" desde fuera. La identidad nace en el dispositivo.

## 2. Emparejamiento mediante QR: confianza explicita

Una vez resuelta la identidad local, el siguiente paso fue permitir que dos dispositivos se reconocieran.

Para el MVP elegimos un flujo de emparejamiento por QR:

1. El dispositivo A genera un payload con su `deviceId`, `displayName` y clave publica.
2. Ese payload se serializa como JSON.
3. La app lo convierte en un QR usando Core Image.
4. El dispositivo B escanea el QR con AVFoundation.
5. Si el payload es valido y no corresponde al propio dispositivo, se guarda como peer de confianza.

Esta decision fue intencionada. El QR obliga a que haya una accion fisica y explicita entre los dos usuarios. No hay descubrimiento silencioso de identidad ni aceptacion automatica de confianza.

## 3. Arquitectura sencilla: servicios compartidos y repositorios locales

Para mantener el prototipo claro, estructuramos la app en capas pequenas:

- `IdentityService`: crea y carga la identidad local.
- `PairingService`: genera y acepta payloads de emparejamiento.
- `PeerRepository`: persiste peers de confianza.
- `MessageRepository`: persiste conversaciones localmente.
- `TransportProtocol`: define una abstraccion para el transporte de mensajes.
- `MultipeerTransport`: implementa el transporte usando MultipeerConnectivity.
- `AppEnvironment`: actua como contenedor compartido de servicios.

La interfaz se construyo con SwiftUI y se dividio en cuatro areas principales:

- Identity: muestra la identidad local.
- Pair: genera y escanea QRs.
- Peers: lista los dispositivos emparejados.
- Messages: permite enviar y recibir mensajes.

Una de las decisiones practicas fue usar `AppEnvironment` como `EnvironmentObject`, evitando multiples instancias de servicios criticos como `IdentityService`. Esto fue especialmente importante para que la identidad usada por el QR, el repositorio y el transporte fuera la misma.

## 4. Transporte: MultipeerConnectivity como primera validacion

Para el transporte inicial elegimos **MultipeerConnectivity**. No es la solucion final para todos los escenarios, pero encaja muy bien con un prototipo local-first:

- Permite descubrimiento cercano entre dispositivos.
- Usa WiFi/Bluetooth segun disponibilidad.
- Evita montar infraestructura de servidor en la primera iteracion.
- Es nativo de iOS.

El `MultipeerTransport` crea:

- Un `MCPeerID` basado en el `deviceId`.
- Una `MCSession`.
- Un `MCNearbyServiceAdvertiser`.
- Un `MCNearbyServiceBrowser`.

Al enviar un mensaje, la app serializa un `MessagePayload` como JSON y lo transmite por la sesion activa.

Durante las pruebas aparecio un problema interesante: ambos iPhones podian descubrirse e invitarse al mismo tiempo, generando una especie de bucle de invitaciones. La solucion fue introducir una regla determinista: solo uno de los dos peers inicia la invitacion, y se evitan invitaciones duplicadas a peers ya conectados.

Este fue uno de esos momentos donde el prototipo deja de ser "codigo que compila" y empieza a ser "software que se comporta bien en dispositivos reales".

## 5. Pruebas reales: el simulador no basta

Una parte clave del proceso fue probar en dos iPhones reales.

En el camino aparecieron varios problemas muy tipicos de desarrollo iOS:

- El proyecto generado por XcodeGen estaba desactualizado y no incluia nuevos archivos Swift.
- El catalogo de iconos tenia imagenes sobrantes no referenciadas.
- El target inicial estaba en iOS 17, pero necesitabamos compatibilidad con iOS 16.
- Algunas APIs de SwiftUI, como ciertas variantes de `onChange` y `ContentUnavailableView`, exigian iOS 17.
- El arranque de MultipeerConnectivity al abrir la app podia complicar el diagnostico de una pantalla negra.

La solucion fue ir reduciendo incertidumbre:

- Regenerar el proyecto con XcodeGen.
- Bajar el deployment target a iOS 16.
- Sustituir vistas iOS 17-only por componentes propios.
- Mover el inicio del transporte a un arranque perezoso desde la pantalla de mensajes.
- Anadir una `RootView` defensiva para mostrar estado de arranque y errores.
- Limpiar y estabilizar la logica de conexion/desconexion.

Este punto me parece especialmente relevante para un proyecto real: no basta con disenar la arquitectura. Hay que cerrar el circuito con compilacion, instalacion, permisos, lifecycle de iOS y pruebas en hardware.

## 6. Mensajeria y persistencia local

El primer flujo de mensajes funcionaba en memoria, pero eso tenia una limitacion evidente: al cambiar de peer o reiniciar la app, el historial se perdia.

Anadimos entonces un `MessageRepository` local basado en JSON:

- Guarda mensajes enviados y recibidos.
- Carga conversaciones filtrando por peer local y peer remoto.
- Mantiene el historial ordenado por fecha.

No es una solucion final tipo SQLite/Core Data, pero para un MVP es una capa suficiente para validar el comportamiento de conversacion.

Tambien se pulio la interfaz:

- Selector de peer activo.
- Indicador de conectado/desconectado.
- Boton para desconectar.
- Boton para reconectar despues de desconectar.
- Boton para salir de la pantalla de mensajes.
- Burbujas diferenciadas para mensajes enviados y recibidos.
- Mejora de contraste en mensajes recibidos.

## 7. Lo aprendido

Este desarrollo deja varias lecciones utiles:

- Empezar local-first obliga a pensar bien donde vive la identidad.
- El emparejamiento por QR es simple, comprensible y explicito.
- MultipeerConnectivity es muy potente, pero necesita control de estados para evitar bucles de invitacion.
- Probar en dispositivos reales cambia rapidamente las prioridades.
- XcodeGen ayuda mucho, pero hay que regenerar el proyecto cuando cambia la estructura.
- La compatibilidad de iOS no es solo cambiar el deployment target: tambien hay que revisar APIs de SwiftUI.
- Un MVP no tiene que resolverlo todo, pero si debe validar el riesgo principal.

## 8. Siguientes pasos

El MVP ya valida el flujo principal:

1. Crear identidad local.
2. Emparejar dos dispositivos por QR.
3. Establecer conexion cercana.
4. Enviar y recibir mensajes.
5. Persistir el historial localmente.
6. Desconectar y reconectar.

Los siguientes pasos naturales serian:

- Encriptacion end-to-end usando las claves publicas ya intercambiadas.
- Confirmaciones de entrega y lectura.
- Mejor gestion de estados de conexion.
- Notificaciones locales.
- Persistencia mas robusta con SQLite o Core Data.
- Mejor UX para multiples peers.
- Pruebas automatizadas de servicios y repositorios.

## Cierre

i2i empezo como una pregunta tecnica: "Podemos construir una comunicacion directa entre dispositivos, con identidad local y confianza explicita, sin empezar por un servidor?"

La respuesta del MVP es: si, y el camino es muy interesante.

No porque el prototipo ya sea un producto cerrado, sino porque valida los bloques fundamentales: identidad, emparejamiento, confianza, transporte y mensajeria.

Para mi, ese es el valor de un buen MVP: no pretende demostrar que todo esta terminado. Demuestra que la direccion tecnica tiene sentido.

