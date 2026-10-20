/*
 * Author / Project Supervisor : Omar Terro
 * GitHub                      : https://github.com/IOTERRO
 * Website                     : https://omarterro.fr
 * Student (FYP)               : Khaled Othman
 * Date                        : 14 October 2026
 * Project                     : SmartUni - Smart University CityU
 */
#pragma once

#include <Arduino.h>
#include <time.h>
#include <Firebase_ESP_Client.h>
#include "Config.h"

/// One ultrasonic parking bay → Firebase RTDB node.
class ParkingSpot {
 private:
  String spotId;
  String label;
  String basePath;
  int trigPin;
  int echoPin;
  bool testMode;

  float readDistanceCm() {
    digitalWrite(trigPin, LOW);
    delayMicroseconds(2);
    digitalWrite(trigPin, HIGH);
    delayMicroseconds(10);
    digitalWrite(trigPin, LOW);

    const long duration = pulseIn(echoPin, HIGH, 30000);  // 30 ms timeout
    if (duration <= 0) return -1.0f;
    return duration * 0.034f / 2.0f;
  }

  void publish(FirebaseData& fbdo, const String& status, float distanceCm) {
    FirebaseJson json;
    json.set("spot_id", spotId);
    json.set("label", label);
    json.set("status", status);
    if (distanceCm >= 0) {
      json.set("distance_cm", distanceCm);
    }
    // Unix seconds (NTP). Flutter uses this to detect ESP online vs stale.
    const time_t nowSec = time(nullptr);
    if (nowSec > 1700000000) {
      json.set("updated_at", (unsigned long)nowSec);
    }
    json.set("timestamp", String(millis()));

    Serial.printf("[ParkingSpot] %s (%s) → %s\n", spotId.c_str(),
                  label.c_str(), status.c_str());

    if (Firebase.RTDB.setJSON(&fbdo, basePath.c_str(), &json)) {
      Serial.println("[ParkingSpot] Firebase update OK");
    } else {
      Serial.print("[ParkingSpot] Firebase error: ");
      Serial.println(fbdo.errorReason());
    }
  }

 public:
  ParkingSpot(const char* id, const char* label, int trig, int echo, bool mode)
      : spotId(id),
        label(label),
        basePath(String("/SmartUniversity/Parking/") + id),
        trigPin(trig),
        echoPin(echo),
        testMode(mode) {}

  void begin() {
    pinMode(trigPin, OUTPUT);
    pinMode(echoPin, INPUT);
    digitalWrite(trigPin, LOW);
  }

  void process(FirebaseData& fbdo) {
    if (testMode) {
      const String status = (random(0, 2) == 1) ? "occupied" : "available";
      Serial.printf("[ParkingSpot] TEST MODE %s\n", spotId.c_str());
      publish(fbdo, status, -1.0f);
      return;
    }

    const float distance = readDistanceCm();
    String status = "available";
    if (distance > 0 && distance < PARKING_OCCUPIED_CM) {
      status = "occupied";
    }

    Serial.printf("[ParkingSpot] %s distance=%.1f cm\n", spotId.c_str(),
                  distance);
    publish(fbdo, status, distance);
  }
};
