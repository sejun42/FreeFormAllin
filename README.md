# FreeFormAllin

FreeFormAllin is a unified Flutter mobile app that combines:

- a WebView shell for the FreeForm web product flow
- native BLE collection from two IMU nodes (`FF_L`, `FF_R`)
- local session persistence (`L.bin`, `R.bin`, `session.json`, SQLite/Drift)
- optional upload to a backend API
- native Google Sign-In bridging for WebView OAuth limitations

This repository is focused on running one integrated app on Android/iOS for end-to-end workout capture and review.

## Table of Contents

1. [Project Goals](#project-goals)
2. [Feature Summary](#feature-summary)
3. [End-to-End Flow](#end-to-end-flow)
4. [Architecture](#architecture)
5. [Native-Web Contract](#native-web-contract)
6. [BLE Protocol](#ble-protocol)
7. [Session Storage Model](#session-storage-model)
8. [Upload API Contract](#upload-api-contract)
9. [Configuration and Settings](#configuration-and-settings)
10. [Project Structure](#project-structure)
11. [Prerequisites](#prerequisites)
12. [Setup and Run](#setup-and-run)
13. [Testing](#testing)
14. [Troubleshooting](#troubleshooting)
15. [Security and Production Notes](#security-and-production-notes)
16. [Development Notes](#development-notes)

## Project Goals

- Provide a single mobile shell that can host the web UX and still access native BLE.
- Capture synchronized-ish left/right IMU streams from BLE devices.
- Persist raw binary sensor payloads for later analysis and backend upload.
- Push a post-session summary into the web layer automatically.
- Keep a mock mode for development without hardware.

## Feature Summary

### Web shell and routing

- App starts on a permissions screen and then enters `WebShellScreen`.
- Web app is loaded via `webview_flutter`.
- Native routes are available for:
  - device scanning/connection
  - live recording session
  - session history/details
  - app settings

### Deep link interception from web to native

`freeform://` links inside WebView are intercepted and routed natively:

- `freeform://ble/devices` -> Devices screen
- `freeform://ble/start?type=squat` -> Live session (with workout type)
- `freeform://ble/sessions` -> Session list

### Native Google authentication bridge

Because embedded WebView OAuth can fail or be blocked, the app:

- intercepts Google OAuth navigations in WebView
- runs `google_sign_in` + `firebase_auth` natively
- writes auth payload into WebView storage for the web layer to consume

### BLE data capture and live metrics

- Scan for `FF_L` and `FF_R` using a fixed custom BLE service UUID.
- Connect to both nodes (left and right).
- Subscribe to notify stream (19-byte IMU packets).
- Parse packet stream with reassembly support (partial/concatenated packets).
- Compute drop statistics from sequence gaps.
- Show live stats:
  - packets
  - PPS
  - drop rate
  - last raw packet values

### Session persistence

Per session:

- create DB row (Drift)
- create session folder
- append raw notify payloads into:
  - `L.bin`
  - `R.bin`
- write metadata `session.json`
- close/update session summary stats in DB on stop

### Web summary injection after session stop

When recording stops (if enabled in settings):

1. Generate workout summary JSON (`WorkoutSessionDataGenerator`)
2. Inject into WebView localStorage/sessionStorage
3. Navigate WebView to post-session page (`/workout-summary` by default)
4. Return from native screen back to web shell

### Upload support

Session directory contents can be uploaded to backend:

- endpoint: `POST {baseUrl}/api/sessions/upload`
- multipart with:
  - field: `session_id`
  - files: all files in session directory

## End-to-End Flow

### Primary flow

1. Launch app
2. Grant BLE permissions (or use mock mode)
3. Web shell opens configured web app URL
4. Web triggers native BLE deep link (`freeform://...`) or user taps BLE FAB
5. Connect `FF_L` and `FF_R`
6. Start recording
7. Receive and persist BLE data
8. Stop recording
9. Inject generated summary to web local storage
10. Navigate web page to workout summary
11. Optional: review session detail and upload

### Mock mode flow

With mock mode on:

- no real hardware required
- simulated `FF_L`/`FF_R` scan, connection, and 200 Hz data stream
- intentional small packet drops are included for realism

## Architecture

### High-level view

```text
Flutter App
|- PermissionsScreen
|- WebShellScreen (WebView)
|  |- Loads configured Web App URL + native_shell=true
|  |- Injects JS bridge
|  |- Intercepts freeform:// deep links
|  |- Intercepts Google OAuth URLs -> native sign-in
|
|- Native BLE Layer
|  |- ble_controller.dart (Riverpod state)
|  |- ReactiveBleClient (real hardware)
|  |- MockBleClient (simulated hardware)
|  |- PacketParser + SeqTracker
|
|- Session Layer
|  |- SessionController
|  |- SessionRepository (Drift + filesystem)
|  |- SessionFileWriter (L.bin, R.bin)
|
|- Upload Layer
|  |- UploadController
|  |- UploadRepository (Dio multipart)
|
`- Settings Layer
   `- SharedPreferences-backed app settings
```

### State management

- Riverpod is used for providers and state notifiers.
- Key provider groups:
  - BLE adapter/scan/connection/live stats
  - session state and session list
  - app settings
  - upload state
  - shared WebView controller reference

## Native-Web Contract

### Query parameter

When loading the web app, appends:

- `native_shell=true`

This allows web code to detect native shell context.

### Injected JS globals/channel

On page load the app injects:

- `window.__FREEFORM_NATIVE__ = true`
- `window.__FREEFORM_REQUEST_NATIVE_AUTH__(provider)` helper
- JS channel: `FreeFormNative` for message passing

### Auth payload storage

Native sign-in writes:

- `localStorage["freeform_native_auth"]`

Contains token payload (`idToken`, `accessToken`, provider, timestamp).

### Workout session storage keys

On session stop injection:

- `localStorage["freeform.activeWorkoutSession"]`
- `localStorage["freeform.workoutSessionHistory"]`
- mirrored to `sessionStorage` where possible

History is deduped by `sessionId` and capped at 500 entries.

## BLE Protocol

### UUIDs

Defined in `lib/core/constants/uuids.dart`.

- Service: `a1b2c3d4-e5f6-47a8-9abc-1234567890ab`
- CMD characteristic (write): `...90ac`
- DATA characteristic (notify): `...90ad`
- META characteristic (read): `...90ae`
- Expected names: `FF_L`, `FF_R`

### Command opcodes

Defined in `lib/core/constants/protocol.dart`.

- `0x01` START payload format: `[cmd, session_uuid_16bytes]`
- `0x02` STOP
- `0x03` PING
- `0x04` SET_RATE payload format: `[cmd, rate_hz_uint16_le]`

### IMU packet format (19 bytes)

```text
Byte 0      : node_id (0x4C='L', 0x52='R')
Bytes 1-2   : seq (uint16 LE)
Bytes 3-6   : timestamp_us (uint32 LE)
Bytes 7-8   : ax (int16 LE)
Bytes 9-10  : ay (int16 LE)
Bytes 11-12 : az (int16 LE)
Bytes 13-14 : gx (int16 LE)
Bytes 15-16 : gy (int16 LE)
Bytes 17-18 : gz (int16 LE)
```

### Drop rate logic

`SeqTracker` tracks sequence continuity with wrap-around handling:

- expected next sequence is previous + 1 (`uint16`)
- gap contributes to drop count if gap is within a reasonable threshold
- drop rate formula:
  - `drops / (packets + drops)`

## Session Storage Model

### File system layout

Under app documents directory:

```text
freeform/
`- sessions/
   `- <session_uuid>/
      |- session.json
      |- L.bin
      `- R.bin
```

`session.json` example fields:

- `session_id`
- `started_at`
- `protocol_version`
- `app_version`

### SQLite schema (Drift)

Tables:

- `sessions`
  - ids, start/end timestamps
  - left/right device ids
  - packet/drop counters
  - estimated Hz values
  - directory path
  - upload status/error
- `devices`
  - id, name, last seen, metadata JSON

### Generated workout summary

`WorkoutSessionDataGenerator` produces web-consumable summary JSON from:

- session metadata
- packet/drop statistics
- synthetic metric curves (for current demo behavior)

It includes:

- safety score and metric blocks
- warning list
- IMU-derived chart arrays
- heartbeat-like downsampled series (capped)
- optional raw frame samples

## Upload API Contract

Current client behavior:

- method: `POST`
- path: `/api/sessions/upload`
- content type: multipart/form-data
- fields:
  - `session_id` (string)
  - multiple `files` parts (all files from session folder)
- success condition: status code `200` or `201`

If upload fails, error text is persisted on the session row.

## Configuration and Settings

Settings are persisted in `SharedPreferences`.

| Key | Purpose | Default |
| --- | --- | --- |
| `mock_mode` | Use simulated BLE devices/data | `true` |
| `web_app_url` | URL loaded in WebView | `https://freeformdb-c3667.web.app` |
| `enable_auto_inject_to_web` | Auto push session summary to WebView | `true` |
| `post_session_navigate_path` | Web path after stop | `/workout-summary` |
| `server_base_url` | Upload server base URL | `http://localhost:8080` |
| `scan_timeout_sec` | BLE scan timeout setting | `10` |
| `sample_rate_hz` | Requested sample rate setting | `200` |

## Project Structure

```text
lib/
|- app.dart
|- main.dart
|- core/
|  |- constants/
|  |  |- protocol.dart
|  |  `- uuids.dart
|  |- logging/log.dart
|  `- utils/
|     |- bytes.dart
|     `- time.dart
|- features/
|  |- auth/native_auth_service.dart
|  |- ble/
|  |  |- application/
|  |  |  |- ble_controller.dart
|  |  |  `- packet_parser.dart
|  |  |- data/
|  |  |  |- mock_ble_client.dart
|  |  |  `- reactive_ble_client.dart
|  |  `- domain/
|  |     |- ble_client.dart
|  |     `- models.dart
|  |- session/
|  |  |- application/session_controller.dart
|  |  |- data/
|  |  |  |- drift/
|  |  |  |  |- app_db.dart
|  |  |  |  |- app_db.g.dart
|  |  |  |  `- tables.dart
|  |  |  |- session_file_writer.dart
|  |  |  `- session_repository.dart
|  |  `- domain/session.dart
|  |- settings/
|  |  |- application/settings_controller.dart
|  |  `- data/settings_repository.dart
|  |- upload/
|  |  |- application/upload_controller.dart
|  |  `- data/upload_repository.dart
|  `- webview/
|     `- data/workout_session_data_generator.dart
`- ui/
   |- screens/
   |  |- permissions_screen.dart
   |  |- web_shell_screen.dart
   |  |- devices_screen.dart
   |  |- live_session_screen.dart
   |  |- sessions_screen.dart
   |  |- session_detail_screen.dart
   |  `- settings_screen.dart
   `- widgets/
      |- device_card.dart
      |- metric_tile.dart
      `- primary_button.dart
```

## Prerequisites

### Required tools

- Flutter SDK with Dart `^3.11.0` compatibility
- Android Studio (for Android builds)
- Xcode (for iOS builds/macOS only)
- JDK 17 (Android Gradle config uses Java 17)

### Runtime notes

- Real BLE capture requires a physical mobile device.
- Mock mode can run on emulator/simulator for UI and flow testing.
- Stable network connectivity is required for web app loading and upload.

## Setup and Run

### 1) Install dependencies

```bash
flutter pub get
```

### 2) Run app

```bash
flutter run
```

### 3) Configure web URL inside app

Open Settings and set `Web App URL`:

- production example: `https://freeformdb-c3667.web.app`
- local dev example: `http://<your-lan-ip>:3000`

If using a local web server, phone and dev machine must be on same network.

### 4) Optional local web app development

If your web app project is in another directory (example):

```bash
cd D:\FreeForm\FreeFormApp
npm install
npm run dev -- --host 0.0.0.0
```

Then set mobile app `Web App URL` accordingly.

## Firebase and Google Sign-In Setup

This app initializes Firebase and uses native Google Sign-In.

Checklist:

1. Firebase project is created.
2. Google Sign-In provider enabled in Firebase Auth.
3. Android `google-services.json` is placed at:
   - `android/app/google-services.json`
4. iOS `GoogleService-Info.plist` is placed at:
   - `ios/Runner/GoogleService-Info.plist`
5. Platform-specific OAuth client setup (SHA certs, bundle id, URL schemes) is completed.

Without proper Firebase/OAuth setup, native Google sign-in may fail.

## Testing

Run tests:

```bash
flutter test
```

Current tests cover:

- `PacketParser` correctness
  - single packet parse
  - concatenated packet parse
  - partial packet reassembly
  - signed value handling
- `SeqTracker` logic
  - drops
  - wrap-around
  - reset behavior
- `SessionFileWriter`
  - file creation
  - append behavior
  - close behavior
  - larger write volume
- basic widget smoke test

## Troubleshooting

### WebView shows load error

- Verify `Web App URL` in Settings.
- Ensure device can access that URL in mobile browser.
- Retry from error screen.
- Check if HTTPS certificate or DNS issue exists.

### OAuth does not complete in web page

- Expected in embedded browser for some providers.
- Confirm native Google sign-in popup appears.
- Validate Firebase/OAuth config for current package/bundle id.

### Cannot find BLE devices

- Confirm devices advertise expected name and service UUID.
- Ensure Bluetooth/location permissions are granted.
- Ensure BLE is enabled on phone.
- Disable mock mode when using real devices.

### Session recorded but web summary did not appear

- Check `Auto Inject to Web` is enabled.
- Verify `Post-Session Nav Path` is valid on web app.
- Verify WebView is still alive (not null controller path).

### Upload fails

- Check `Upload Base URL`.
- Confirm backend route `/api/sessions/upload` exists.
- Ensure device can reach backend network endpoint.
- Inspect saved `uploadError` from session detail.

### iOS build/auth issues

- Confirm `GoogleService-Info.plist` exists in Runner target.
- Ensure Info.plist contains Bluetooth usage descriptions.
- Run `pod install` if CocoaPods state is stale.

## Security and Production Notes

- Use HTTPS for web URL and upload server in production.
- Review what is stored in localStorage/sessionStorage for auth/session.
- Avoid committing sensitive files unintentionally.
- Consider token lifetime and logout synchronization between web/native.
- Validate backend auth on upload endpoint before accepting files.

## Development Notes

- `isMockModeProvider` controls whether BLE uses mock or reactive client.
- `webViewControllerProvider` enables cross-screen WebView JS injection/navigation.
- Session stop currently computes summary from in-memory pre-stop stats.
- Generated workout analysis is heuristic/demo-oriented, not biomechanical truth.

Recommended next engineering improvements:

- add integration tests for native-web bridge behavior
- add explicit command for SET_RATE to match settings value at session start
- add retry/backoff and auth headers for upload
- add structured analytics/log export for field debugging

