// ignore_for_file: avoid_print

import 'package:json_schema/json_schema.dart';

void main() async {
  final schemaMap = {
    'type': 'object',
    'properties': {
      'maybeString': {
        'type': ['string', 'null'],
        'description': 'A string or null',
      },
    },
  };

  final schema = JsonSchema.create(schemaMap);
  print('schema.type: \\${schema.type}');
  print('schema.properties: \\${schema.properties}');
  print('maybeString.type: \\${schema.properties['maybeString']?.type}');
  print(
    'maybeString.description: \\${schema.properties['maybeString']?.description}',
  );
}
