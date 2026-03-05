#ifndef HARDWARE_CONTROL_H
#define HARDWARE_CONTROL_H

#include <Arduino.h>

namespace Hardware {

constexpr int RELAY_PIN = 23;
constexpr int GREEN_LED_PIN = 18;
constexpr int RED_LED_PIN = 19;
constexpr int BUZZER_PIN = 5;
constexpr int BUTTON_PIN = 4;

void setup();
void loop();

void lockDoor();
void unlockDoor(uint32_t durationMs);

void alarmOn();
void alarmOff();

bool consumeButtonPressed();

}  // namespace Hardware

#endif
