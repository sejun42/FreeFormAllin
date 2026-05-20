#include "config.h"

#include <Arduino.h>
#include <Wire.h>
#include <BLE2902.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>

// FreeForm BLE UUIDs. These must match the Flutter app.
static const char* SERVICE_UUID = "a1b2c3d4-e5f6-47a8-9abc-1234567890ab";
static const char* CMD_CHAR_UUID = "a1b2c3d4-e5f6-47a8-9abc-1234567890ac";
static const char* DATA_CHAR_UUID = "a1b2c3d4-e5f6-47a8-9abc-1234567890ad";
static const char* META_CHAR_UUID = "a1b2c3d4-e5f6-47a8-9abc-1234567890ae";

static const uint8_t CMD_START = 0x01;
static const uint8_t CMD_STOP = 0x02;
static const uint8_t CMD_PING = 0x03;
static const uint8_t CMD_SET_RATE = 0x04;

BLEServer* bleServer = nullptr;
BLECharacteristic* cmdCharacteristic = nullptr;
BLECharacteristic* dataCharacteristic = nullptr;
BLECharacteristic* metaCharacteristic = nullptr;

volatile bool deviceConnected = false;
volatile bool recording = false;

uint16_t sampleRateHz = DEFAULT_SAMPLE_RATE_HZ;
uint32_t notifyIntervalUs = 1000000UL / DEFAULT_SAMPLE_RATE_HZ;
uint32_t nextNotifyUs = 0;
uint16_t sequenceNumber = 0;

bool mpuReady = false;
uint32_t lastStatsMs = 0;
uint32_t packetsThisSecond = 0;
uint32_t mpuReadFailuresThisSecond = 0;

struct ImuRaw {
  int16_t ax;
  int16_t ay;
  int16_t az;
  int16_t gx;
  int16_t gy;
  int16_t gz;
};

void refreshMetaCharacteristic();
void handleCommand(const uint8_t* payload, size_t length);
void startBle();
bool initMpu6050();
bool readMpu6050(ImuRaw& raw);
void fillMockImu(ImuRaw& raw);
void sendImuPacket();
void writeInt16Le(uint8_t* buffer, size_t offset, int16_t value);
void printSessionId(const uint8_t* bytes, size_t length);

class ServerCallbacks : public BLEServerCallbacks {
 public:
  void onConnect(BLEServer* server) {
    deviceConnected = true;
    Serial.println("BLE connected");
  }

  void onConnect(BLEServer* server, esp_ble_gatts_cb_param_t* param) {
    onConnect(server);
  }

  void onDisconnect(BLEServer* server) {
    deviceConnected = false;
    recording = false;
    Serial.println("BLE disconnected");
    BLEDevice::startAdvertising();
    Serial.print("BLE advertising started as ");
    Serial.println(DEVICE_NAME);
  }

  void onDisconnect(BLEServer* server, esp_ble_gatts_cb_param_t* param) {
    onDisconnect(server);
  }
};

class CommandCallbacks : public BLECharacteristicCallbacks {
 public:
  void onWrite(BLECharacteristic* characteristic) {
    auto value = characteristic->getValue();
    handleCommand(reinterpret_cast<const uint8_t*>(value.c_str()), value.length());
  }

  void onWrite(BLECharacteristic* characteristic, esp_ble_gatts_cb_param_t* param) {
    onWrite(characteristic);
  }
};

void setup() {
  Serial.begin(115200);
  delay(300);

  Serial.println();
  Serial.println("Boot started");
  Serial.print("FreeForm ESP32 MPU6050 firmware ");
  Serial.println(FW_VERSION);
  Serial.print("Node: ");
  Serial.print(DEVICE_NAME);
  Serial.print(" node_id=0x");
  Serial.println(NODE_ID, HEX);

  Wire.begin(I2C_SDA_PIN, I2C_SCL_PIN);
  mpuReady = initMpu6050();

#if USE_MOCK_IMU
  Serial.println("USE_MOCK_IMU enabled: sending generated IMU values");
#endif

  startBle();
  lastStatsMs = millis();
}

void loop() {
  if (recording && deviceConnected) {
    const uint32_t nowUs = micros();
    if ((int32_t)(nowUs - nextNotifyUs) >= 0) {
      sendImuPacket();

      nextNotifyUs += notifyIntervalUs;
      if ((int32_t)(nowUs - nextNotifyUs) > 0) {
        nextNotifyUs = nowUs + notifyIntervalUs;
      }
    }
  }

  const uint32_t nowMs = millis();
  if (nowMs - lastStatsMs >= 1000) {
    Serial.print("Recording packet count: ");
    Serial.print(packetsThisSecond);
    Serial.println(" packets/sec");
    if (mpuReadFailuresThisSecond > 0) {
      Serial.print("MPU6050 read failures: ");
      Serial.println(mpuReadFailuresThisSecond);
    }
    packetsThisSecond = 0;
    mpuReadFailuresThisSecond = 0;
    lastStatsMs = nowMs;
  }

  delay(1);
}

void startBle() {
  BLEDevice::init(DEVICE_NAME);
  BLEDevice::setMTU(64);

  bleServer = BLEDevice::createServer();
  bleServer->setCallbacks(new ServerCallbacks());

  BLEService* service = bleServer->createService(SERVICE_UUID);

  cmdCharacteristic = service->createCharacteristic(
      CMD_CHAR_UUID,
      BLECharacteristic::PROPERTY_WRITE | BLECharacteristic::PROPERTY_WRITE_NR);
  cmdCharacteristic->setCallbacks(new CommandCallbacks());

  dataCharacteristic = service->createCharacteristic(
      DATA_CHAR_UUID,
      BLECharacteristic::PROPERTY_NOTIFY);
  dataCharacteristic->addDescriptor(new BLE2902());

  metaCharacteristic = service->createCharacteristic(
      META_CHAR_UUID,
      BLECharacteristic::PROPERTY_READ);
  refreshMetaCharacteristic();

  service->start();

  BLEAdvertising* advertising = BLEDevice::getAdvertising();
  advertising->addServiceUUID(SERVICE_UUID);
  advertising->setScanResponse(true);
  advertising->setMinPreferred(0x06);
  advertising->setMinPreferred(0x12);

  BLEDevice::startAdvertising();
  Serial.print("BLE advertising started as ");
  Serial.println(DEVICE_NAME);
}

void refreshMetaCharacteristic() {
  if (metaCharacteristic == nullptr) {
    return;
  }

  String meta = "{";
  meta += "\"name\":\"";
  meta += DEVICE_NAME;
  meta += "\",\"fw\":\"";
  meta += FW_VERSION;
  meta += "\",\"imu\":\"MPU6050\",\"sample_rate_hz\":";
  meta += sampleRateHz;
  meta += ",\"packet_size\":";
  meta += IMU_PACKET_SIZE;
  meta += "}";

  metaCharacteristic->setValue(meta.c_str());
}

void handleCommand(const uint8_t* payload, size_t length) {
  if (payload == nullptr || length == 0) {
    return;
  }

  switch (payload[0]) {
    case CMD_START:
      Serial.println("START received");
      if (length >= 17) {
        Serial.print("Session ID: ");
        printSessionId(payload + 1, 16);
      }
      sequenceNumber = 0;
      nextNotifyUs = micros();
      packetsThisSecond = 0;
      mpuReadFailuresThisSecond = 0;
      recording = true;
      break;

    case CMD_STOP:
      recording = false;
      Serial.println("STOP received");
      break;

    case CMD_PING:
      Serial.println("PING received");
      break;

    case CMD_SET_RATE:
      if (length >= 3) {
        const uint16_t requestedRate =
            static_cast<uint16_t>(payload[1]) |
            (static_cast<uint16_t>(payload[2]) << 8);

        if (requestedRate == 0) {
          Serial.println("SET_RATE ignored: 0 Hz is invalid");
          break;
        }

        sampleRateHz = requestedRate;
        notifyIntervalUs = 1000000UL / sampleRateHz;
        nextNotifyUs = micros() + notifyIntervalUs;
        refreshMetaCharacteristic();

        Serial.print("SET_RATE received: ");
        Serial.print(sampleRateHz);
        Serial.println(" Hz");
      } else {
        Serial.println("SET_RATE ignored: payload too short");
      }
      break;

    default:
      Serial.print("Unknown CMD received: 0x");
      Serial.println(payload[0], HEX);
      break;
  }
}

bool initMpu6050() {
  Wire.beginTransmission(MPU6050_ADDR);
  Wire.write(0x6B);  // PWR_MGMT_1
  Wire.write(0x00);  // wake up
  const uint8_t result = Wire.endTransmission(true);

  if (result == 0) {
    Serial.println("MPU6050 init success");
    return true;
  }

  Serial.print("MPU6050 init failed, I2C error=");
  Serial.println(result);
  return false;
}

bool readMpu6050(ImuRaw& raw) {
#if USE_MOCK_IMU
  fillMockImu(raw);
  return true;
#else
  if (!mpuReady) {
    return false;
  }

  Wire.beginTransmission(MPU6050_ADDR);
  Wire.write(0x3B);  // ACCEL_XOUT_H
  if (Wire.endTransmission(false) != 0) {
    return false;
  }

  const uint8_t bytesRead = Wire.requestFrom(
      static_cast<uint8_t>(MPU6050_ADDR),
      static_cast<uint8_t>(14),
      static_cast<uint8_t>(true));

  if (bytesRead < 14) {
    return false;
  }

  raw.ax = static_cast<int16_t>((Wire.read() << 8) | Wire.read());
  raw.ay = static_cast<int16_t>((Wire.read() << 8) | Wire.read());
  raw.az = static_cast<int16_t>((Wire.read() << 8) | Wire.read());
  Wire.read();
  Wire.read();
  raw.gx = static_cast<int16_t>((Wire.read() << 8) | Wire.read());
  raw.gy = static_cast<int16_t>((Wire.read() << 8) | Wire.read());
  raw.gz = static_cast<int16_t>((Wire.read() << 8) | Wire.read());

  return true;
#endif
}

void fillMockImu(ImuRaw& raw) {
  static int16_t phase = 0;
  phase += 23;

  raw.ax = phase;
  raw.ay = phase / 2;
  raw.az = 16384;
  raw.gx = phase * 2;
  raw.gy = -phase;
  raw.gz = phase / 3;
}

void sendImuPacket() {
  ImuRaw raw = {};
  if (!readMpu6050(raw)) {
    mpuReadFailuresThisSecond++;
    return;
  }

  uint8_t packet[IMU_PACKET_SIZE] = {};
  const uint32_t timestamp = micros();

  packet[0] = NODE_ID;
  packet[1] = sequenceNumber & 0xFF;
  packet[2] = (sequenceNumber >> 8) & 0xFF;
  packet[3] = timestamp & 0xFF;
  packet[4] = (timestamp >> 8) & 0xFF;
  packet[5] = (timestamp >> 16) & 0xFF;
  packet[6] = (timestamp >> 24) & 0xFF;

  writeInt16Le(packet, 7, raw.ax);
  writeInt16Le(packet, 9, raw.ay);
  writeInt16Le(packet, 11, raw.az);
  writeInt16Le(packet, 13, raw.gx);
  writeInt16Le(packet, 15, raw.gy);
  writeInt16Le(packet, 17, raw.gz);

  dataCharacteristic->setValue(packet, sizeof(packet));
  dataCharacteristic->notify();

  sequenceNumber++;
  packetsThisSecond++;
}

void writeInt16Le(uint8_t* buffer, size_t offset, int16_t value) {
  const uint16_t unsignedValue = static_cast<uint16_t>(value);
  buffer[offset] = unsignedValue & 0xFF;
  buffer[offset + 1] = (unsignedValue >> 8) & 0xFF;
}

void printSessionId(const uint8_t* bytes, size_t length) {
  for (size_t i = 0; i < length; i++) {
    if (i == 4 || i == 6 || i == 8 || i == 10) {
      Serial.print("-");
    }
    if (bytes[i] < 0x10) {
      Serial.print("0");
    }
    Serial.print(bytes[i], HEX);
  }
  Serial.println();
}
