class LogModel {
  LogModel({required this.message, DateTime? timestamp})
      : timestamp = timestamp ?? DateTime.now();

  final String message;
  final DateTime timestamp;

  String get pretty =>
      '[${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}] $message';
}
