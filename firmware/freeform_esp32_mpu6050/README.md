# FreeForm ESP32 + MPU6050 Firmware

ESP32 DevKit과 MPU6050 IMU를 FreeFormAllin Flutter 앱의 BLE 센서 노드로 동작시키는 Arduino 펌웨어입니다.

이 펌웨어는 앱의 기존 BLE 프로토콜을 바꾸지 않습니다. ESP32가 `FF_L` 또는 `FF_R` 이름으로 광고되고, 앱에서 `START` 명령을 받으면 MPU6050 raw accel/gyro 값을 19-byte packet으로 만들어 `DATA` characteristic notify로 전송합니다.

## 지원 하드웨어

- MCU: ESP32 DevKit 계열
- IMU: MPU6050 I2C 모듈
- 통신: BLE Peripheral

## 회로 연결

| ESP32 | MPU6050 |
| --- | --- |
| 3.3V | VCC |
| GND | GND |
| GPIO 21 | SDA |
| GPIO 22 | SCL |

주의:

- ESP32 실험에서는 MPU6050 VCC를 3.3V에 연결하는 것을 우선 권장합니다.
- GND는 반드시 공통 접지해야 합니다.
- 보드 배선이 다르면 `config.h`의 `I2C_SDA_PIN`, `I2C_SCL_PIN` 값을 변경하세요.
- MPU6050 주소가 `0x69`인 모듈은 `config.h`의 `MPU6050_ADDR`를 `0x69`로 바꾸세요.

## Arduino IDE 설정

1. Arduino IDE를 엽니다.
2. Boards Manager에서 `esp32 by Espressif Systems`를 설치합니다.
3. 보드를 사용하는 ESP32 보드에 맞게 선택합니다. 예: `ESP32 Dev Module`
4. `firmware/freeform_esp32_mpu6050/freeform_esp32_mpu6050.ino`를 엽니다.
5. Port를 선택하고 업로드합니다.
6. Serial Monitor를 `115200 baud`로 엽니다.

## 필요한 라이브러리

- `Wire.h`: Arduino/ESP32 기본 포함
- `ESP32 BLE Arduino`: ESP32 Arduino 보드 패키지에 포함되는 BLE 라이브러리

MPU6050은 별도 라이브러리 없이 직접 레지스터를 읽습니다.

## FF_L / FF_R 변경 방법

`config.h`에서 `NODE_LEFT`만 변경합니다.

```cpp
#define NODE_LEFT 1  // FF_L, node_id 0x4C
```

오른쪽 노드로 업로드할 때:

```cpp
#define NODE_LEFT 0  // FF_R, node_id 0x52
```

왼쪽/오른쪽은 같은 스케치를 사용하며, 별도의 펌웨어 파일을 만들 필요가 없습니다.

## 주요 설정

`config.h`에서 변경할 수 있습니다.

```cpp
#define DEFAULT_SAMPLE_RATE_HZ 200
#define MPU6050_ADDR 0x68
#define I2C_SDA_PIN 21
#define I2C_SCL_PIN 22
#define USE_MOCK_IMU 0
```

MPU6050 없이 BLE notify만 먼저 확인하려면 `USE_MOCK_IMU`를 `1`로 바꿔 업로드하세요. 이 경우 가짜 accel/gyro 값으로 19-byte packet을 전송합니다.

## BLE 규격

Service UUID:

```text
a1b2c3d4-e5f6-47a8-9abc-1234567890ab
```

| Characteristic | UUID | 역할 |
| --- | --- | --- |
| CMD | `a1b2c3d4-e5f6-47a8-9abc-1234567890ac` | 앱에서 ESP32로 명령 write |
| DATA | `a1b2c3d4-e5f6-47a8-9abc-1234567890ad` | ESP32에서 앱으로 19-byte packet notify |
| META | `a1b2c3d4-e5f6-47a8-9abc-1234567890ae` | 앱에서 읽는 JSON metadata |

CMD opcode:

| Opcode | 이름 | Payload |
| --- | --- | --- |
| `0x01` | START | `[0x01, session_id 16 bytes]` |
| `0x02` | STOP | `[0x02]` |
| `0x03` | PING | `[0x03]` |
| `0x04` | SET_RATE | `[0x04, rate_hz uint16 little-endian]` |

DATA packet은 항상 19바이트입니다.

| Byte | Field | Type |
| --- | --- | --- |
| 0 | node_id | `uint8`, `0x4C` for FF_L, `0x52` for FF_R |
| 1-2 | seq | `uint16 little-endian` |
| 3-6 | timestamp_us | `uint32 little-endian`, `micros()` |
| 7-8 | ax | `int16 little-endian` |
| 9-10 | ay | `int16 little-endian` |
| 11-12 | az | `int16 little-endian` |
| 13-14 | gx | `int16 little-endian` |
| 15-16 | gy | `int16 little-endian` |
| 17-18 | gz | `int16 little-endian` |

## FreeFormAllin 앱 테스트 순서

1. 왼쪽 노드 테스트
   - `config.h`에서 `NODE_LEFT`를 `1`로 설정합니다.
   - ESP32에 업로드합니다.
   - Serial Monitor에서 `BLE advertising started as FF_L`를 확인합니다.
   - FreeFormAllin 앱의 BLE scan 화면에서 `FF_L`이 보이는지 확인하고 연결합니다.

2. 세션 시작
   - 앱에서 운동 세션을 시작합니다.
   - Serial Monitor에서 `START received`를 확인합니다.
   - `Recording packet count: ... packets/sec` 값이 증가하는지 확인합니다.
   - 앱의 live stats에서 packet count가 증가하는지 확인합니다.

3. 세션 종료
   - 앱에서 Stop Recording을 누릅니다.
   - Serial Monitor에서 `STOP received`를 확인합니다.
   - 앱에서 세션과 `L.bin` 저장 여부를 확인합니다.

4. 오른쪽 노드 테스트
   - `config.h`에서 `NODE_LEFT`를 `0`으로 변경합니다.
   - ESP32에 다시 업로드합니다.
   - BLE 이름이 `FF_R`인지 확인하고 같은 순서로 테스트합니다.

## Serial Monitor 로그

정상 부팅 시 주요 로그:

```text
Boot started
MPU6050 init success
BLE advertising started as FF_L
BLE connected
START received
Recording packet count: 200 packets/sec
STOP received
BLE disconnected
```

패킷마다 로그를 찍으면 100-200Hz notify가 불안정해질 수 있으므로, 펌웨어는 1초마다 packet count를 요약해서 출력합니다.

## 자주 발생하는 문제와 해결법

### 앱에서 디바이스가 보이지 않음

- Serial Monitor에 `BLE advertising started as FF_L` 또는 `FF_R`가 찍혔는지 확인합니다.
- `config.h`의 `DEVICE_NAME`이 앱이 찾는 `FF_L` 또는 `FF_R`인지 확인합니다.
- Android/iOS Bluetooth 권한과 위치 권한을 확인합니다.
- ESP32가 이미 다른 기기에 연결되어 있다면 리셋 후 다시 스캔합니다.

### 연결은 되는데 패킷 수가 증가하지 않음

- 앱에서 세션 시작 후 Serial Monitor에 `START received`가 찍혔는지 확인합니다.
- MPU6050 없이 통신만 확인하려면 `USE_MOCK_IMU`를 `1`로 변경해 테스트합니다.
- `MPU6050 read failures`가 계속 증가하면 배선, 전원, I2C 주소를 확인합니다.

### MPU6050 init failed

- VCC/GND, SDA/SCL 연결을 확인합니다.
- 기본 주소는 `0x68`입니다. AD0 핀이 HIGH인 모듈은 `0x69`일 수 있습니다.
- ESP32 핀이 다르면 `Wire.begin(21, 22)`에 해당하는 `config.h` 핀 값을 변경합니다.

### 드롭이 많거나 연결이 불안정함

- 앱에서 `SET_RATE`를 낮추거나 `DEFAULT_SAMPLE_RATE_HZ`를 100으로 낮춰 테스트합니다.
- Serial Monitor를 매 패킷 출력하도록 수정하지 마세요.
- ESP32와 휴대폰 거리를 줄이고, 배터리 전원이 불안정하지 않은지 확인합니다.

