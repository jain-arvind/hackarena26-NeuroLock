# NeuroLock - BLE Smart Door Prototype

This repository now contains initial scaffolding for:

- ESP32 firmware with BLE command server
- Flutter app for BLE scan/connect and control actions
- Basic protocol documentation

## Project Structure

- `docs/ble_protocol.md`
- `flutter_app/`
- `esp32_firmware/`

## Wiring (as provided)

- Relay IN1 -> GPIO23
- Green LED -> GPIO18 (with 220/330 ohm resistor)
- Red LED -> GPIO19 (with 220/330 ohm resistor)
- Buzzer + -> GPIO5, buzzer - -> GND
- Push button -> GPIO4 and GND (INPUT_PULLUP)
- Relay VCC -> 5V, Relay GND -> GND

## ESP32 Setup

1. Install `NimBLE-Arduino` library.
2. Open `esp32_firmware/main.ino` in Arduino IDE.
3. Select ESP32 board and upload.
4. Device advertises as `NeuroLock-ESP32`.

## Flutter Setup

1. Create/enable Flutter platform folders if needed:
   - from `flutter_app/`, run `flutter create .`
2. Install dependencies:
   - `flutter pub get`
3. Run on Android device with Bluetooth + Location permissions enabled.

## BLE Commands

`UNLOCK`, `LOCK`, `ALARM_ON`, `ALARM_OFF`, `PING`

See `docs/ble_protocol.md` for full details.
