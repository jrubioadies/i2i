To: jrubio.es@gmail.com
Subject: i2i - propuesta de arquitectura de identidad

Hola,

Te comparto la propuesta inicial para la arquitectura de identidad de i2i.

Resumen ejecutivo:
- descartamos IMEI como base del sistema
- para el MVP, la mejor opción es una identidad generada por la app
- esa identidad estaría basada en claves locales por dispositivo
- el emparejamiento sería ligero y explícito, sin login clásico
- no recomiendo meter blockchain ni capas onion en la primera versión
- sí dejaría la arquitectura preparada para reforzar privacidad más adelante

La idea es construir primero una base realista y testeable en iPhone:
- identidad local generada por la app
- almacenamiento seguro en dispositivo
- relación de confianza entre dispositivos emparejados
- separación entre identidad, descubrimiento, transporte y sesión

Motivos para no arrancar con blockchain / onion:
- complican mucho el MVP demasiado pronto
- no resuelven por sí solos el problema principal de pairing y comunicación
- pueden introducir complejidad y fricción antes de validar el valor del producto

Recomendación:
1. identidad generada por la app
2. pairing ligero
3. comunicación local o cercana en MVP
4. preparar evolución futura a capas de privacidad más fuertes si el producto lo requiere

Documento base en el proyecto:
- projects/i2i/identity-architecture.md

Si esta línea te encaja, el siguiente paso sería convertir esto en un technical decision memo y arrancar ya la parte de código.

Un saludo
