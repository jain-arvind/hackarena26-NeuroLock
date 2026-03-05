#ifndef AUTH_ENGINE_H
#define AUTH_ENGINE_H

#include <Arduino.h>

namespace Auth {

bool isAuthorizedCommand(const String& command);

}  // namespace Auth

#endif
