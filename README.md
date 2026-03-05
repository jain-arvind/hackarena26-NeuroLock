# VICSTA Hackathon - Grand Finale
**VIT College, Kondhwa Campus | 5th - 6th March**

---

## Team Details

- **Team Name:** NeuroLock
- **Members:** Yashodeep Karle, Pushkar Suryavanshi, Sarvesh Katkar, Kaustav Sengupta
- **Domain:** Productivity and Security

---

## Project

**Problem:**
BioAccess MFA: Expand the locker detection concept into a full-room entry system that uses ESP32 to manage multi-factor authentication (identity + proximity + control channel) for sensitive rooms.

**Solution:**
NeuroLock is a smart room-entry prototype with secure mobile authentication and hardware control.

- Flutter mobile app for user authentication and lock control.
- ESP32-based door controller with relay, LEDs, buzzer, and push-button simulation.
- Dual connectivity path:
  - BLE (primary local control path using custom service/characteristic)
  - Wi-Fi HTTP fallback (for easier testing and network-based control)
- Firebase-backed authentication and cloud log pipeline.

---

## Current Architecture

1. User signs in from Flutter app using Email/Password or Google.
2. App restricts access to approved academic emails (`.edu`) at app and Firestore rule layer.
3. App connects to ESP32 via:
   - BLE custom GATT command characteristic, or
   - Wi-Fi host/IP endpoint (`/command`, `/unlock`, `/lock`, `/alarm-on`, `/alarm-off`, `/ping`).
4. ESP32 executes command:
   - Relay toggles lock
   - Green/Red LED status update
   - Buzzer alarm toggle
5. App writes logs/events to Firestore (`ble_logs` collection).

---

## Hardware Pin Mapping (ESP32)

- Relay IN1 -> GPIO 23
- Green LED -> GPIO 18 (with resistor)
- Red LED -> GPIO 19 (with resistor)
- Buzzer + -> GPIO 5
- Push button -> GPIO 4 (INPUT_PULLUP)
- Relay VCC -> 5V
- Relay GND -> GND

---

## BLE Protocol

- **Device Name:** `NeuroLock_ESP32`
- **Service UUID:** `19B10010-E8F2-537E-4F6C-D104768A1214`
- **Characteristic UUID:** `19B10011-E8F2-537E-4F6C-D104768A1214`
- **Commands:** `UNLOCK`, `LOCK`, `ALARM_ON`, `ALARM_OFF`, `PING`

---

## Wi-Fi API Contract (ESP32)

Base URL example: `http://<esp32-ip>:80`

- `GET /ping` -> health check (`pong`)
- `POST /command` -> JSON body: `{ "command": "UNLOCK" }`
- Fallback endpoints:
  - `GET /unlock`
  - `GET /lock`
  - `GET /alarm-on`
  - `GET /alarm-off`

---

## Tech Stack

### Mobile App
- Flutter (Dart)
- Android Studio / VS Code

### Hardware
- ESP32
- Relay module
- Solenoid lock
- LEDs, buzzer, push button

### Cloud
- Firebase Authentication
- Cloud Firestore

---

## APIs, SDKs, and Libraries Used

### Flutter Dependencies
- `flutter_blue_plus` (BLE scan/connect/GATT write)
- `permission_handler` (Android runtime permissions)
- `firebase_core` (Firebase initialization)
- `firebase_auth` (Email/Password + Google sign-in)
- `cloud_firestore` (cloud logs)
- `google_sign_in` (Google OAuth)
- `http` (Wi-Fi command requests)
- `network_info_plus` (local IP/subnet discovery)

### ESP32 Libraries
- `BLEDevice`, `BLEServer`, `BLEUtils`, `BLE2902` (BLE GATT server)
- `WiFi.h` (Wi-Fi connectivity)
- `WebServer.h` (HTTP endpoints)

### External Services / APIs
- Firebase Authentication API
- Cloud Firestore API
- Google Sign-In (OAuth client via Firebase)

---

## Setup Notes (Hackathon Build)

1. Add Firebase Android config file:
   - `flutter_app/android/app/google-services.json`
2. Enable Firebase providers:
   - Email/Password
   - Google
3. Add SHA-1 and SHA-256 fingerprints in Firebase Android app settings.
4. Run Flutter app:
   - `flutter pub get`
   - `flutter run`
5. Flash ESP32 firmware and keep phone + ESP32 on same Wi-Fi for Wi-Fi mode.

---

## Rules to Remember

- All development must happen **during** the hackathon only
- Push code **regularly** - commit history is monitored
- Use only open-source libraries with compatible licenses and **credit them**
- Only **one submission** per team
- All members must be present **both days**

---

## Attribution

- Flutter and Dart open-source ecosystem
- ESP32 Arduino core and BLE/Wi-Fi libraries
- Firebase (Authentication + Firestore)
- Google Sign-In SDK

---

> *"The world is not enough - but it is such a perfect place to start."* - James Bond
>
> All the best to every team. Build something great.
