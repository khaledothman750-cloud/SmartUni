/*
 * Author / Project Supervisor : Omar Terro
 * GitHub                      : https://github.com/IOTERRO
 * Website                     : https://omarterro.fr
 * Student (FYP)               : Khaled Othman
 * Date                        : 14 October 2026
 * Project                     : SmartUni - Smart University CityU
 */
/*
  SmartUni — ESP32 Parking IoT node
  Publishes 3 ultrasonic bay statuses to Firebase Realtime Database.

  Wiring (HC-SR04):
    Spot P1 Front : TRIG=13, ECHO=14
    Spot P2 Left  : TRIG=26, ECHO=27
    Spot P3 Right : TRIG=32, ECHO=33

  Library: Firebase ESP Client (mobizt)
*/

#include <WiFi.h>
#include <Firebase_ESP_Client.h>
#include "addons/TokenHelper.h"
#include "addons/RTDBHelper.h"

#include "Config.h"
#include "WiFiController.h"
#include "FirebaseController.h"
#include "ParkingSpot.h"

// ==============================================================================
// Pin map (validated on hardware)
// ==============================================================================
static const int TRIG_FRONT = 13;
static const int ECHO_FRONT = 14;
static const int TRIG_LEFT = 26;
static const int ECHO_LEFT = 27;
static const int TRIG_RIGHT = 32;
static const int ECHO_RIGHT = 33;

WiFiController wifi(WIFI_SSID, WIFI_PASSWORD);
FirebaseController db;

ParkingSpot spotFront("P1", "Front", TRIG_FRONT, ECHO_FRONT, PARKING_TEST_MODE);
ParkingSpot spotLeft("P2", "Left", TRIG_LEFT, ECHO_LEFT, PARKING_TEST_MODE);
ParkingSpot spotRight("P3", "Right", TRIG_RIGHT, ECHO_RIGHT, PARKING_TEST_MODE);

unsigned long lastSendTime = 0;

void setup() {
  Serial.begin(115200);
  delay(1000);

  Serial.println("\n=== SmartUni Parking Node ===");
  Serial.printf("Test mode: %s\n", PARKING_TEST_MODE ? "ON" : "OFF (sensors)");

  spotFront.begin();
  spotLeft.begin();
  spotRight.begin();

  wifi.connect();

  // Wall-clock time so Firebase `updated_at` is real (for ESP online indicator).
  configTime(0, 0, "pool.ntp.org", "time.nist.gov");
  Serial.print("Waiting for NTP");
  for (int i = 0; i < 40 && time(nullptr) < 1700000000; i++) {
    delay(250);
    Serial.print(".");
  }
  Serial.println();
  if (time(nullptr) < 1700000000) {
    Serial.println("WARNING: NTP not synced — app cannot detect ESP online status.");
  } else {
    Serial.printf("NTP OK: %ld\n", (long)time(nullptr));
  }

  db.begin(API_KEY, DATABASE_URL, USER_EMAIL, USER_PASSWORD);

  randomSeed(analogRead(0));
}

void loop() {
  if (!db.isReady()) return;

  const unsigned long now = millis();
  if (lastSendTime != 0 && (now - lastSendTime) < PARKING_SEND_INTERVAL_MS) {
    return;
  }
  lastSendTime = now;

  Serial.println("\n=========================================");
  Serial.println("Syncing parking spots → Firebase");

  spotFront.process(db.fbdo);
  delay(200);
  spotLeft.process(db.fbdo);
  delay(200);
  spotRight.process(db.fbdo);

  Serial.println("=========================================");
}
