# FreeFormAllin — Integrated Mobile App for BLE IMU Capture and Web-Based Workout Flow

> Flutter mobile shell that combines WebView UX, native BLE sensor capture, local session storage, upload support, and native Google sign-in bridging

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.11-0175C2?logo=dart&logoColor=white)
![BLE](https://img.shields.io/badge/BLE-Dual%20IMU-blueviolet)
![Riverpod](https://img.shields.io/badge/State-Riverpod-4F46E5)

---

## Overview

FreeFormAllin is the integrated mobile application layer for the FreeForm ecosystem.

Instead of splitting the product into a separate web experience and a separate sensor utility, this repository combines both in one Flutter app:

- a WebView shell for the workout/product web flow
- native BLE data collection from two IMU nodes (`FF_L`, `FF_R`)
- local storage for raw binary sessions and metadata
- optional upload to a backend API
- native Google authentication to work around embedded WebView OAuth limitations

The result is a single app that can guide a workout, collect motion data, and hand the result back to the web layer.

## Core Features

| Feature | Details |
| --- | --- |
| Web shell | Loads the FreeForm web app inside `WebShellScreen` |
| Native deep-link bridge | Intercepts `freeform://` links and routes into BLE-native screens |
| Dual-node BLE capture | Connects to `FF_L` and `FF_R` and receives notify streams |
| Packet parsing | Reassembles and parses 19-byte IMU packets with sequence tracking |
| Session persistence | Saves `L.bin`, `R.bin`, metadata, and Drift-backed session records |
| Upload flow | Sends saved session files to a backend multipart endpoint |
| Mock mode | Simulates sensors for UI and logic testing without hardware |
| Native auth bridge | Uses Google Sign-In and Firebase auth for WebView login handoff |

## End-to-End Flow

```text
Launch App
   |
   v
Permissions / Settings
   |
   v
WebShellScreen
   |
   +--> Web app requests native BLE flow via freeform://...
   |
   v
Device Scan / Connect (FF_L, FF_R)
   |
   v
Live Session Recording
   |
   +--> Parse IMU packets
   +--> Track drops / PPS
   +--> Write L.bin / R.bin
   +--> Save session metadata
   |
   v
Session Stop
   |
   +--> Generate workout session summary
   +--> Inject summary back into WebView storage
   `--> Optional upload to backend
```

## Repository Layout

```text
FreeFormAllin/
|- lib/
|  |- app.dart
|  |- main.dart
|  |- core/
|  |  |- constants/
|  |  |  |- protocol.dart
|  |  |  `- uuids.dart
|  |  |- logging/log.dart
|  |  `- utils/
|  |- features/
|  |  |- auth/native_auth_service.dart
|  |  |- ble/
|  |  |  |- application/ble_controller.dart
|  |  |  |- application/packet_parser.dart
|  |  |  |- data/mock_ble_client.dart
|  |  |  |- data/reactive_ble_client.dart
|  |  |  `- domain/
|  |  |- session/
|  |  |- settings/
|  |  |- upload/
|  |  `- webview/data/workout_session_data_generator.dart
|  `- ui/
|     |- screens/
|     `- widgets/
|- android/
|- ios/
|- test/
`- pubspec.yaml
```

## BLE Protocol

### IMU packet format

The app expects a 19-byte packet:

| Byte range | Field | Type |
| --- | --- | --- |
| `0` | `node_id` | `0x4C` for left, `0x52` for right |
| `1-2` | `seq` | `uint16` little-endian |
| `3-6` | `timestamp_us` | `uint32` little-endian |
| `7-12` | `ax`, `ay`, `az` | signed `int16` |
| `13-18` | `gx`, `gy`, `gz` | signed `int16` |

### Packet processing

`packet_parser.dart` handles:

- exact packet parsing
- partial packet buffering
- concatenated packet reassembly
- sequence-gap tracking for drop-rate estimation

## Session Storage Model

Per session, the app stores:

- `L.bin`
- `R.bin`
- session metadata JSON
- Drift database rows for stats and upload state

This keeps the raw sensor stream intact while also making it easy to display session lists, detail pages, and upload status inside the UI.

## Tech Stack

- Flutter / Dart
- Riverpod
- `flutter_reactive_ble`
- Drift + SQLite
- Dio
- SharedPreferences
- WebView
- Firebase Auth
- Google Sign-In

## Getting Started

### Prerequisites

- Flutter SDK
- Android Studio or Xcode
- physical BLE devices if you want real capture
- Firebase/Google Sign-In setup if you want native auth bridge

### Install and run

```bash
git clone https://github.com/sejun42/FreeFormAllin.git
cd FreeFormAllin
flutter pub get
flutter run
```

### Recommended setup notes

- Use **Mock Mode** for development without hardware.
- Configure the in-app web URL for your FreeForm web environment.
- Add Firebase platform config files before testing native Google sign-in.
- Set your backend upload URL in Settings if you want session upload enabled.

## Development Notes

This repository is most useful when treated as a native integration layer:

- the web app owns much of the user-facing workout flow
- the Flutter shell owns BLE, storage, native auth, and upload
- the bridge between the two is a key part of the product design

That makes FreeFormAllin different from a standalone data logger. It is closer to a native companion runtime for a larger web-based fitness platform.

## Contact

- Sejun Yoon — [sejun1324@gmail.com](mailto:sejun1324@gmail.com)
- GitHub — [@sejun42](https://github.com/sejun42)
