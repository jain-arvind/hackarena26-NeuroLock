#include "auth_engine.h"

namespace Auth {

bool isAuthorizedCommand(const String& command) {
  return command == "UNLOCK" || command == "LOCK" || command == "ALARM_ON" ||
         command == "ALARM_OFF" || command == "PING";
}

}  // namespace Auth
