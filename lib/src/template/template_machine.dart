import 'characters_consts.dart';
import 'errors_types.dart';
import 'states/root_state.dart';
import 'template_context.dart';
import 'template_messages.dart';
import 'template_result.dart';
import 'template_state.dart';

class TemplateMachine {
  TemplateMachine(String? tpl) {
    _template = tpl;
  }
  final List<TemplateState> _stack = [];
  String _res = '';

  String? _template;

  int _line = 0; // template lining support
  int _symbol = 0;

  /// Launching machine with a given TemplateContext
  String run(TemplateContext context) {
    _stack.clear();
    _stack.add(RootState());
    _res = '';

    if (_template != null && _template!.isNotEmpty) {
      final lines = _template!.split('\n');

      for (var l = 0; l < lines.length; l++) {
        _line = l + 1;
        final line = lines[l];

        for (var i = 0; i < line.length; i++) {
          //print('Current state is: ${_stack.last}');
          _symbol = i;
          final charCode = line.codeUnitAt(i);

          //print("char: ${line[i]}");

          context.symbol = _symbol;
          context.line = _line;

          _process(ProcessMessage(charCode: charCode), context);
        }

        if (l < lines.length - 1) {
          _process(ProcessMessage(charCode: enter), context);
        }
      }

      _process(ProcessMessage(charCode: eos), context);

      if (_stack.last is! RootState) {
        throw Exception(
          'Something go wrong: please check your template for issues.',
        );
      }
    }

    return _res;
  }

  /// Processing machine message
  void _process(TemplateMessage msg, TemplateContext context) {
    final state = _stack.last;

    if (state.canAcceptMessage(msg)) {
      final res = state.processMessage(msg, context);

      if (res != null) {
        _processResult(res, context);
      }
    }
  }

  /// Processing message result
  void _processResult(TemplateResult r, TemplateContext context) {
    if (r.result != null) {
      _res += r.result!;
    }

    if (r.pop ?? false) {
      pop();
    }

    if (r.state != null) {
      _stack.add(r.state!);
    }

    if (r.message != null) {
      _process(r.message!, context);
    }

    if (r.err != null) {
      if (context.opt('ignoreUnregisteredHelperErrors') == true &&
          r.err!.code == errorHelperUnregistered) {
        print('Warning: ${r.err}');
      } else {
        final e = 'Error (${r.err!.code}) on $_line:$_symbol ${r.err!.text}';

        print(e);

        throw Exception(e);
      }
    }
  }

  /// Pops top state from stack
  void pop() {
    _stack.removeLast();
  }
}
