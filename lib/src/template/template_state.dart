import 'template_context.dart';
import 'template_messages.dart';
import 'template_result.dart';

/// Base class for template state machine states.
///
/// Each state implements message handling methods for processing template
/// characters. Subclasses populate the [methods] map with handlers for specific
/// message types.
class TemplateState {
  /// Map of message names to handler functions.
  ///
  /// Each handler function receives a [TemplateMessage] and [TemplateContext]
  /// and returns a [TemplateResult].
  Map<String, Function> methods = {};

  /// Checks if this state can accept messages of the given type.
  bool canAcceptMessage(TemplateMessage msg) {
    final messageName = msg.getName();

    if (methods[messageName] != null) {
      return true;
    }

    return false;
  }

  /// Processes a message in this state.
  ///
  /// Returns a [TemplateResult] if the message was handled, null otherwise.
  TemplateResult? processMessage(TemplateMessage msg, TemplateContext context) {
    final messageName = msg.getName();

    if (methods[messageName] != null) {
      // ignore: avoid_dynamic_calls
      return methods[messageName]!(msg, context);
    }

    return null;
  }
}
