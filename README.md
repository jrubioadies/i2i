# i2i

Proyecto para explorar comunicación entre dos dispositivos iPhone sin SIM, evitando dependencias de autenticación tradicional y documentando tanto hallazgos válidos como vías descartadas.

## Estado actual

Fase: exploración y validación técnica.

## Objetivo inicial

Encontrar una forma viable de establecer comunicación entre dos iPhone:
- sin SIM insertada
- sin depender de cuentas/login tradicionales
- con la menor fricción posible para el usuario
- dejando espacio posterior para una interfaz de usuario

## Log del proceso

### 2026-04-08 - Punto de partida

**Idea inicial**
- Usar el IMEI del teléfono como identificador único.
- Abrir una comunicación entre dos iPhone usando ese identificador.
- Más adelante, construir una interfaz de usuario encima.

**Análisis inicial**
- El IMEI puede identificar hardware, pero no crea por sí mismo un canal de comunicación.
- En iPhone/iOS, el acceso al IMEI está muy restringido para apps normales.
- Por tanto, una solución basada en IMEI como identidad operativa principal no parece viable en iPhone estándar.

**Conclusión actual**
- Se descarta IMEI como base del diseño.

**Razones para descartarlo**
1. No resuelve descubrimiento ni transporte.
2. No ofrece sesión ni emparejamiento por sí mismo.
3. iOS limita fuertemente el acceso al IMEI desde aplicaciones corrientes.
4. Introduce una dependencia técnica poco realista para un MVP sobre iPhone.

## Aprendizajes recuperables

- El problema real no es “cómo identificar el teléfono”, sino “cómo crear una identidad práctica y una comunicación viable en iOS con baja fricción”.
- Hay que separar claramente:
  - identidad
  - descubrimiento
  - transporte
  - sesión
  - experiencia de usuario

## Errores / caminos descartados

### IMEI como identificador principal
Estado: descartado.

Motivo:
- No es una base práctica para implementar una app iPhone estándar.

## Siguientes líneas de exploración

Opciones a evaluar en próximas iteraciones:
- identidad propia generada por la app
- comunicación local o cercana entre dispositivos
- emparejamiento sin login clásico
- uso de capacidades nativas de iOS para proximidad o descubrimiento

## Próximo paso recomendado

Redactar un documento de viabilidad con:
- restricciones reales de iOS
- opciones técnicas viables
- arquitectura mínima de MVP
- riesgos
- decisiones a tomar
