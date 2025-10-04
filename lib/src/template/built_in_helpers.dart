import 'dart:convert';

import 'helper_types.dart';

/// Built-in helpers for dotprompt template spec
/// https://google.github.io/dotprompt/reference/template/

/// JSON helper - serializes a value to JSON.
String jsonHelper(HelperInvocation invocation) {
  if (invocation.positionalArgs.isEmpty) return '{}';
  final value = invocation.firstPositional;
  return jsonEncode(value);
}

/// Role helper - marks the beginning of a message with a specific role.
/// The helper is structural and does not emit content.
String roleHelper(HelperInvocation invocation) => '';

/// History helper - inserts conversation history using existing helpers.
String historyHelper(HelperInvocation invocation) {
  final context = invocation.context;
  final messages = context.metadata['messages'];

  if (messages is! List) return '';
  if (messages.isEmpty) return '';

  final buffer = StringBuffer();
  var isFirst = true;

  for (final message in messages) {
    if (message is! Map) continue;

    final role = message['role'];
    final content = message['content'];

    if (role != null) {
      context.call('role', [role.toString()]);
    }

    if (content == null) continue;

    if (!isFirst) {
      buffer.writeln();
    }
    isFirst = false;

    if (content is List) {
      var firstSegment = true;
      for (final segment in content) {
        final segmentText = _contentSegmentToString(segment);
        if (segmentText == null) continue;
        if (!firstSegment) {
          buffer.writeln();
        }
        firstSegment = false;
        buffer.write(segmentText);
      }
    } else {
      buffer.write(content.toString());
    }
  }

  return buffer.toString();
}

/// Media helper - inserts media content. Returns textual representation.
String mediaHelper(HelperInvocation invocation) {
  final url = invocation.named('url') ?? invocation.firstPositional;
  if (url == null) return '';
  return url.toString();
}

/// Section helper - structural marker used for section ordering.
String sectionHelper(HelperInvocation invocation) => '';

String? _contentSegmentToString(dynamic segment) {
  if (segment is String) return segment;
  if (segment is Map) {
    final type = segment['type'];
    if (type == 'text' && segment['text'] != null) {
      return segment['text'].toString();
    }
    if ((type == 'media' || type == 'image') && segment['url'] != null) {
      return segment['url'].toString();
    }
    if (segment['content'] != null) {
      return segment['content'].toString();
    }
  }

  if (segment == null) return null;
  return segment.toString();
}

/// Returns a map of all built-in helpers.
Map<String, TemplateHelper> getBuiltInHelpers() => {
  'json': jsonHelper,
  'role': roleHelper,
  'history': historyHelper,
  'media': mediaHelper,
  'section': sectionHelper,
};
