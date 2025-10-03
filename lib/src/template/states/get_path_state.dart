import '../characters_consts.dart';
import '../errors_types.dart';
import '../notify_types.dart';
import '../template_context.dart';
import '../template_error.dart';
import '../template_messages.dart';
import '../template_result.dart';
import '../template_state.dart';

class GetPathState extends TemplateState {
  GetPathState({this.path}) {
    methods = {'process': process};
  }
  String? path;
  int? lastChar;

  TemplateResult? process(ProcessMessage msg, TemplateContext context) {
    final charCode = msg.charCode;

    path ??= '';

    if (charCode == eos) {
      return TemplateResult(
        pop: true,
        message: ProcessMessage(charCode: charCode),
      );
    } else if (charCode == dot) {
      if (path!.isEmpty) {
        return TemplateResult(
          err: TemplateError(
            text: 'Path should not start with point character',
            code: errorPathWrongSpecified,
          ),
        );
      }

      path = path! + String.fromCharCode(charCode);
    } else if (charCode >= 48 && charCode <= 57) {
      if (path!.isEmpty) {
        return TemplateResult(
          err: TemplateError(
            text: 'Path should not start with number character',
            code: errorPathWrongSpecified,
          ),
        );
      }

      path = path! + String.fromCharCode(charCode);
    } else if ((charCode >= 65 && charCode <= 90) ||
        (charCode >= 97 && charCode <= 122) ||
        charCode == 95) {
      path = path! + String.fromCharCode(charCode);
    } else if (charCode == space || charCode == closeBracket) {
      if (lastChar == dot) {
        return TemplateResult(
          err: TemplateError(
            text: 'Path should not end with dot character',
            code: errorPathWrongSpecified,
          ),
        );
      }
      return TemplateResult(
        pop: true,
        message: NotifyMessage(
          type: notifyPathResult,
          value: path,
          charCode: charCode,
        ),
      );
    } else {
      return TemplateResult(
        err: TemplateError(
          code: errorNotAValidPathChar,
          text:
              'Character "${String.fromCharCode(charCode)}" is not a valid in path',
        ),
      );
    }

    lastChar = charCode;

    return null;
  }
}
