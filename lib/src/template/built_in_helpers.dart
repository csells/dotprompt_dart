import 'dart:convert';

/// Built-in helpers for dotprompt template spec
/// https://google.github.io/dotprompt/reference/template/

/// JSON helper - serializes a value to JSON
String jsonHelper(List<dynamic> attributes, Function? fn) {
  if (attributes.isEmpty) return '{}';

  final value = attributes[0];
  return jsonEncode(value);
}

/// Role helper - marks the beginning of a message with a specific role
/// In dotprompt, this is used for multi-message prompts
/// For now, we just skip it and render the content after it
String roleHelper(List<dynamic> attributes, Function? fn) {
  // The role helper doesn't produce output itself
  // It's a structural marker for message boundaries
  return '';
}

/// History helper - inserts conversation history
/// For now, returns empty string as we need to integrate with message context
String historyHelper(List<dynamic> attributes, Function? fn) {
  // TODO: Integrate with message history from context
  return '';
}

/// Media helper - inserts media content
/// Returns the media URL or reference
String mediaHelper(List<dynamic> attributes, Function? fn) {
  // Extract url from named arguments
  // Attributes come in as a list, where named args are in a Map
  if (attributes.isEmpty) return '';

  // Look for url in named arguments
  for (final attr in attributes) {
    if (attr is Map && attr.containsKey('url')) {
      final urlValue = attr['url'];
      // If it's a string, return it directly; otherwise convert to string
      return urlValue.toString();
    }
  }

  return '';
}

/// Section helper - marks content positioning
/// For now, just returns empty string as it's a structural marker
String sectionHelper(List<dynamic> attributes, Function? fn) {
  // The section helper is a structural marker
  // It doesn't produce output itself
  return '';
}

/// Returns a map of all built-in helpers
Map<String, Function(List<dynamic>, Function?)> getBuiltInHelpers() {
  return {
    'json': jsonHelper,
    'role': roleHelper,
    'history': historyHelper,
    'media': mediaHelper,
    'section': sectionHelper,
  };
}
