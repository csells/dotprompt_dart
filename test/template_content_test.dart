import 'package:dotprompt_dart/dotprompt_dart.dart';
import 'package:dotprompt_dart/src/partial_resolver.dart';
import 'package:test/test.dart';

class InlinePartialResolver implements DotPromptPartialResolver {
  InlinePartialResolver(this.partials);

  final Map<String, String> partials;

  @override
  String? resolve(String name) => partials[name];
}

String greetHelper(HelperInvocation invocation) {
  final name = invocation.firstPositional?.toString() ?? '';
  return 'Hello, $name!';
}

String annotateHelper(HelperInvocation invocation) {
  final label = invocation.named('label')?.toString() ?? '';
  final value = invocation.firstPositional?.toString() ?? '';
  return '$label:$value';
}

void main() {
  group('Dotprompt template spec', () {
    group('Language basics', () {
      test('interpolates variables and nested properties', () {
        const promptString = '''
---
name: language_basics
input:
  schema:
    type: object
    properties:
      name:
        type: string
      address:
        type: object
        properties:
          city:
            type: string
---
Hello, {{name}} from {{address.city}}!
''';
        final prompt = DotPrompt(promptString);
        final output = prompt.render(
          input: {
            'name': 'Sam',
            'address': {'city': 'Portland'},
          },
        );
        expect(output.trim(), equals('Hello, Sam from Portland!'));
      });

      test('supports escaped literals and unescaped output', () {
        const promptString = r'''
---
name: escaped_values
input:
  schema:
    type: object
    properties:
      name:
        type: string
---
Literal: \{{name}}
Escaped: {{name}}
Unescaped: {{{name}}}
''';
        final prompt = DotPrompt(promptString);
        final output = prompt.render(input: {'name': '<b>Sam</b>'});
        expect(output, contains('Literal: {{name}}'));
        expect(output, contains('Escaped: &lt;b&gt;Sam&lt;/b&gt;'));
        expect(output, contains('Unescaped: <b>Sam</b>'));
      });
    });

    group('Built-in helpers', () {
      test('#if renders the matching branch', () {
        const promptString = '''
---
name: helper_if
input:
  schema:
    type: object
    properties:
      isMember:
        type: boolean
---
{{#if isMember}}Welcome back{{else}}Join us{{/if}}
''';
        final prompt = DotPrompt(promptString);
        expect(
          prompt.render(input: {'isMember': true}).trim(),
          equals('Welcome back'),
        );
        expect(
          prompt.render(input: {'isMember': false}).trim(),
          equals('Join us'),
        );
      });

      test('#unless renders when the condition is falsy', () {
        const promptString = '''
---
name: helper_unless
input:
  schema:
    type: object
    properties:
      isSubmitted:
        type: boolean
---
{{#unless isSubmitted}}Pending review{{/unless}}
''';
        final prompt = DotPrompt(promptString);
        expect(
          prompt.render(input: {'isSubmitted': false}).trim(),
          equals('Pending review'),
        );
        expect(prompt.render(input: {'isSubmitted': true}).trim(), equals(''));
      });

      test('#each exposes array metadata', () {
        const promptString = '''
---
name: helper_each_array
input:
  schema:
    type: object
    properties:
      items:
        type: array
        items:
          type: string
---
{{#each items}}{{@index}}={{this}}{{#if @first}}[first]{{/if}}{{#if @last}}[last]{{/if}}{{#unless @last}}, {{/unless}}{{/each}}
''';
        final prompt = DotPrompt(promptString);
        final output = prompt.render(
          input: {
            'items': ['alpha', 'beta', 'omega'],
          },
        );
        expect(output.trim(), equals('0=alpha[first], 1=beta, 2=omega[last]'));
      });

      test('#each exposes object keys', () {
        const promptString = '''
---
name: helper_each_object
input:
  schema:
    type: object
    properties:
      settings:
        type: object
---
{{#each settings}}{{@key}}={{this}}{{#unless @last}}, {{/unless}}{{/each}}
''';
        final prompt = DotPrompt(promptString);
        final output = prompt.render(
          input: {
            'settings': {'theme': 'dark', 'layout': 'compact'},
          },
        );
        final parts = output.trim().split(', ');
        expect(parts, hasLength(2));
        expect(parts.any((part) => part == 'theme=dark'), isTrue);
        expect(parts.any((part) => part == 'layout=compact'), isTrue);
      });
    });

    group('Dotprompt helpers', () {
      test('json serializes input data', () {
        const promptString = '''
---
name: helper_json
input:
  schema:
    type: object
    properties:
      user:
        type: object
---
User: {{json user}}
''';
        final prompt = DotPrompt(promptString);
        final output = prompt.render(
          input: {
            'user': {'name': 'Ana', 'age': 30},
          },
        );
        expect(output.trim(), equals('User: {"name":"Ana","age":30}'));
      });

      test('role demarcates message boundaries', () {
        const promptString = '''
---
name: helper_role
input:
  schema:
    type: object
    properties:
      question:
        type: string
---
{{role "system"}}
You are a helpful AI assistant.
{{role "user"}}
{{question}}
''';
        final prompt = DotPrompt(promptString);
        final output = prompt.render(
          input: {'question': 'What is the forecast?'},
        );
        expect(
          output.trim(),
          equals('You are a helpful AI assistant.\nWhat is the forecast?'),
        );
      });

      test('history injects prior conversation', () {
        const promptString = '''
---
name: helper_history
input:
  schema:
    type: object
---
Conversation so far:
{{history}}
''';
        final prompt = DotPrompt(promptString);
        final output = prompt.render(
          input: const {},
          messages: const [
            {'role': 'user', 'content': 'Hi'},
            {'role': 'assistant', 'content': 'Hello!'},
          ],
        );
        expect(output, contains('Hi'));
        expect(output, contains('Hello!'));
      });

      test('media inserts the referenced url', () {
        const promptString = '''
---
name: helper_media
input:
  schema:
    type: object
    properties:
      imageUrl:
        type: string
---
Describe this image:
{{media url=imageUrl}}
''';
        final prompt = DotPrompt(promptString);
        final output = prompt.render(
          input: {'imageUrl': 'https://example.com/image.png'},
        );
        expect(output, contains('https://example.com/image.png'));
      });

      test('section acts as a structural marker', () {
        const promptString = '''
---
name: helper_section
input:
  schema:
    type: object
---
Intro
{{section "output"}}
Conclusion
''';
        final prompt = DotPrompt(promptString);
        final output = prompt.render(input: const {});
        expect(output.trim(), equals('Intro\nConclusion'));
      });
    });

    group('Partials', () {
      test('includes the referenced partial', () {
        const promptString = '''
---
name: partial_basic
---
Greeting: {{> greeting }}
''';
        final prompt = DotPrompt(
          promptString,
          partialResolver: InlinePartialResolver({
            'greeting': 'Hello from partial.',
          }),
        );
        expect(
          prompt.render(input: const {}).trim(),
          equals('Greeting: Hello from partial.'),
        );
      });

      test('passes positional and named arguments to partials', () {
        const promptString = '''
---
name: partial_arguments
input:
  schema:
    type: object
    properties:
      user:
        type: object
---
{{> welcomeCard user greeting="Welcome"}}
''';
        final prompt = DotPrompt(
          promptString,
          partialResolver: InlinePartialResolver({
            'welcomeCard': 'Greeting: {{greeting}}, Name: {{name}}',
          }),
        );
        final output = prompt.render(
          input: {
            'user': {'name': 'Ada'},
          },
        );
        expect(output.trim(), equals('Greeting: Welcome, Name: Ada'));
      });

      test('supports partials that receive scoped context', () {
        const promptString = '''
---
name: partial_scoped
input:
  schema:
    type: object
    properties:
      users:
        type: array
---
{{#each users}}{{> userCard this}}{{#unless @last}}\n{{/unless}}{{/each}}
''';
        final prompt = DotPrompt(
          promptString,
          partialResolver: InlinePartialResolver({
            'userCard': 'User: {{name}}',
          }),
        );
        final output = prompt.render(
          input: {
            'users': [
              {'name': 'Sam'},
              {'name': 'Lee'},
            ],
          },
        );
        expect(output.trim(), equals('User: Sam\nUser: Lee'));
      });
    });

    group('Custom helpers', () {
      test('invoke custom helper with positional arguments', () {
        const promptString = '''
---
name: helper_custom_positional
input:
  schema:
    type: object
    properties:
      name:
        type: string
---
{{greet name}}
''';
        final prompt = DotPrompt(promptString);
        prompt.registerHelper('greet', greetHelper);
        final output = prompt.render(input: {'name': 'Sky'});
        expect(output.trim(), equals('Hello, Sky!'));
      });

      test('invoke custom helper with named arguments', () {
        const promptString = '''
---
name: helper_custom_named
input:
  schema:
    type: object
    properties:
      value:
        type: string
---
{{annotate value label="ID"}}
''';
        final prompt = DotPrompt(promptString);
        prompt.registerHelper('annotate', annotateHelper);
        final output = prompt.render(input: {'value': '007'});
        expect(output.trim(), equals('ID:007'));
      });
    });

    group('Context variables', () {
      test('@root keeps access to the original input', () {
        const promptString = '''
---
name: context_root
input:
  schema:
    type: object
    properties:
      owner:
        type: string
      items:
        type: array
---
{{#each items}}Item: {{this}} (owner: {{@root.owner}}){{#unless @last}}, {{/unless}}{{/each}}
''';
        final prompt = DotPrompt(promptString);
        final output = prompt.render(
          input: {
            'owner': 'team',
            'items': ['alpha', 'beta'],
          },
        );
        expect(
          output.trim(),
          equals('Item: alpha (owner: team), Item: beta (owner: team)'),
        );
      });

      test('@metadata exposes prompt state', () {
        const promptString = '''
---
name: context_metadata
model: gemini-1.5-flash
---
Prompt: {{@metadata.prompt.name}}
Model: {{@metadata.prompt.model}}
Docs: {{#each @metadata.docs}}{{this}}{{#unless @last}}, {{/unless}}{{/each}}
History: {{#each @metadata.messages}}{{content}}{{#unless @last}} | {{/unless}}{{/each}}
''';
        final prompt = DotPrompt(promptString);
        final output = prompt.render(
          input: const {},
          docs: const ['Guide'],
          messages: const [
            {'role': 'user', 'content': 'Hello'},
            {'role': 'assistant', 'content': 'Hi!'},
          ],
        );
        expect(output, contains('Prompt: context_metadata'));
        expect(output, contains('Model: gemini-1.5-flash'));
        expect(output, contains('Docs: Guide'));
        expect(output, contains('History: Hello | Hi!'));
      });

      test('render context adds custom @ variables', () {
        const promptString = '''
---
name: context_custom
input:
  schema:
    type: object
---
State: {{@state.name}}
Admin: {{@isAdmin}}
''';
        final prompt = DotPrompt(promptString);
        final output = prompt.render(
          input: const {},
          context: {
            'state': {'name': 'Evelyn'},
            'isAdmin': true,
          },
        );
        expect(output, contains('State: Evelyn'));
        expect(output, contains('Admin: true'));
      });
    });
  });
}
