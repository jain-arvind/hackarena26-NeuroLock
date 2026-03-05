#include <BLE2902.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>

#define RELAY_PIN 23
#define GREEN_LED 18
#define RED_LED 19
#define BUZZER 5
#define BUTTON_PIN 4

static const char* DEVICE_NAME = "NeuroLock_ESP32";
static const char* SERVICE_UUID = "19B10010-E8F2-537E-4F6C-D104768A1214";
static const char* CHARACTERISTIC_UUID = "19B10011-E8F2-537E-4F6C-D104768A1214";

// Most 1-channel relay modules used with ESP32 are active LOW.
static const int RELAY_ACTIVE_LEVEL = LOW;
static const int RELAY_IDLE_LEVEL = HIGH;

static const uint32_t UNLOCK_DURATION_MS = 5000;
static const uint32_t BUTTON_DEBOUNCE_MS = 250;

BLEServer* g_server = nullptr;
BLECharacteristic* g_commandCharacteristic = nullptr;
bool g_deviceConnected = false;
bool g_prevDeviceConnected = false;

bool g_alarmEnabled = false;
bool g_doorUnlocked = false;
uint32_t g_unlockUntil = 0;
uint32_t g_lastButtonMs = 0;

void setLockedState() {
  digitalWrite(RELAY_PIN, RELAY_IDLE_LEVEL);
  digitalWrite(GREEN_LED, LOW);
  digitalWrite(RED_LED, HIGH);
  g_doorUnlocked = false;
  g_unlockUntil = 0;
}

void setUnlockedState(uint32_t durationMs) {
  digitalWrite(RELAY_PIN, RELAY_ACTIVE_LEVEL);
  digitalWrite(GREEN_LED, HIGH);
  digitalWrite(RED_LED, LOW);
  g_doorUnlocked = true;
  g_unlockUntil = millis() + durationMs;
}

void setAlarm(bool enabled) {
  g_alarmEnabled = enabled;
  digitalWrite(BUZZER, enabled ? HIGH : LOW);
}

void notifyStatus(const char* status) {
  if (g_commandCharacteristic == nullptr || !g_deviceConnected) {
    return;
  }
  g_commandCharacteristic->setValue(status);
  g_commandCharacteristic->notify();
}

String normalizedCommand(std::string raw) {
  String cmd = String(raw.c_str());
  cmd.trim();
  cmd.toUpperCase();
  return cmd;
}

class ServerCallbacks : public BLEServerCallbacks {
  void onConnect(BLEServer* pServer) override {
    (void)pServer;
    g_deviceConnected = true;
    Serial.println("BLE client connected");
  }

  void onDisconnect(BLEServer* pServer) override {
    (void)pServer;
    g_deviceConnected = false;
    Serial.println("BLE client disconnected");
  }
};

class CommandCallbacks : public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic* pCharacteristic) override {
    std::string raw = pCharacteristic->getValue();
    if (raw.empty()) {
      return;
    }

    String cmd = normalizedCommand(raw);
    Serial.print("CMD: ");
    Serial.println(cmd);

    if (cmd == "UNLOCK") {
      setUnlockedState(UNLOCK_DURATION_MS);
      notifyStatus("UNLOCKED");
      return;
    }

    if (cmd == "LOCK") {
      setLockedState();
      notifyStatus("LOCKED");
      return;
    }

    if (cmd == "ALARM_ON") {
      setAlarm(true);
      notifyStatus("ALARM_ON");
      return;
    }

    if (cmd == "ALARM_OFF") {
      setAlarm(false);
      notifyStatus("ALARM_OFF");
      return;
    }

    if (cmd == "PING") {
      notifyStatus("PONG");
      return;
    }

    notifyStatus("DENIED");
  }
};

void setup() {
  Serial.begin(115200);

  pinMode(RELAY_PIN, OUTPUT);
  pinMode(GREEN_LED, OUTPUT);
  pinMode(RED_LED, OUTPUT);
  pinMode(BUZZER, OUTPUT);
  pinMode(BUTTON_PIN, INPUT_PULLUP);

  setAlarm(false);
  setLockedState();

  BLEDevice::init(DEVICE_NAME);
  g_server = BLEDevice::createServer();
  g_server->setCallbacks(new ServerCallbacks());

  BLEService* service = g_server->createService(SERVICE_UUID);
  g_commandCharacteristic = service->createCharacteristic(
      CHARACTERISTIC_UUID,
      BLECharacteristic::PROPERTY_READ |
          BLECharacteristic::PROPERTY_WRITE |
          BLECharacteristic::PROPERTY_NOTIFY);
  g_commandCharacteristic->addDescriptor(new BLE2902());
  g_commandCharacteristic->setCallbacks(new CommandCallbacks());
  g_commandCharacteristic->setValue("READY");

  service->start();

  BLEAdvertising* advertising = BLEDevice::getAdvertising();
  advertising->addServiceUUID(SERVICE_UUID);
  advertising->setScanResponse(true);
  advertising->setMinPreferred(0x06);
  advertising->setMinPreferred(0x12);
  BLEDevice::startAdvertising();

  Serial.println("NeuroLock BLE server ready");
}

void loop() {
  const uint32_t now = millis();

  if (g_doorUnlocked && g_unlockUntil != 0 && (int32_t)(now - g_unlockUntil) >= 0) {
    setLockedState();
    notifyStatus("LOCKED");
  }

  if (digitalRead(BUTTON_PIN) == LOW && (now - g_lastButtonMs) > BUTTON_DEBOUNCE_MS) {
    g_lastButtonMs = now;
    setUnlockedState(UNLOCK_DURATION_MS);
    notifyStatus("BUTTON_UNLOCK");
  }

  if (g_deviceConnected && !g_prevDeviceConnected) {
    g_prevDeviceConnected = true;
  }

  if (!g_deviceConnected && g_prevDeviceConnected) {
    delay(100);
    g_server->startAdvertising();
    g_prevDeviceConnected = false;
  }

  delay(10);
}
