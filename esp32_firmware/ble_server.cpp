#include "ble_server.h"

#include <NimBLEDevice.h>

namespace BleServer {

constexpr const char* DEVICE_NAME = "NeuroLock-ESP32";
constexpr const char* SERVICE_UUID = "19B10010-E8F2-537E-4F6C-D104768A1214";
constexpr const char* COMMAND_CHAR_UUID =
    "19B10011-E8F2-537E-4F6C-D104768A1214";

static NimBLEServer* g_server = nullptr;
static NimBLECharacteristic* g_commandCharacteristic = nullptr;
static CommandHandler g_handler = nullptr;
static bool g_connected = false;

String trimAndUpper(String value) {
  value.trim();
  value.toUpperCase();
  return value;
}

class ServerCallbacks : public NimBLEServerCallbacks {
  void onConnect(NimBLEServer* pServer, NimBLEConnInfo& connInfo) override {
    (void)pServer;
    (void)connInfo;
    g_connected = true;
  }

  void onDisconnect(NimBLEServer* pServer, NimBLEConnInfo& connInfo,
                    int reason) override {
    (void)connInfo;
    (void)reason;
    g_connected = false;
    pServer->startAdvertising();
  }
};

class CommandCallbacks : public NimBLECharacteristicCallbacks {
  void onWrite(NimBLECharacteristic* pCharacteristic,
               NimBLEConnInfo& connInfo) override {
    (void)connInfo;
    const std::string raw = pCharacteristic->getValue();
    if (raw.empty()) {
      return;
    }

    String command = String(raw.c_str());
    command = trimAndUpper(command);

    if (g_handler != nullptr) {
      g_handler(command);
    }
  }
};

void setup(CommandHandler handler) {
  g_handler = handler;

  NimBLEDevice::init(DEVICE_NAME);
  g_server = NimBLEDevice::createServer();
  g_server->setCallbacks(new ServerCallbacks());

  NimBLEService* service = g_server->createService(SERVICE_UUID);
  g_commandCharacteristic =
      service->createCharacteristic(COMMAND_CHAR_UUID,
                                    NIMBLE_PROPERTY::READ |
                                        NIMBLE_PROPERTY::WRITE |
                                        NIMBLE_PROPERTY::NOTIFY);

  g_commandCharacteristic->setValue("READY");
  g_commandCharacteristic->setCallbacks(new CommandCallbacks());

  service->start();

  NimBLEAdvertising* advertising = NimBLEDevice::getAdvertising();
  advertising->addServiceUUID(SERVICE_UUID);
  advertising->start();
}

void loop() {}

bool isConnected() { return g_connected; }

void notifyStatus(const String& status) {
  if (g_commandCharacteristic == nullptr || !g_connected) {
    return;
  }

  g_commandCharacteristic->setValue(status.c_str());
  g_commandCharacteristic->notify();
}

}  // namespace BleServer
