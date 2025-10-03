import 'template_context.dart';
import 'template_messages.dart';
import 'template_result.dart';

class TemplateState {
  /// available method for processing.
  /// Each method function should have two params: <TemplateMessage msg, TemplateContext context>
  /// For a state to process a message of concrete type, it must implement a method with key of Message.getName() value.
  Map<String, Function> methods = {};

  /// Checks if state can accept messages of this type.
  bool canAcceptMessage(TemplateMessage msg) {
    final messageName = msg.getName();

    if (methods[messageName] != null) {
      return true;
    }

    return false;
  }

  /// Processing message
  TemplateResult? processMessage(TemplateMessage msg, TemplateContext context) {
    final messageName = msg.getName();

    if (methods[messageName] != null) {
      return methods[messageName]!(msg, context);
    }

    return null;
  }
}
