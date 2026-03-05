#include <BLEDevice.h>
#include <BLEUtils.h>
#include <BLEScan.h>
#include <BLEAdvertising.h>

#define RELAY_PIN 23
#define GREEN_LED 18
#define RED_LED 19
#define BUZZER 5
#define BUTTON_PIN 4

#define SCAN_TIME 1

// -------- DEVICE DATABASE --------
struct User {
  int userID;
  String phoneName;
};

User users[] = {
  {1, "OPPO Reno7 Pro 5G"},
  {2, "iQOO Z3 5G"}
};

const int USER_COUNT = 2;

BLEScan* pBLEScan;

int detectedUser = 0;
String detectedPhone = "";

bool doorOpen = false;
unsigned long doorOpenTime = 0;
unsigned long lastScan = 0;
unsigned long doorTimeout = 8000;

class MyAdvertisedDeviceCallbacks: public BLEAdvertisedDeviceCallbacks {
  void onResult(BLEAdvertisedDevice advertisedDevice) {

    String name = advertisedDevice.getName().c_str();
    int rssi = advertisedDevice.getRSSI();

    if (rssi > -75 && name.length() > 0) {
      detectedPhone = name;
    }
  }
};

void setup() {

  Serial.begin(115200);

  pinMode(RELAY_PIN, OUTPUT);
  pinMode(GREEN_LED, OUTPUT);
  pinMode(RED_LED, OUTPUT);
  pinMode(BUZZER, OUTPUT);
  pinMode(BUTTON_PIN, INPUT_PULLUP);

  digitalWrite(RELAY_PIN, HIGH);
  digitalWrite(GREEN_LED, LOW);
  digitalWrite(RED_LED, HIGH);

  // -------- TURN ON BLUETOOTH --------
  BLEDevice::init("NeuroLock_ESP32");

  // -------- MAKE ESP32 VISIBLE --------
  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->start();

  // -------- START BLE SCANNING --------
  pBLEScan = BLEDevice::getScan();
  pBLEScan->setAdvertisedDeviceCallbacks(new MyAdvertisedDeviceCallbacks());
  pBLEScan->setActiveScan(true);

  Serial.println("ESP32 Bluetooth Ready");
}

void loop() {

  if (millis() - lastScan > 3000) {

    detectedPhone = "";

    BLEScanResults* foundDevices = pBLEScan->start(SCAN_TIME, false);

    pBLEScan->clearResults();

    lastScan = millis();
  }

  // ---- Receive user ID from Python ----
  if (Serial.available()) {

    String msg = Serial.readStringUntil('\n');
    msg.trim();

    if (msg == "USER1") detectedUser = 1;
    else if (msg == "USER2") detectedUser = 2;
    else detectedUser = 0;
  }

  bool accessGranted = false;

  for (int i = 0; i < USER_COUNT; i++) {

    if (users[i].userID == detectedUser &&
        users[i].phoneName == detectedPhone) {

      accessGranted = true;
      break;
    }
  }

  // -------- LED STATUS --------
  if (doorOpen || accessGranted) {

    digitalWrite(GREEN_LED, HIGH);
    digitalWrite(RED_LED, LOW);

  } else {

    digitalWrite(GREEN_LED, LOW);
    digitalWrite(RED_LED, HIGH);
  }

  // -------- BUTTON CONTROL --------
  if (digitalRead(BUTTON_PIN) == LOW) {

    delay(50);

    if (doorOpen) closeDoor();
    else if (accessGranted) openDoor();
    else alarm();

    while (digitalRead(BUTTON_PIN) == LOW);
  }

  // -------- DOOR OPEN WARNING --------
  if (doorOpen && millis() - doorOpenTime > doorTimeout)
    digitalWrite(BUZZER, HIGH);
}

void openDoor() {

  digitalWrite(RELAY_PIN, LOW);
  doorOpen = true;
  doorOpenTime = millis();
}

void closeDoor() {

  digitalWrite(RELAY_PIN, HIGH);
  doorOpen = false;
  digitalWrite(BUZZER, LOW);
}

void alarm() {

  for (int i = 0; i < 3; i++) {

    digitalWrite(BUZZER, HIGH);
    delay(200);

    digitalWrite(BUZZER, LOW);
    delay(200);
  }
}