# fintech-security

*Read this in [English](README.md)*

Módulo nativo para React Native (Expo Modules API) que devuelve un identificador único del dispositivo a través de `getIdentifier(): Promise<string>`.

## Notas de diseño

### La primera pregunta: ¿para qué es este identificador?

La API correcta depende del caso de uso, y algunos casos de uso no se resuelven con un identificador:

| Caso de uso | Qué necesita | La herramienta correcta |
|---|---|---|
| Registro regulatorio (p. ej. bitácoras de dispositivo de acceso de la CNBV para IFPEs) | Estable por instalación | IDFV / `ANDROID_ID` |
| Vinculación de dispositivo para autenticación | No es un ID: un par de llaves en hardware | Secure Enclave / Keystore + attestation |
| Antifraude (multi-accounting, account takeover) | Sobrevivir reinstalación/reset | UUID persistido en Keychain (iOS), `ANDROID_ID` (Android), más señales del lado del servidor |
| Correlacionar usuarios entre apps de la misma empresa | Mismo valor entre las apps del vendor | IDFV / App Set ID |

Planteé esta pregunta al equipo, y sus respuestas fijaron los requisitos:

1. El identificador **debe sobrevivir la reinstalación de la app**.
2. **No** necesita sobrevivir un factory reset.
3. Basta el alcance por app — no necesita coincidir entre las demás apps de la empresa.
4. Identifica al **dispositivo**, no al usuario: debe cambiar cuando el usuario cambia de teléfono.

Ese perfil descarta el IDFV en iOS (se resetea con la reinstalación cuando es la única app del vendor) y descarta los mecanismos cross-app como App Set ID (fuera de alcance por la respuesta 3). Apunta al diseño implementado aquí.

### Qué se descartó y por qué

- **IMEI, MAC address, UDID**: muertos. El IMEI está bloqueado para apps normales desde Android 10; la MAC devuelve una constante desde Android 6/iOS 7; el UDID se eliminó en iOS 7.
- **IDFA / Advertising ID**: por política son solo para publicidad, reseteables por el usuario, y en iOS están detrás del prompt de ATT. Usarlos para otra cosa es causal de rechazo en las stores.
- **DeviceCheck, App Attest, Play Integrity, Key Attestation**: requieren un backend que verifique tokens contra Apple/Google, así que quedan fuera del alcance de este ejercicio.
- **MediaDrm/Widevine ID**: legible sin permisos y sobrevive el factory reset, pero es una API de DRM reutilizada para identificación. El usuario no puede resetearla ni ver que se recolecta, y sigue al hardware entre dueños. La política de Google Play solo lo tolera bajo la excepción de prevención de fraude y debe declararse en el Data Safety form. Aceptable como señal secundaria en un stack antifraude; no como identificador primario.

### Qué devuelve este módulo

- **iOS: un UUID generado una sola vez y persistido en el Keychain**, con `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly` y no sincronizable. Los items del Keychain sobreviven la desinstalación de la app, lo que satisface el requisito 1. Los atributos `ThisDeviceOnly` + no sincronizable son los que satisfacen el requisito 4: el item queda excluido de la sincronización de iCloud Keychain y de las restauraciones entre dispositivos, así que el valor nunca sigue al usuario a un teléfono nuevo. Se pierde con factory reset.
- **Android: `ANDROID_ID`** (SSAID). Con alcance por app-signing-key + usuario + dispositivo desde Android 8. Satisface todos los requisitos tal cual: sobrevive reinstalación, se pierde con factory reset, alcance por app, y nunca se traslada a otro dispositivo. Sin permisos y sin dependencia de Google Play Services, lo cual es relevante para dispositivos sin GMS como los Huawei.

### Cómo evolucionó la decisión de iOS

El primer candidato fue el IDFV: es la API más simple que satisface el contrato literal (estable por instalación) y no requiere almacenamiento. Pero el IDFV se resetea con la reinstalación cuando es la única app instalada del vendor, lo que incumple el requisito 1, así que el UUID persistido en Keychain pasó a ser la solución elegida.

El IDFV también se consideró como fallback para cuando el Keychain no esté disponible, y se descartó: un valor de fallback tiene semántica de persistencia más débil que el primario, y el consumidor no puede distinguir cuál recibió. Para un sistema que correlaciona dispositivos a través de reinstalaciones, un rechazo duro con `ERR_IDENTIFIER_STORAGE_ACCESS` es más útil que un identificador silenciosamente degradado.

### Por qué la Expo Modules API

El documento pide idealmente Expo Modules, o JSI/TurboModules. Un solo Expo Module cubre a todos los consumidores sin bindings adicionales:

- No requiere una app Expo — requiere `expo-modules-core`, que se instala en cualquier app React Native bare con `npx install-expo-modules`.
- Funciona sobre el bridge clásico y la New Architecture; `expo-modules-core` resuelve esa frontera.

La lógica del identificador vive en clases Swift/Kotlin puras, sin imports de React Native. El módulo Expo es un adaptador delgado sobre ellas. Esto permite testear la lógica nativa con XCTest/JUnit.

### Soporte de versiones de OS y manejo de errores

No se necesita ramificación por versión de OS: los mínimos del propio React Native (iOS 15.1+, Android 7+) están muy por encima de la introducción de todas las APIs usadas aquí (`ANDROID_ID`: API 1; Keychain: iOS 2). Lo que el módulo sí maneja son condiciones de runtime.

- `ANDROID_ID` puede ser null o vacío en dispositivos raros.
- Las operaciones de Keychain pueden fallar con errores `OSStatus` (p. ej. poco después de reiniciar el dispositivo, antes del primer desbloqueo).

Los fallos cruzan la frontera hacia JS como códigos de error tipados (`ERR_IDENTIFIER_UNAVAILABLE`, `ERR_IDENTIFIER_STORAGE_ACCESS`) en lugar de mensajes crudos de la plataforma, para que el consumidor pueda ramificar sobre ellos.

## Instalación

| Consumidor | Comando |
|---|---|
| App Expo | `npx expo install fintech-security` |
| React Native bare con expo-modules-core | `npm i fintech-security` |
| React Native bare sin Expo | `npx install-expo-modules && npm i fintech-security` |

## Uso

```ts
import FintechSecurity from 'fintech-security';

const id = await FintechSecurity.getIdentifier();
```

## Scripts

Todos se corren desde la raíz del repo:

| Script | Qué hace |
|---|---|
| `npm run build` | Compila `src/` a `build/` (lo que usan Metro y los consumidores de npm) |
| `npm run clean` | Borra `build/` |
| `npm run lint` | ESLint sobre `src/` |
| `npm test` | Jest para la capa TS del módulo (una sola corrida) |
| `npm run test:example` | Jest para la app de ejemplo (una sola corrida) |
| `npm run test:android` | Corre los tests JUnit del módulo, imprimiendo cada resultado en consola |
| `npm run open:android` | Abre `example/android` en Android Studio |
| `npm run open:ios` | Abre `example/ios` en Xcode |

## Testing

### Android

La lógica del identificador vive en `DeviceIdentifierProvider`, que recibe la lectura de `Settings.Secure` como función inyectada (`() -> String?`); un constructor secundario conecta la llamada real. La suite (`android/src/test`) cubre:

- `ANDROID_ID` presente → se devuelve tal cual
- `ANDROID_ID` null (dispositivos raros) → `IdentifierUnavailableException`
- `ANDROID_ID` blank → `IdentifierUnavailableException`

Se corren desde la raíz del repo:

```sh
npm run test:android
```

Cada test imprime su resultado en consola (`testLogging` está configurado en `android/build.gradle`, y el script pasa `--rerun` para re-ejecutar aunque haya resultados cacheados). El reporte HTML queda en `android/build/reports/tests/testDebugUnitTest/index.html`.

Nota: el folder `android/` del módulo es un subproyecto Gradle de la app de ejemplo (layout estándar de `create-expo-module`), así que los tests corren a través de `example/android`. Ese proyecto debe existir primero — completa el [setup de la app de ejemplo](#correr-la-app-de-ejemplo) una vez antes de correrlos. Solo se compila el módulo y sus dependencias, no el APK de la app.

El adaptador Expo (`FintechSecurityModule.kt`) no tiene unit tests: no contiene lógica — resuelve el Context y delega al provider. Lo ejercita end-to-end la app de ejemplo.

### TypeScript

La superficie JS del módulo (`src/__tests__/`, Jest con el preset `jest-expo`, `requireNativeModule` mockeado) cubre el contrato:

- El módulo nativo se resuelve con el nombre `FintechSecurity`
- `getIdentifier()` está expuesto y pasa el resultado nativo tal cual
- Los códigos de rechazo (`ERR_IDENTIFIER_UNAVAILABLE`, `ERR_IDENTIFIER_STORAGE_ACCESS`) se mantienen estables

```sh
npm test   # agrega --watch para modo watch
```

### App de ejemplo

`example/App.test.tsx` (Jest + React Native Testing Library, con el módulo mockeado) cubre la máquina de estados de la pantalla:

- Arranca idle: el módulo no se llama al montar
- Presionar el botón muestra el identificador
- Un rechazo con código tipado muestra el código y el mensaje
- Un rechazo sin código cae a `UNKNOWN`

```sh
npm run test:example   # o: cd example && npm test
```

Ninguna de las dos suites necesita emulador.

### Decisión de herramientas

Se consideraron tres opciones para testear código cuya única dependencia de Android es una llamada estática:

| Opción | Por qué se eligió / descartó |
|---|---|
| Robolectric | Simula el `ContentResolver` real, pero trae los jars `android-all` y configuración de runner para testear un guard de null/blank. Se justifica en código que usa resources, lifecycle o storage; desproporcionado aquí |
| MockK (`mockkStatic`) | No requiere refactor, pero parcha clases globalmente a nivel de classloader y acopla los tests a la API exacta llamada en lugar del comportamiento |
| **Lectura inyectada + JUnit puro (elegida)** | El fake es una lambda local a cada test, cero dependencias agregadas, firmas públicas sin cambios |

Trade-off aceptado: la única línea que llama a `Settings.Secure` no tiene unit test; la cubre la app de ejemplo corriendo en un dispositivo.

## Correr la app de ejemplo

La app en `example/` muestra un botón que llama a `getIdentifier()` y despliega el valor (o el código de error tipado).

### Prerrequisitos

- **Node.js** 20+
- **JDK 17 o 21** — JDK 24+ rompe el build de React Native/CMake. Si `java -version` muestra 24+, apunta Gradle a un JDK más viejo (Android Studio trae JDK 21 en `<Android Studio>/Contents/jbr/Contents/Home`) vía `JAVA_HOME`, o agrega `org.gradle.java.home=<ruta-jdk>` a `example/android/gradle.properties` después del prebuild.
- **Android SDK** con un emulador o dispositivo conectado. Si Gradle no lo encuentra, define `ANDROID_HOME` o crea `example/android/local.properties` con `sdk.dir=<ruta-sdk>` (default en macOS: `~/Library/Android/sdk`).
- iOS todavía no corre: la implementación Swift está pendiente.

### Pasos

```sh
# 1. Raíz del repo: instalar (el hook prepare compila el TS del módulo a build/,
#    que es lo que Metro sirve — no src/)
npm install

# 2. App de ejemplo
cd example
npm install
npx expo prebuild --platform android   # genera example/android (gitignorado)
npx expo run:android                   # compila, instala y arranca Metro
```

Debe haber un emulador corriendo (o un dispositivo conectado) antes del `run:android`. Si el build falla con un error de JDK o de ubicación del SDK, revisa los Prerrequisitos.

`example/android` es generado — no está commiteado, así que el `prebuild` es obligatorio en un clone fresco. El example resuelve `fintech-security` desde la raíz del repo vía `extraNodeModules` de Metro (ver `example/metro.config.js`); no se necesita `npm link`.
