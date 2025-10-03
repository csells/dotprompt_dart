import 'template_error.dart';
import 'template_messages.dart';
import 'template_state.dart';

/// Describes results of message processing
class TemplateResult {
  TemplateResult({this.state, this.message, this.pop, this.err, this.result});
  TemplateState? state;
  bool? pop;
  TemplateError? err;
  String? result;
  TemplateMessage? message;
}
