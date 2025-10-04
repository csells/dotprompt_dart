import 'helper_types.dart';

/// Manages template rendering context including data, helpers, and options.
///
/// The context holds the current data value, registered helpers, rendering
/// options, and metadata. It supports hierarchical scoping through child
/// contexts.
class TemplateContext {
  /// Creates a template context.
  ///
  /// Required parameters:
  /// - [value]: The current data value for this context
  /// - [helpers]: Map of registered helper functions
  /// - [options]: Rendering options
  /// - [partialResolver]: Function to resolve partial template sources
  ///
  /// Optional parameters:
  /// - [parent]: Parent context for hierarchical scoping
  /// - [metadata]: Additional metadata for the render operation
  /// - [sharedAtVariables]: Variables shared across context hierarchy
  /// - [localAtVariables]: Variables local to this context
  /// - [rootValue]: The root data value for the entire render operation
  TemplateContext({
    required dynamic value,
    required Map<String, TemplateHelper> helpers,
    required Map<String, dynamic> options,
    required String? Function(String)? partialResolver,
    TemplateContext? parent,
    Map<String, dynamic>? metadata,
    Map<String, dynamic>? sharedAtVariables,
    Map<String, dynamic>? localAtVariables,
    dynamic rootValue,
  }) : _value = value,
       _helpers = helpers,
       _options = options,
       _partialResolver = partialResolver,
       _metadata = metadata ?? parent?._metadata ?? <String, dynamic>{},
       _sharedAtVariables = {
         if (parent != null) ...parent._sharedAtVariables,
         if (sharedAtVariables != null) ...sharedAtVariables,
       },
       _localAtVariables = localAtVariables ?? <String, dynamic>{},
       _rootValue = rootValue ?? parent?._rootValue ?? value {
    _sharedAtVariables.putIfAbsent('@metadata', () => _metadata);
    _sharedAtVariables.putIfAbsent('@root', () => _rootValue);
  }

  final dynamic _value;
  final Map<String, TemplateHelper> _helpers;
  final Map<String, dynamic> _options;
  final String? Function(String)? _partialResolver;
  final Map<String, dynamic> _metadata;
  final Map<String, dynamic> _sharedAtVariables;
  final Map<String, dynamic> _localAtVariables;
  final dynamic _rootValue;

  /// Current character position in the template source.
  int symbol = 0;

  /// Current line number in the template source.
  int line = 0;

  /// Creates a child context preserving helper, option, and metadata state.
  TemplateContext child(dynamic value, {Map<String, dynamic>? locals}) =>
      TemplateContext(
        value: value,
        helpers: _helpers,
        options: _options,
        partialResolver: _partialResolver,
        parent: this,
        metadata: _metadata,
        sharedAtVariables: {..._sharedAtVariables, ..._localAtVariables},
        localAtVariables: locals,
        rootValue: _rootValue,
      );

  /// Checks if a helper with given name has been registered.
  bool callable(String helper) => _helpers.containsKey(helper);

  /// Invokes a helper with positional/named attributes and optional blocks.
  String call(
    String? helper,
    List<dynamic> attributes, {
    BlockRenderer? block,
    BlockRenderer? inverse,
  }) {
    if (helper == null || helper.isEmpty) {
      throw Exception('Helper name not specified');
    }

    final helperFn = _helpers[helper];
    if (helperFn == null) {
      throw Exception('Helper "$helper" is not registered');
    }

    final positional = <dynamic>[];
    final named = <String, dynamic>{};

    for (final attr in attributes) {
      if (attr is NamedArgument) {
        named[attr.key] = attr.value;
        continue;
      }

      positional.add(attr);
    }

    return helperFn(
      HelperInvocation(
        context: this,
        positionalArgs: positional,
        namedArgs: named,
        block: block,
        inverse: inverse,
      ),
    );
  }

  /// Returns partial template source for the given partial name.
  String? resolvePartial(String partialName) =>
      _partialResolver?.call(partialName);

  /// Returns a value from context data by given path.
  dynamic get(String path) {
    if (path.isEmpty) return null;

    if (path == '.' || path == 'this') {
      return _value;
    }

    // Debug output removed - use debugger or logging framework instead
    // if (path == 'debug_user') {
    //   print('DEBUG context data: $_value');
    // }

    final segments = path.split('.');
    if (segments.isEmpty) return null;

    if (segments[0].startsWith('@')) {
      return _resolveAtVariable(segments);
    }

    final value = _resolveValue(_value, segments);
    return value;
  }

  dynamic _resolveAtVariable(List<String> segments) {
    final head = segments.first;

    if (head == '@root') {
      return _resolveValue(_rootValue, segments.sublist(1));
    }

    if (head == '@metadata') {
      return _resolveValue(_metadata, segments.sublist(1));
    }

    final value =
        _localAtVariables.containsKey(head)
            ? _localAtVariables[head]
            : _sharedAtVariables[head];

    if (segments.length == 1) {
      return value;
    }

    return _resolveValue(value, segments.sublist(1));
  }

  dynamic _resolveValue(dynamic current, List<String> segments) {
    if (segments.isEmpty) return current;

    var cursor = current;

    for (final segment in segments) {
      if (cursor == null) return null;

      if (cursor is Map) {
        cursor = cursor[segment];
      } else if (cursor is List) {
        final index = int.tryParse(segment);
        if (index == null || index < 0 || index >= cursor.length) {
          return null;
        }
        cursor = cursor[index];
      } else {
        return null;
      }
    }

    return cursor;
  }

  /// Returns an option value or null when not set.
  dynamic opt(String name) => _options[name];

  /// Current context data (original value).
  dynamic get data => _value;

  /// Exposes registered helpers map.
  Map<String, TemplateHelper> get helpers => _helpers;

  /// Exposes rendering options.
  Map<String, dynamic> get options => _options;

  /// Returns metadata map in the current context.
  Map<String, dynamic> get metadata => _metadata;

  /// Returns the root value for the render operation.
  dynamic get rootValue => _rootValue;
}
