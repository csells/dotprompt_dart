import '../characters_consts.dart';
import '../notify_types.dart';
import '../template_context.dart';
import '../template_messages.dart';
import '../template_result.dart';
import '../template_state.dart';

/// State for processing the closing tag of a block (e.g., {{/if}}).
class GetBlockEndState extends TemplateState {
  /// Creates a new block end state for the specified block name.
  GetBlockEndState({required this.blockName}) {
    methods = {'process': process};

    final o = String.fromCharCode(openBracket);
    final c = String.fromCharCode(closeBracket);
    final s = String.fromCharCode(slash);
    final h = String.fromCharCode(sharp);

    _look = '$o$o$s$blockName$c$c'; // {{/<name>}}
    _openTag = '$o$o$h$blockName';
  }

  /// The name of the block being closed.
  final String blockName;
  bool _search = false;
  bool _esc = false;
  String _look = '';
  String _openTag = '';
  String _tmp = '';
  String _body = '';
  int _count = 0;
  int _innerOpened = 0;

  /// Processes characters to find the closing block tag, handling nested
  /// blocks.
  TemplateResult? process(ProcessMessage msg, TemplateContext context) {
    final charCode = msg.charCode;

    if (charCode == eos) {
      return TemplateResult(
        pop: true,
        message: ProcessMessage(charCode: charCode),
      );
    }

    if (_search) {
      _tmp += String.fromCharCode(charCode);

      var l = _look;
      var t = _tmp;
      var o = _openTag;

      final op = context.opt('ignoreTagCaseSensetive');

      if (op == true) {
        l = l.toLowerCase();
        t = t.toLowerCase();
        o = o.toLowerCase();
      }

      if ((t[_count] != l[_count] && t[_count] != o[_count]) ||
          _count >= l.length) {
        _search = false;
        _body += _tmp;
      } else {
        _count++;
      }

      if (t == o) {
        _search = false;
        _body += _tmp;
        _innerOpened++;
      } else if (t.length == l.length) {
        if (_innerOpened > 0) {
          _search = false;
          _body += _tmp;
          _innerOpened--;
        } else {
          return TemplateResult(
            pop: true,
            message: NotifyMessage(
              charCode: null,
              type: notifyBlockEndResult,
              value: _body,
            ),
          );
        }
      }
    } else {
      if (charCode == openBracket && !_esc) {
        _search = true;
        _tmp = String.fromCharCode(openBracket);
        _count = 0;
      } else if (charCode == backSlash && !_esc) {
        _esc = true;
      } else {
        _esc = false;
        _body += String.fromCharCode(charCode);
      }
    }

    return null;
  }
}
