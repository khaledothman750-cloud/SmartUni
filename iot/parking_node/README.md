# SmartUni IoT — Parking Node

**Author / Project Supervisor:** Omar Terro ([GitHub](https://github.com/IOTERRO) · [omarterro.fr](https://omarterro.fr))  
**Student (FYP):** Khaled Othman  
**Date:** 14 October 2026

ESP32 firmware that reads **three HC-SR04 ultrasonic sensors** and publishes bay occupancy to **Firebase Realtime Database**.

Attendance is **not** handled here (Flutter + Cloudflare attendance Worker).

## Hardware pins

| Spot | Label | TRIG | ECHO |
|------|-------|------|------|
| `P1` | Front | 13   | 14   |
| `P2` | Left  | 26   | 27   |
| `P3` | Right | 32   | 33   |

## Firebase path

```
/SmartUniversity/Parking/P1
/SmartUniversity/Parking/P2
/SmartUniversity/Parking/P3
```

Each node JSON:

```json
{
  "spot_id": "P1",
  "label": "Front",
  "status": "occupied",
  "distance_cm": 42.5,
  "updated_at": 1729420800,
  "timestamp": "123456"
}
```

`updated_at` is Unix time (NTP). The Flutter parking screen treats the ESP as **online** if any bay was updated within ~45s; otherwise it shows **offline** and last-known status.

## Setup

1. Install **Firebase ESP Client** (mobizt) in Arduino IDE / PlatformIO.
2. Copy `Config.example.h` → `Config.h` and fill Wi-Fi + Firebase Auth.
3. Open `parking_node.ino`, select your ESP32 board, flash.
4. Set `PARKING_TEST_MODE` to `true` for random demo data without sensors.

## Flutter

The SmartUni app reads the same RTDB path via `FirebaseParkingRepository`.
