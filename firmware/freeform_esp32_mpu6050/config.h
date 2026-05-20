#pragma once

// Change only this value when flashing the same sketch to the right node.
// 1: left node  -> BLE name FF_L, node_id 0x4C ('L')
// 0: right node -> BLE name FF_R, node_id 0x52 ('R')
#define NODE_LEFT 1

#if NODE_LEFT
  #define DEVICE_NAME "FF_L"
  #define NODE_ID 0x4C
#else
  #define DEVICE_NAME "FF_R"
  #define NODE_ID 0x52
#endif

#define FW_VERSION "0.1.0"

// FreeForm app protocol defaults.
#define DEFAULT_SAMPLE_RATE_HZ 200
#define IMU_PACKET_SIZE 19

// MPU6050 I2C settings.
#define MPU6050_ADDR 0x68
#define I2C_SDA_PIN 21
#define I2C_SCL_PIN 22

// Set to 1 to test BLE notify packets without an MPU6050 connected.
// In mock mode, accel/gyro fields are generated locally.
#define USE_MOCK_IMU 0

