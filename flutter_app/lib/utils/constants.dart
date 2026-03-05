class BleConstants {
  static const String deviceName = 'NeuroLock_ESP32';
  static const String serviceUuid = '19b10010-e8f2-537e-4f6c-d104768a1214';
  static const String commandCharacteristicUuid =
      '19b10011-e8f2-537e-4f6c-d104768a1214';
}

class BleCommands {
  static const String unlock = 'UNLOCK';
  static const String lock = 'LOCK';
  static const String alarmOn = 'ALARM_ON';
  static const String alarmOff = 'ALARM_OFF';
  static const String ping = 'PING';
}
