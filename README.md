# Color Matcher Pro - Flutter Edition

Una aplicación móvil avanzada desarrollada en Flutter para la captura, análisis y gestión de colores utilizando Inteligencia Artificial (Gemini 1.5 Flash).

## 🚀 Registro de Modificaciones Recientes

### 1. Arquitectura y Servicios Base
- **GeminiService**: Integración con el modelo `gemini-1.5-flash` para análisis profundo de color.
- **HistoryService**: Sistema de persistencia local con `SharedPreferences` para el historial de escaneos.
- **LoggerService**: Sistema de registro de eventos para depuración y monitoreo.
- **Modelos de Datos**: Implementación de clases `ColorData`, `RGB`, `CMYK` y `HarmonyColor` con soporte para serialización JSON.

### 2. Mejoras de Estabilidad y Red (Última Sesión)
- **Configuración de Permisos**: Se añadieron permisos de `INTERNET` y `CAMERA` en el `AndroidManifest.xml` para asegurar la conectividad y funcionalidad del hardware.
- **Tests de Estabilidad**: Creación de `test/stability_test.dart` para verificar automáticamente la carga de configuraciones y la inicialización de servicios críticos.
- **Gestión de Entorno**: Actualización del sistema de claves API mediante `.env` y corrección de errores de carga.

### 3. Interfaz y Experiencia de Usuario (UI/UX)
- **ScannerPage**: Interfaz de cámara en tiempo real con detección de color central y búsqueda de coincidencia Pantone más cercana.
- **ColorDetailPage**: Visualización mejorada con:
    - Análisis de **Psicología del Color**.
    - **Consejos de Diseño** profesionales generados por IA.
    - Paletas armoniosas dinámicas.
- **Dashboard**: Vista principal con estadísticas de colores escaneados y acceso rápido al historial.

---

## 🛠️ Requisitos e Instalación

1. **Flutter SDK**: Versión `3.1.0` o superior.
2. **Dependencias**:
   ```bash
   flutter pub get
   ```
3. **Configuración de API Key**:
   Crea un archivo `.env` en la raíz del proyecto:
   ```env
   GEMINI_API_KEY=tu_clave_aqui
   ```

## 🧪 Pruebas
Para ejecutar los tests de estabilidad:
```bash
flutter test test/stability_test.dart
```

---
**Estado del Proyecto:** Estable / Mejorado con IA Pro
**Última actualización:** 23 de Mayo de 2024
