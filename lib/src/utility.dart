import 'package:yaml/yaml.dart';

/// Helper function to convert YamlMap/Map recursively to `Map<String, dynamic>`
dynamic yamlToMap(dynamic yaml) {
  if (yaml is YamlMap || yaml is Map) {
    return Map<String, dynamic>.fromEntries(
      (yaml as Map).entries.map(
        (e) => MapEntry(e.key.toString(), yamlToMap(e.value)),
      ),
    );
  } else if (yaml is YamlList || yaml is List) {
    return yamlToList(yaml);
  } else {
    return yaml;
  }
}

/// Helper function to convert YamlList/List recursively to `List<dynamic>`
dynamic yamlToList(dynamic yaml) {
  if (yaml is YamlList || yaml is List) {
    return (yaml as List).map(yamlToMap).toList();
  } else {
    return yaml;
  }
}
