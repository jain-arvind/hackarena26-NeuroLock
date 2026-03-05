#ifndef BLE_SERVER_H
#define BLE_SERVER_H

#include <Arduino.h>

namespace BleServer {

using CommandHandler = void (*)(const String& command);

void setup(CommandHandler handler);
void loop();

bool isConnected();
void notifyStatus(const String& status);

}  // namespace BleServer

#endif
