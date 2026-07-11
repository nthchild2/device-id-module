# fintech-security

*Leer en [español](README.es.md)*

Native module for React Native (Expo Modules API) that returns a unique device identifier through `getIdentifier(): Promise<string>`.

## Design notes

### The first question: what is this identifier for?

The correct API depends on the use case, and some use cases are not solved by an identifier at all:

| Use case | What it needs | The right tool |
|---|---|---|
| Regulatory logging (e.g. CNBV access-device records for Mexican IFPEs) | Stable per install | IDFV / `ANDROID_ID` |
| Device binding for authentication | Not an ID: a hardware-backed key pair | Secure Enclave / Keystore + attestation |
| Fraud prevention (multi-accounting, account takeover) | Survives reinstall/reset | Keychain-persisted UUID (iOS), `ANDROID_ID` (Android), plus server-side signals |
| Correlating users across apps from the same company | Same value across the vendor's apps | IDFV / App Set ID |

I raised this question with the team, and their answers pinned down the requirements:

1. The identifier **must survive app reinstalls**.
2. It does **not** need to survive a factory reset.
3. Per-app scope is enough — it does not need to match across the company's other apps.
4. It identifies the **device**, not the user: it must change when the user moves to a new phone.

That profile rules out IDFV on iOS (it resets on reinstall when it is the vendor's only app) and rules out cross-app mechanisms like App Set ID (out of scope per answer 3). It points to the design implemented here.

### What was ruled out and why

- **IMEI, MAC address, UDID**: dead. IMEI has been blocked for non-system apps since Android 10; MAC returns a constant since Android 6/iOS 7; UDID was removed in iOS 7.
- **IDFA / Advertising ID**: advertising-only by policy, user-resettable, and behind the ATT prompt on iOS. Using it for anything other than ads is grounds for store rejection.
- **DeviceCheck, App Attest, Play Integrity, Key Attestation**: these require a backend that verifies tokens against Apple/Google, so they are out of scope for this exercise.
- **MediaDrm/Widevine ID**: readable without permissions and survives factory reset, but it is a DRM API repurposed for identification. It is not user-resettable, invisible to the user, and it follows the hardware across owners. Google Play policy only tolerates it under the fraud-prevention carve-out and it must be declared in the Data Safety form. Acceptable as a secondary signal in a fraud stack; not acceptable as a primary identifier.

### What this module returns

- **iOS: a UUID generated once and persisted in the Keychain**, with `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly` and non-synchronizable. Keychain items survive app uninstall, which satisfies requirement 1. The `ThisDeviceOnly` + non-synchronizable attributes are what satisfy requirement 4: the item is excluded from iCloud Keychain sync and device-to-device restores, so the value never follows the user to a new phone. It dies on factory reset.
- **Android: `ANDROID_ID`** (SSAID). Scoped per app-signing-key + user + device since Android 8. It satisfies every requirement as-is: survives reinstall, dies on factory reset, per-app scope, and never moves to another device. No permissions, no Google Play Services dependency which is relevant for devices without GMS like Huawei devices.

### How the iOS choice evolved

The first candidate was IDFV: it is the simplest API that satisfies the literal contract (stable per install) and requires no storage. But IDFV resets on reinstall when it is the vendor's only installed app, which fails requirement 1, so the Keychain-persisted UUID became the chosen solution.

IDFV was also considered as a fallback for when the Keychain is unavailable, and discarded: a fallback value has weaker persistence semantics than the primary, and the caller cannot tell which one it received. For a system correlating devices across reinstalls, a hard `ERR_IDENTIFIER_STORAGE_ACCESS` rejection is more useful than a silently degraded identifier.

### Why the Expo Modules API

The brief asks for Expo Modules ideally, or JSI/TurboModules. A single Expo Module covers every consumer without extra bindings:

- It does not require an Expo app — it requires `expo-modules-core`, which installs into any bare React Native app via `npx install-expo-modules`.
- It works on both the legacy bridge and the New Architecture; `expo-modules-core` handles that boundary.

The identifier logic lives in plain Swift/Kotlin classes with no React Native imports. The Expo module is a thin adapter over them. This keeps the native logic unit-testable with XCTest/JUnit.

### OS version support and error handling

No OS-version branching is needed: React Native's own minimums (iOS 15.1+, Android 7+) are far above the introduction of every API used here (`ANDROID_ID`: API 1; Keychain: iOS 2). What the module does handle are runtime conditions.

- `ANDROID_ID` can be null or empty on rare devices.
- Keychain operations can fail with `OSStatus` errors (e.g. shortly after a device restart, before first unlock).

Failures cross the JS boundary as typed error codes (`ERR_IDENTIFIER_UNAVAILABLE`, `ERR_IDENTIFIER_STORAGE_ACCESS`) rather than raw platform messages, so callers can branch on them.

## Installation

| Consumer | Command |
|---|---|
| Expo app | `npx expo install fintech-security` |
| Bare React Native with expo-modules-core | `npm i fintech-security` |
| Bare React Native without Expo | `npx install-expo-modules && npm i fintech-security` |

## Usage

```ts
import FintechSecurity from 'fintech-security';

const id = await FintechSecurity.getIdentifier();
```

## Running the example app

The `example/` app renders a button that calls `getIdentifier()` and displays the value (or the typed error code).

### Prerequisites

- **Node.js** 20+
- **JDK 17 or 21** — JDK 24+ breaks the React Native/CMake build. If `java -version` shows 24+, point Gradle to an older JDK (Android Studio bundles JDK 21 at `<Android Studio>/Contents/jbr/Contents/Home`) via `JAVA_HOME`, or add `org.gradle.java.home=<jdk-path>` to `example/android/gradle.properties` after prebuild.
- **Android SDK** with an emulator or a connected device. If Gradle can't find it, set `ANDROID_HOME` or create `example/android/local.properties` with `sdk.dir=<sdk-path>` (macOS default: `~/Library/Android/sdk`).
- iOS is not runnable yet: the Swift implementation is pending.

### Steps

```sh
# 1. Repo root: install and compile the module's TS (Metro serves build/, not src/)
npm install
npm run build

# 2. Example app
cd example
npm install
npx expo prebuild --platform android   # generates example/android (gitignored)
npx expo run:android                   # builds, installs and starts Metro
```

`example/android` is generated — it is not committed, so `prebuild` is required on a fresh clone. The example resolves `fintech-security` from the repo root via Metro's `extraNodeModules` (see `example/metro.config.js`); no `npm link` is needed.
