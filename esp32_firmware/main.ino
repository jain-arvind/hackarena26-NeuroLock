#include "auth_engine.h"
#include "ble_server.h"
#include "hardware_control.h"

namespace {

constexpr uint32_t kUnlockDurationMs = 5000;

void handleCommand(const String& command) {
  if (!Auth::isAuthorizedCommand(command)) {
    BleServer::notifyStatus("DENIED");
    return;
  }

  if (command == "UNLOCK") {
    Hardware::unlockDoor(kUnlockDurationMs);
    BleServer::notifyStatus("UNLOCKED");
    return;
  }

  if (command == "LOCK") {
    Hardware::lockDoor();
    BleServer::notifyStatus("LOCKED");
    return;
  }

  if (command == "ALARM_ON") {
    Hardware::alarmOn();
    BleServer::notifyStatus("ALARM_ON");
    return;
  }

  if (command == "ALARM_OFF") {
    Hardware::alarmOff();
    BleServer::notifyStatus("ALARM_OFF");
    return;
  }

  if (command == "PING") {
    BleServer::notifyStatus("PONG");
    return;
  }
}

}  // namespace

void setup() {
  Serial.begin(115200);
  Hardware::setup();
  BleServer::setup(handleCommand);
  Serial.println("NeuroLock ESP32 firmware ready");
}

void loop() {
  Hardware::loop();
  BleServer::loop();

  if (Hardware::consumeButtonPressed()) {
    Hardware::unlockDoor(kUnlockDurationMs);
    BleServer::notifyStatus("BUTTON_UNLOCK");
  }

  delay(10);
}
