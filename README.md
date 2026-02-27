# FreeForm Unified App — Web UI + BLE IMU Integration

> **Single Flutter mobile app** combining FreeFormApp (React Web UI) and FreeFormMobileApp (BLE IMU Logger).

## Architecture Overview

```
┌──────────────────────────────────────────────────┐
│              Flutter Shell App                    │
│                                                  │
│  ┌──────────────────────────────────────────┐     │
│  │  WebView (FreeFormApp React UI)          │     │
│  │  - /home, /workout-select, /progress    │     │
│  │  - /workout-summary?sessionId=...       │     │
│  │                                         │     │
│  │  freeform://ble/start?type=squat ──────────── Native LiveSessionScreen
│  │  freeform://ble/devices ───────────────────── Native DevicesScreen
│  │  freeform://ble/sessions ──────────────────── Native SessionsScreen
│  └──────────────────────────────────────────┘     │
│                                                  │
│  ┌──────────────────────────────────────────┐     │
│  │  Native BLE Layer (flutter_reactive_ble) │     │
│  │  - FF_L / FF_R scan & connect           │     │
│  │  - 200Hz IMU packet recording           │     │
│  │  - L.bin / R.bin file storage           │     │
│  │  - Mock mode for testing                │     │
│  └──────────────────────────────────────────┘     │
│                                                  │
│  Session Stop Flow:                              │
│  1. Generate WorkoutSessionData JSON             │
│  2. Inject into WebView localStorage             │
│  3. Navigate WebView to /workout-summary         │
│  4. React UI shows graphs/metrics automatically  │
└──────────────────────────────────────────────────┘
```

## Key Assumptions

- **Firebase Hosting URL**: Default `https://freeformdb-c3667.web.app` (from `.firebaserc`). Configurable in Settings.
- **Workout Analysis**: Uses statistical approximations from BLE packet data (drop rates, L/R symmetry) rather than full biomechanical AI. Sufficient for functional demo.
- **Heartbeat Data**: Downsampled to ~10Hz, max 200 points, to avoid bloating localStorage.
- **WebView**: Uses `webview_flutter` for Android/iOS compatibility.

## Setup & Run

### Prerequisites

- Flutter SDK ≥ 3.11.0
- Android Studio / Xcode
- Physical device or emulator (BLE requires real device for non-mock mode)

### Steps

1. **Clone / navigate to this project**

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run on device/emulator**
   ```bash
   flutter run
   ```

4. **Configure Web App URL** (Settings screen)
   - Default: `https://freeformdb-c3667.web.app`
   - For local development: `http://YOUR_IP:5173` (Vite dev server)

### FreeFormApp Web UI (for local dev)

If you want to test with a local web server:

```bash
cd D:\FreeForm\FreeFormApp
npm install
npm run dev -- --host 0.0.0.0
```

Then set the Web App URL in Settings to `http://YOUR_LOCAL_IP:5173`.

## Testing Scenarios

### Scenario 1: Mock Mode (No Hardware)

1. Open app → Permissions screen → "Continue to FreeForm"
2. FreeFormApp UI loads in WebView
3. Navigate to "Workout Select" → tap "Squat"
4. Native LiveSessionScreen opens (via deep link)
5. Session auto-starts with mock BLE data (200Hz simulated)
6. Tap "Stop Recording"
7. **Automatic**: WorkoutSessionData injected to WebView → workout-summary page shows graphs
8. Navigate to "Progress" → session appears in history

### Scenario 2: Real BLE (Hardware)

1. Settings → Mock Mode OFF
2. Settings → ensure Web App URL is correct
3. Grant BLE permissions
4. Use FAB (Bluetooth icon) → Devices screen → Scan → Connect FF_L & FF_R
5. Start Session → record real IMU data
6. Stop → same auto-injection flow as mock mode

### Scenario 3: Browser-only (FreeFormApp in browser)

The web changes (nativeLink.ts) ensure `freeform://` is **never** called in a browser.
`window.__FREEFORM_NATIVE__` is only true inside the Flutter WebView.

## Project Structure

```
lib/
├── app.dart                           # App routing (+ /web_shell route)
├── main.dart                          # Entry point
├── core/
│   ├── constants/
│   │   ├── protocol.dart              # BLE protocol constants
│   │   └── uuids.dart                 # BLE UUID constants
│   ├── logging/log.dart               # Logger
│   └── utils/
│       ├── bytes.dart                 # Byte manipulation
│       └── time.dart                  # Time formatting
├── features/
│   ├── ble/                           # BLE scanning, connection, data
│   │   ├── application/
│   │   │   ├── ble_controller.dart    # Riverpod providers
│   │   │   └── packet_parser.dart     # 19B packet parser
│   │   ├── data/
│   │   │   ├── mock_ble_client.dart   # Mock mode (200Hz simulated)
│   │   │   └── reactive_ble_client.dart
│   │   └── domain/
│   │       ├── ble_client.dart        # Abstract interface
│   │       └── models.dart            # BleDevice, etc.
│   ├── session/                       # Recording sessions
│   │   ├── application/session_controller.dart
│   │   ├── data/
│   │   │   ├── drift/                 # SQLite DB (Drift)
│   │   │   ├── session_file_writer.dart
│   │   │   └── session_repository.dart
│   │   └── domain/session.dart
│   ├── settings/                      # App settings (+ webAppUrl)
│   │   ├── application/settings_controller.dart
│   │   └── data/settings_repository.dart
│   ├── upload/                        # Server upload (dio multipart)
│   │   ├── application/upload_controller.dart
│   │   └── data/upload_repository.dart
│   └── webview/                       # NEW: WebView integration
│       └── data/
│           └── workout_session_data_generator.dart
├── ui/
│   ├── screens/
│   │   ├── web_shell_screen.dart      # NEW: WebView shell (home screen)
│   │   ├── devices_screen.dart        # BLE device scan/connect
│   │   ├── live_session_screen.dart   # MODIFIED: + WebView injection
│   │   ├── permissions_screen.dart    # MODIFIED: → web_shell route
│   │   ├── sessions_screen.dart       # BLE session list
│   │   ├── session_detail_screen.dart # Session detail + upload
│   │   └── settings_screen.dart       # MODIFIED: + webAppUrl settings
│   └── widgets/
│       ├── device_card.dart
│       ├── metric_tile.dart
│       └── primary_button.dart
```

## FreeFormApp (Web) Changes

Minimal changes to the React codebase:

1. **`src/lib/nativeLink.ts`** — New utility that checks `window.__FREEFORM_NATIVE__`
2. **`src/pages/workout-select/page.tsx`** — Squat card click uses `startWorkout()` from nativeLink

These changes are backward-compatible: the web app works identically in a browser.

## Settings

| Setting | Key | Default | Description |
|---------|-----|---------|-------------|
| Mock Mode | `mock_mode` | `true` | Simulate BLE without hardware |
| Web App URL | `web_app_url` | `https://freeformdb-c3667.web.app` | URL loaded in WebView |
| Auto Inject | `enable_auto_inject_to_web` | `true` | Auto-send session data to WebView |
| Post-Session Path | `post_session_navigate_path` | `/workout-summary` | WebView route after recording |
| Upload Base URL | `server_base_url` | `http://localhost:8080` | Server for file upload |
| Scan Timeout | `scan_timeout_sec` | `10` | BLE scan duration |
| Sample Rate | `sample_rate_hz` | `200` | Requested IMU sample rate |

## Deep Link Protocol

| URL | Action |
|-----|--------|
| `freeform://ble/devices` | Open native BLE device scanner |
| `freeform://ble/start?type=squat` | Open LiveSession with workout type |
| `freeform://ble/sessions` | Open native session history |

## BLE Preserved Features

All original FreeFormMobileApp features are preserved:
- ✅ FF_L / FF_R scanning and connection
- ✅ START / STOP / SET_RATE commands
- ✅ 19-byte IMU packet parsing (200Hz)
- ✅ Sequence drop calculation
- ✅ L.bin / R.bin file storage
- ✅ session.json metadata
- ✅ Drift SQLite session database
- ✅ Mock mode (simulated BLE)
- ✅ Dio multipart upload
- ✅ Android/iOS BLE permissions
