import 'template_error.dart';
import 'template_messages.dart';
import 'template_state.dart';

/// Represents the result of processing a template state machine message.
///
/// Contains optional state transitions, output text, errors, and follow-up
/// messages.
class TemplateResult {
  /// Creates a template processing result.
  TemplateResult({this.state, this.message, this.pop, this.err, this.result});

  /// The next state to transition to, if any.
  TemplateState? state;

  /// Whether to pop the current state from the stack.
  bool? pop;

  /// An error that occurred during processing, if any.
  TemplateError? err;

  /// Text to append to the template output, if any.
  String? result;

  /// A follow-up message to process, if any.
  TemplateMessage? message;
}
