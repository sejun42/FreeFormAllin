# FreeFormAllin - IMU Sensor BLE Collection and Analysis Mobile App

**Flutter app integrating WebView, native BLE IMU streaming, and session-based binary data management**

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-100%25-0175C2?logo=dart&logoColor=white)
![BLE](https://img.shields.io/badge/BLE-IMU%20Sensor-blueviolet)

---

## Overview

FreeFormAllin is a **Flutter mobile application** that unifies:
- A **WebView shell** hosting the FreeForm web service
- - **Native BLE collection** from dual IMU sensor nodes (FF_L / FF_R)
  - - **Binary session storage** (L.bin, R.bin) with metadata
    - - Optional **backend upload** via multipart API
      - - **Native Google OAuth bridge** to bypass WebView OAuth restrictions
       
        - Designed for capturing high-frequency (200 Hz) inertial measurement data during exercise sessions, enabling biomechanical analysis of human movement.
       
        - ## Key Features
       
        - | Feature | Description |
        - |---|---|
        - | **Dual-Node BLE Streaming** | Simultaneous L/R IMU data capture via BLE notify |
        - | **19-Byte IMU Packet Parser** | node_id, seq, timestamp, 3-axis accel + 3-axis gyro |
        - | **Drop Rate Monitoring** | Sequence gap detection with real-time PPS and drop statistics |
        - | **Binary Session Files** | Raw sensor data preserved in L.bin / R.bin per session |
        - | **Mock Mode** | Full UI/flow testing without hardware (simulated 200 Hz data) |
        - | **Web to Native Bridge** | freeform:// deep links + JS channel for seamless integration |
       
        - ## BLE Protocol
       
        - ### IMU Packet Format (19 bytes)
       
        - | Byte | Field | Type |
        - |---|---|---|
        - | 0 | node_id | 0x4C = L, 0x52 = R |
        - | 1-2 | sequence | uint16 LE |
        - | 3-6 | timestamp_us | uint32 LE |
        - | 7-8 | accel_x | int16 LE |
        - | 9-10 | accel_y | int16 LE |
        - | 11-12 | accel_z | int16 LE |
        - | 13-14 | gyro_x | int16 LE |
        - | 15-16 | gyro_y | int16 LE |
        - | 17-18 | gyro_z | int16 LE |
       
        - ## Getting Started
       
        - ### Prerequisites
        - - Flutter 3.x SDK
          - - Android Studio / Xcode
            - - (Optional) FF_L / FF_R IMU sensor hardware
             
              - ```bash
                git clone https://github.com/sejun42/FreeFormAllin.git
                cd FreeFormAllin
                flutter pub get
                flutter run
                ```

                Enable **Mock Mode** in Settings to develop without physical sensors.

                ## Research Context

                This app supports biomechanics research by providing a robust pipeline for:
                - **Wearable IMU data acquisition** during exercise
                - - **Bilateral sensor synchronization** for movement symmetry analysis
                  - - **Session-based data management** for longitudinal studies
                   
                    - ## Contact
                   
                    - - **Sejun Yoon** - sejun1324@gmail.com
                      - - GitHub: @sejun42
                        - 
