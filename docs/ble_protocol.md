# BLE Protocol (NeuroLock)

Service UUID: `19B10010-E8F2-537E-4F6C-D104768A1214`

Characteristic UUID: `19B10011-E8F2-537E-4F6C-D104768A1214`

The characteristic accepts UTF-8 text commands from the Flutter app:

- `UNLOCK` -> activates relay and unlocks door for 5 seconds
- `LOCK` -> deactivates relay and locks door
- `ALARM_ON` -> turns buzzer on
- `ALARM_OFF` -> turns buzzer off
- `PING` -> ESP32 responds with `PONG`

Notes:
- Wiring matches your pin mapping.
- Relay active level can differ by module. Change `RELAY_ACTIVE_LEVEL` in `hardware_control.cpp` if needed.
