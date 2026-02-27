# FreeFormAllin

FreeFormAllin은 다음을 하나로 통합한 Flutter 모바일 앱입니다.

- FreeForm 웹 서비스를 띄우는 WebView 셸
- `FF_L`, `FF_R` 두 개 IMU 노드의 네이티브 BLE 수집
- 로컬 세션 저장(`L.bin`, `R.bin`, `session.json`, SQLite/Drift)
- 백엔드 업로드(선택)
- WebView OAuth 제약을 우회하는 네이티브 Google 로그인 브리지

이 저장소의 목적은 Android/iOS에서 웹+BLE+세션 관리까지 한 앱으로 일관되게 동작시키는 것입니다.

## 목차

1. [프로젝트 목표](#프로젝트-목표)
2. [주요 기능 요약](#주요-기능-요약)
3. [End-to-End 동작 흐름](#end-to-end-동작-흐름)
4. [아키텍처](#아키텍처)
5. [네이티브-웹 계약(Contract)](#네이티브-웹-계약contract)
6. [BLE 프로토콜](#ble-프로토콜)
7. [세션 저장 모델](#세션-저장-모델)
8. [업로드 API 계약](#업로드-api-계약)
9. [설정(Configuration)](#설정configuration)
10. [프로젝트 구조](#프로젝트-구조)
11. [사전 준비](#사전-준비)
12. [설치 및 실행](#설치-및-실행)
13. [테스트](#테스트)
14. [문제 해결 가이드](#문제-해결-가이드)
15. [보안 및 운영 주의사항](#보안-및-운영-주의사항)
16. [개발 메모](#개발-메모)

## 프로젝트 목표

- 웹 UX를 유지하면서도 네이티브 BLE 기능을 함께 제공
- 좌/우 IMU BLE 스트림을 안정적으로 수집
- 원시 바이너리 센서 데이터를 세션 단위로 보존
- 세션 종료 후 웹 요약 화면으로 자동 연동
- 하드웨어 없이 개발 가능한 Mock 모드 유지

## 주요 기능 요약

### Web 셸 및 화면 라우팅

- 앱 시작 화면은 권한 화면(`PermissionsScreen`)입니다.
- 이후 `WebShellScreen`에서 WebView로 웹 앱을 로드합니다.
- 네이티브 화면 라우트:
  - 디바이스 스캔/연결
  - 라이브 세션 기록
  - 세션 목록/상세
  - 앱 설정

### 웹 -> 네이티브 Deep Link 인터셉트

WebView 내부 `freeform://` 링크를 네이티브 라우트로 변환합니다.

- `freeform://ble/devices` -> 디바이스 화면
- `freeform://ble/start?type=squat` -> 라이브 세션 화면(운동 타입 전달)
- `freeform://ble/sessions` -> 세션 목록 화면

### 네이티브 Google 인증 브리지

임베디드 WebView에서 OAuth가 제한될 수 있어 앱이 다음을 수행합니다.

- WebView의 Google OAuth URL 이동을 감지
- `google_sign_in` + `firebase_auth` 네이티브 로그인 수행
- 토큰/인증 정보를 WebView 스토리지로 전달

### BLE 수집 및 실시간 지표

- 고정 UUID 서비스 기준으로 `FF_L`, `FF_R` 스캔
- 좌/우 노드 연결
- Notify 데이터(19바이트 IMU 패킷) 구독
- 부분 패킷/결합 패킷 재조립 파싱
- 시퀀스 갭 기반 드롭률 계산
- 실시간 표시 지표:
  - packets
  - PPS
  - drop rate
  - 마지막 raw IMU 값

### 세션 영속화

세션 단위로 아래를 저장합니다.

- Drift DB 세션 레코드 생성
- 세션 폴더 생성
- 원시 notify payload를 아래 파일로 append:
  - `L.bin`
  - `R.bin`
- `session.json` 메타데이터 작성
- 세션 종료 시 DB 요약 통계 업데이트

### 세션 종료 후 Web 요약 자동 주입

세션 정지 시(설정 ON 기준):

1. `WorkoutSessionDataGenerator`로 요약 JSON 생성
2. WebView localStorage/sessionStorage에 주입
3. 기본 `/workout-summary` 경로로 이동
4. 네이티브 화면을 닫고 Web 셸로 복귀

### 업로드 기능

세션 폴더 전체를 multipart로 서버에 업로드할 수 있습니다.

- endpoint: `POST {baseUrl}/api/sessions/upload`
- form-data:
  - `session_id`
  - 세션 폴더 내 파일 전체(`files` 반복)

## End-to-End 동작 흐름

### 기본 시나리오

1. 앱 실행
2. BLE 권한 허용(또는 Mock 모드 사용)
3. Web 셸에서 설정된 웹 URL 로드
4. 웹에서 `freeform://...` 호출 또는 앱 내 BLE FAB 탭
5. `FF_L`, `FF_R` 연결
6. 세션 시작
7. BLE 데이터 수신 및 파일 저장
8. 세션 종료
9. WebView에 세션 요약 주입
10. 웹 요약 화면 이동
11. 필요 시 세션 상세에서 업로드

### Mock 모드 시나리오

Mock 모드 ON일 때:

- 실제 하드웨어 없이 UI/플로우 테스트 가능
- 가상 `FF_L`/`FF_R` 스캔/연결 동작
- 200Hz 유사 데이터 + 소량 의도적 드롭 생성

## 아키텍처

### 상위 구조

```text
Flutter App
|- PermissionsScreen
|- WebShellScreen (WebView)
|  |- 웹 앱 URL + native_shell=true 로드
|  |- JS 브리지 주입
|  |- freeform:// 딥링크 인터셉트
|  |- Google OAuth URL 인터셉트 -> 네이티브 로그인
|
|- Native BLE Layer
|  |- ble_controller.dart (Riverpod 상태)
|  |- ReactiveBleClient (실기기 BLE)
|  |- MockBleClient (가상 BLE)
|  |- PacketParser + SeqTracker
|
|- Session Layer
|  |- SessionController
|  |- SessionRepository (Drift + 파일시스템)
|  |- SessionFileWriter (L.bin, R.bin)
|
|- Upload Layer
|  |- UploadController
|  `- UploadRepository (Dio multipart)
|
`- Settings Layer
   `- SharedPreferences 기반 설정 저장
```

### 상태 관리

- Riverpod 기반 Provider/StateNotifier를 사용합니다.
- 주요 상태 범주:
  - BLE 어댑터/스캔/연결/실시간 통계
  - 세션 상태 및 세션 목록
  - 앱 설정
  - 업로드 상태
  - 전역 WebViewController 참조

## 네이티브-웹 계약(Contract)

### WebView 로드 시 Query 파라미터

- `native_shell=true`

웹 레이어에서 네이티브 셸 컨텍스트를 감지할 때 사용합니다.

### 주입되는 JS 전역 및 채널

페이지 로드 후 앱이 주입합니다.

- `window.__FREEFORM_NATIVE__ = true`
- `window.__FREEFORM_REQUEST_NATIVE_AUTH__(provider)`
- JS 채널: `FreeFormNative`

### 인증 정보 저장 키

네이티브 로그인 후 저장:

- `localStorage["freeform_native_auth"]`

포함 정보: `idToken`, `accessToken`, provider, timestamp

### 운동 세션 주입 키

세션 종료 후 저장:

- `localStorage["freeform.activeWorkoutSession"]`
- `localStorage["freeform.workoutSessionHistory"]`
- 가능하면 `sessionStorage`에도 동기 저장

히스토리는 `sessionId` 중복 제거 후 최대 500개로 제한됩니다.

## BLE 프로토콜

### UUID

`lib/core/constants/uuids.dart` 기준:

- Service: `a1b2c3d4-e5f6-47a8-9abc-1234567890ab`
- CMD Characteristic(write): `...90ac`
- DATA Characteristic(notify): `...90ad`
- META Characteristic(read): `...90ae`
- 기대 디바이스 이름: `FF_L`, `FF_R`

### 명령 Opcode

`lib/core/constants/protocol.dart` 기준:

- `0x01` START: `[cmd, session_uuid_16bytes]`
- `0x02` STOP
- `0x03` PING
- `0x04` SET_RATE: `[cmd, rate_hz_uint16_le]`

### IMU 패킷 포맷(19 bytes)

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

### 드롭률 계산

`SeqTracker` 동작:

- 기대 seq = 이전 seq + 1 (`uint16` wrap-around 고려)
- 기대값과 다르면 gap을 drop으로 누적(비정상적으로 큰 gap 제외)
- drop rate:
  - `drops / (packets + drops)`

## 세션 저장 모델

### 파일 저장 경로

앱 문서 디렉터리 하위:

```text
freeform/
`- sessions/
   `- <session_uuid>/
      |- session.json
      |- L.bin
      `- R.bin
```

`session.json` 주요 필드:

- `session_id`
- `started_at`
- `protocol_version`
- `app_version`

### SQLite 스키마(Drift)

테이블:

- `sessions`
  - 세션 ID, 시작/종료 시각
  - 좌/우 디바이스 ID
  - packet/drop 카운트
  - 추정 Hz
  - 저장 디렉터리 경로
  - 업로드 상태/오류
- `devices`
  - 디바이스 ID, 이름, 마지막 탐지 시각, 메타 JSON

### Web 요약 데이터 생성

`WorkoutSessionDataGenerator`가 아래 정보를 기반으로 Web 호환 JSON을 생성합니다.

- 세션 메타
- packet/drop 통계
- 차트/점수용 파생 데이터(현재 데모용 heuristic 포함)

포함 항목:

- 안전 점수 및 세부 metric
- 경고(warnings)
- IMU 관련 시계열/비교 데이터
- downsample heartbeat 유사 데이터
- raw frame 샘플(옵션)

## 업로드 API 계약

클라이언트 현재 구현:

- Method: `POST`
- Path: `/api/sessions/upload`
- Content-Type: `multipart/form-data`
- Form fields:
  - `session_id` (string)
  - `files` (세션 폴더의 모든 파일)
- 성공 기준: HTTP `200` 또는 `201`

실패 시 오류 문자열을 세션 레코드의 `uploadError`에 저장합니다.

## 설정(Configuration)

설정은 `SharedPreferences`에 저장됩니다.

| Key | 의미 | 기본값 |
| --- | --- | --- |
| `mock_mode` | 가상 BLE 사용 여부 | `true` |
| `web_app_url` | WebView 로드 URL | `https://freeformdb-c3667.web.app` |
| `enable_auto_inject_to_web` | 세션 종료 후 Web 자동 주입 | `true` |
| `post_session_navigate_path` | 종료 후 이동 웹 경로 | `/workout-summary` |
| `server_base_url` | 업로드 서버 Base URL | `http://localhost:8080` |
| `scan_timeout_sec` | 스캔 타임아웃 설정 | `10` |
| `sample_rate_hz` | 샘플레이트 설정값 | `200` |

## 프로젝트 구조

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

## 사전 준비

### 필수 툴

- Flutter SDK (Dart `^3.11.0` 호환)
- Android Studio
- Xcode(macOS/iOS 빌드 시)
- JDK 17 (Android 설정 기준)

### 런타임 참고

- 실 BLE 수집은 실제 모바일 기기가 필요합니다.
- Mock 모드는 에뮬레이터/시뮬레이터에서 테스트 가능합니다.
- 웹 로드/업로드를 위해 네트워크 접근이 필요합니다.

## 설치 및 실행

### 1) 의존성 설치

```bash
flutter pub get
```

### 2) 앱 실행

```bash
flutter run
```

### 3) 앱 내부 웹 URL 설정

Settings에서 `Web App URL` 지정:

- 운영 예시: `https://freeformdb-c3667.web.app`
- 로컬 예시: `http://<내 LAN IP>:3000`

로컬 웹 서버 사용 시 모바일 기기와 개발 PC가 같은 네트워크에 있어야 합니다.

### 4) 웹 앱 로컬 개발(선택)

예시 경로:

```bash
cd D:\FreeForm\FreeFormApp
npm install
npm run dev -- --host 0.0.0.0
```

그 후 앱의 `Web App URL`을 해당 주소로 설정합니다.

## Firebase / Google Sign-In 설정

앱은 Firebase 초기화 및 네이티브 Google 로그인을 사용합니다.

체크리스트:

1. Firebase 프로젝트 생성
2. Firebase Auth에서 Google provider 활성화
3. Android 파일 배치:
   - `android/app/google-services.json`
4. iOS 파일 배치:
   - `ios/Runner/GoogleService-Info.plist`
5. 플랫폼별 OAuth 설정:
   - Android SHA 인증서 등록
   - iOS 번들 ID/URL Scheme 설정

설정이 누락되면 네이티브 Google 로그인 실패 가능성이 높습니다.

## 테스트

실행:

```bash
flutter test
```

현재 포함된 테스트 범위:

- `PacketParser`
  - 단일 패킷 파싱
  - 결합 패킷 파싱
  - 부분 패킷 재조립
  - signed int16 처리
- `SeqTracker`
  - drop 계산
  - wrap-around 처리
  - reset 동작
- `SessionFileWriter`
  - 파일 생성
  - append 동작
  - close 동작
  - 대량 쓰기
- 기본 위젯 스모크 테스트

## 문제 해결 가이드

### WebView 로드 실패

- Settings의 `Web App URL` 확인
- 모바일 브라우저에서 URL 직접 접속 확인
- 에러 화면에서 Retry 실행
- DNS/HTTPS 인증서 문제 여부 확인

### OAuth 완료 안 됨

- WebView 내 OAuth 제한은 일반적으로 발생 가능
- 네이티브 Google 로그인 팝업이 뜨는지 확인
- Firebase/OAuth 설정(패키지/번들 기준) 재검증

### BLE 디바이스가 보이지 않음

- 디바이스 광고 이름/Service UUID 확인
- Bluetooth/Location 권한 허용 확인
- 휴대폰 Bluetooth ON 확인
- 실기기 테스트 시 Mock 모드 OFF 확인

### 세션은 저장됐는데 웹 요약이 안 뜸

- `Auto Inject to Web` ON 여부 확인
- `Post-Session Nav Path` 유효 경로인지 확인
- WebViewController가 정상 유지되는지 로그 확인

### 업로드 실패

- `Upload Base URL` 확인
- 서버에 `/api/sessions/upload` 라우트 존재 여부 확인
- 디바이스에서 서버 네트워크 접근 가능 여부 확인
- 세션 상세의 `uploadError` 내용 확인

### iOS 빌드/인증 이슈

- `GoogleService-Info.plist` Runner 타깃 포함 여부 확인
- Info.plist Bluetooth usage description 확인
- CocoaPods 캐시/설치 상태 문제 시 `pod install` 재실행

## 보안 및 운영 주의사항

- 운영 환경에서는 웹 URL/업로드 URL 모두 HTTPS 사용 권장
- localStorage/sessionStorage에 저장되는 인증 데이터 범위 점검
- 민감 파일 커밋 방지
- 토큰 만료/로그아웃 동기화 정책 설계 권장
- 업로드 API 서버 측 인증/검증 필수

## 개발 메모

- `isMockModeProvider`로 Mock/실BLE 클라이언트 전환
- `webViewControllerProvider`로 화면 간 WebView 제어 공유
- 세션 종료 시 pre-stop 통계 기반으로 요약 생성
- 현재 분석 점수는 데모/히ュー리스틱 성격(의학/운동역학 정확도 보장 아님)

추가 개선 권장 항목:

- 네이티브-웹 브리지 통합 테스트 강화
- 세션 시작 시 설정값 기반 `SET_RATE` 실제 송신 연동
- 업로드 재시도/백오프 및 인증 헤더 지원
- 현장 디버깅용 구조화 로그/진단 내보내기

