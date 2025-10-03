/// StateMachine processes messages of different types.
library;

abstract class TemplateMessage {
  String getName();
}

class InitMessage extends TemplateMessage {
  InitMessage({this.value});
  final dynamic value;

  @override
  String getName() => 'init';
}

class ProcessMessage extends TemplateMessage {
  ProcessMessage({required this.charCode});
  final int charCode;

  @override
  String getName() => 'process';
}

class NotifyMessage extends TemplateMessage {
  NotifyMessage({this.charCode, this.type, this.value});
  final int? charCode;
  final int? type;
  final dynamic value;

  @override
  String getName() => 'notify';
}
