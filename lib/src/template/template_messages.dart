/// Messages processed by the template state machine.
library;

/// Base class for all template state machine messages.
abstract class TemplateMessage {
  /// Returns the name of this message type.
  String getName();
}

/// Initialization message sent to states.
class InitMessage extends TemplateMessage {
  /// Creates an initialization message with optional [value].
  InitMessage({this.value});

  /// The initialization value.
  final dynamic value;

  @override
  String getName() => 'init';
}

/// Message representing a character to process from the template source.
class ProcessMessage extends TemplateMessage {
  /// Creates a process message with the given [charCode].
  ProcessMessage({required this.charCode});

  /// The character code to process.
  final int charCode;

  @override
  String getName() => 'process';
}

/// Notification message sent between states to signal events.
class NotifyMessage extends TemplateMessage {
  /// Creates a notification message with optional parameters.
  NotifyMessage({this.charCode, this.type, this.value});

  /// Optional character code associated with this notification.
  final int? charCode;

  /// The notification type (see notify_types.dart for constants).
  final int? type;

  /// Optional value payload for this notification.
  final dynamic value;

  @override
  String getName() => 'notify';
}
