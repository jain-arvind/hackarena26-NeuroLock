#include "hardware_control.h"

namespace Hardware {

// Change to LOW if your relay is active-low.
constexpr int RELAY_ACTIVE_LEVEL = HIGH;
constexpr int RELAY_IDLE_LEVEL = (RELAY_ACTIVE_LEVEL == HIGH) ? LOW : HIGH;

static bool g_alarmOn = false;
static bool g_buttonPressLatched = false;
static uint32_t g_lastDebounceMs = 0;
static uint32_t g_unlockUntilMs = 0;

void alarmOn() {
  g_alarmOn = true;
  digitalWrite(BUZZER_PIN, HIGH);
}

void alarmOff() {
  g_alarmOn = false;
  digitalWrite(BUZZER_PIN, LOW);
}

void lockDoor() {
  digitalWrite(RELAY_PIN, RELAY_IDLE_LEVEL);
  digitalWrite(RED_LED_PIN, HIGH);
  digitalWrite(GREEN_LED_PIN, LOW);
  g_unlockUntilMs = 0;
}

void unlockDoor(uint32_t durationMs) {
  digitalWrite(RELAY_PIN, RELAY_ACTIVE_LEVEL);
  digitalWrite(RED_LED_PIN, LOW);
  digitalWrite(GREEN_LED_PIN, HIGH);

  if (durationMs > 0) {
    g_unlockUntilMs = millis() + durationMs;
  } else {
    g_unlockUntilMs = 0;
  }
}

void setup() {
  pinMode(RELAY_PIN, OUTPUT);
  pinMode(GREEN_LED_PIN, OUTPUT);
  pinMode(RED_LED_PIN, OUTPUT);
  pinMode(BUZZER_PIN, OUTPUT);
  pinMode(BUTTON_PIN, INPUT_PULLUP);

  digitalWrite(BUZZER_PIN, LOW);
  lockDoor();
}

void loop() {
  const uint32_t now = millis();

  if (g_unlockUntilMs != 0 && (int32_t)(now - g_unlockUntilMs) >= 0) {
    lockDoor();
  }

  if (digitalRead(BUTTON_PIN) == LOW && (now - g_lastDebounceMs) > 250) {
    g_lastDebounceMs = now;
    g_buttonPressLatched = true;
  }

  if (!g_alarmOn) {
    digitalWrite(BUZZER_PIN, LOW);
  }
}

bool consumeButtonPressed() {
  if (!g_buttonPressLatched) {
    return false;
  }

  g_buttonPressLatched = false;
  return true;
}

}  // namespace Hardware
