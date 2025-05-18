import 'package:dotprompt_dart/dotprompt_dart.dart';
import 'package:mustache_template/mustache_template.dart'
    show TemplateException;
import 'package:test/test.dart';

void main() {
  group('Template Content', () {
    group('Basic Expression Tests', () {
      test('simple variable interpolation', () {
        const promptString = '''
---
name: test_template
input:
  schema:
    type: object
    properties:
      name:
        type: string
---
Hello, {{name}}!''';
        final dotPrompt = DotPrompt.fromString(promptString);
        final output = dotPrompt.render({'name': 'World'});
        expect(output, equals('Hello, World!'));
      });

      test('nested object interpolation', () {
        const promptString = '''
---
name: test_nested
input:
  schema:
    type: object
    properties:
      address:
        type: object
        properties:
          city:
            type: string
---
City: {{address.city}}''';
        final dotPrompt = DotPrompt.fromString(promptString);
        final output = dotPrompt.render({
          'address': {'city': 'San Francisco'},
        });
        expect(output, equals('City: San Francisco'));
      });
    });

    group('Built-in Helpers', skip: 'TODO: make these work', () {
      test('#if conditional block', () {
        const promptString = '''
---
name: test_if
input:
  schema:
    type: object
    properties:
      isLoggedIn:
        type: boolean
---
{{#if isLoggedIn}}Welcome back!{{/if}}''';
        final dotPrompt = DotPrompt.fromString(promptString);
        expect(dotPrompt.render({'isLoggedIn': true}), equals('Welcome back!'));
        expect(dotPrompt.render({'isLoggedIn': false}), equals(''));
      });

      test('#if with else block', () {
        const promptString = '''
---
name: test_if_else
input:
  schema:
    type: object
    properties:
      isLoggedIn:
        type: boolean
---
{{#if isLoggedIn}}Welcome back!{{else}}Please log in.{{/if}}''';
        final dotPrompt = DotPrompt.fromString(promptString);
        expect(dotPrompt.render({'isLoggedIn': true}), equals('Welcome back!'));
        expect(
          dotPrompt.render({'isLoggedIn': false}),
          equals('Please log in.'),
        );
      });

      test('#unless block', () {
        const promptString = '''
---
name: test_unless
input:
  schema:
    type: object
    properties:
      isLoggedIn:
        type: boolean
---
{{#unless isLoggedIn}}Please log in to continue.{{/unless}}''';
        final dotPrompt = DotPrompt.fromString(promptString);
        expect(
          dotPrompt.render({'isLoggedIn': false}),
          equals('Please log in to continue.'),
        );
        expect(dotPrompt.render({'isLoggedIn': true}), equals(''));
      });

      test('#each with @index', () {
        const promptString = '''
---
name: test_each_index
input:
  schema:
    type: object
    properties:
      items:
        type: array
        items:
          type: string
---
{{#each items}}{{@index}}:{{this}}{{#unless @last}}, {{/unless}}{{/each}}''';
        final dotPrompt = DotPrompt.fromString(promptString);
        final output = dotPrompt.render({
          'items': ['apple', 'banana', 'orange'],
        });
        expect(output, equals('0:apple, 1:banana, 2:orange'));
      });

      test('#each with @first and @last', () {
        const promptString = '''
---
name: test_each_first_last
input:
  schema:
    type: object
    properties:
      items:
        type: array
        items:
          type: string
---
{{#each items}}{{#if @first}}First: {{/if}}{{this}}{{#if @last}} (last){{/if}}{{#unless @last}}, {{/unless}}{{/each}}''';
        final dotPrompt = DotPrompt.fromString(promptString);
        final output = dotPrompt.render({
          'items': ['apple', 'banana', 'orange'],
        });
        expect(output, equals('First: apple, banana, orange (last)'));
      });

      test('#each with object properties', () {
        const promptString = '''
---
name: test_each_object
input:
  schema:
    type: object
    properties:
      user:
        type: object
        properties:
          name:
            type: string
          age:
            type: integer
          city:
            type: string
---
{{#each user}}{{@key}}: {{this}}{{#unless @last}}, {{/unless}}{{/each}}''';
        final dotPrompt = DotPrompt.fromString(promptString);
        final output = dotPrompt.render({
          'user': {'name': 'John', 'age': 30, 'city': 'New York'},
        });
        expect(output, equals('age: 30, city: New York, name: John'));
      });
    });

    group('Dotprompt Helpers', skip: 'TODO: make these work', () {
      test('json helper serializes objects', () {
        const promptString = '''
---
name: test_json
input:
  schema:
    type: object
    properties:
      user:
        type: object
        properties:
          name:
            type: string
          age:
            type: integer
---
User info: {{json user}}''';
        final dotPrompt = DotPrompt.fromString(promptString);
        final output = dotPrompt.render({
          'user': {'name': 'John', 'age': 30},
        });
        expect(output, equals('User info: {"name":"John","age":30}'));
      });

      test('role helper for multi-message prompts', () {
        const promptString = '''
---
name: test_role
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
{{question}}''';
        final dotPrompt = DotPrompt.fromString(promptString);
        final output = dotPrompt.render({
          'question': "What's the weather like?",
        });
        expect(
          output,
          equals('''
You are a helpful AI assistant.
What's the weather like?'''),
        );
      });

      test('history helper for conversation context', () {
        const promptString = '''
---
name: test_history
input:
  schema:
    type: object
---
{{role "system"}}
You are a helpful AI assistant.
{{history}}
{{role "user"}}
What was my last question about?''';
        final dotPrompt = DotPrompt.fromString(promptString);
        // ignore: unused_local_variable
        final messages = [
          {'role': 'user', 'content': 'Tell me about Paris.'},
          {'role': 'assistant', 'content': 'Paris is the capital of France.'},
        ];
        final output = dotPrompt.render({} /* messages: messages */);
        expect(output, contains('Tell me about Paris.'));
        expect(output, contains('Paris is the capital of France.'));
      });

      test('media helper for image content', () {
        const promptString = '''
---
name: test_media
input:
  schema:
    type: object
    properties:
      imageUrl:
        type: string
---
Describe this image:
{{media url=imageUrl}}''';
        final dotPrompt = DotPrompt.fromString(promptString);
        final output = dotPrompt.render({
          'imageUrl': 'https://example.com/image.jpg',
        });
        expect(output, contains('https://example.com/image.jpg'));
      });

      test('section helper for content positioning', () {
        const promptString = '''
---
name: test_section
input:
  schema:
    type: object
---
This is the main content.
{{section "output"}}
This comes after the output instructions.''';
        final dotPrompt = DotPrompt.fromString(promptString);
        final output = dotPrompt.render({});
        expect(
          output,
          equals('''
This is the main content.
This comes after the output instructions.'''),
        );
      });

      test('combining multiple dotprompt helpers', () {
        const promptString = '''
---
name: test_combined
input:
  schema:
    type: object
    properties:
      imageUrl:
        type: string
      userData:
        type: object
---
{{role "system"}}
You are an image analysis assistant.
{{history}}
{{role "user"}}
Analyze this image and user data:
{{media url=imageUrl}}
User context: {{json userData}}''';
        final dotPrompt = DotPrompt.fromString(promptString);
        // ignore: unused_local_variable
        final messages = [
          {'role': 'user', 'content': 'What do you see in this image?'},
          {'role': 'assistant', 'content': 'I see a landscape photo.'},
        ];
        final output = dotPrompt.render({
          'imageUrl': 'https://example.com/photo.jpg',
          'userData': {
            'preferences': {'style': 'detailed'},
          },
        } /* messages: messages */);

        expect(output, contains('You are an image analysis assistant.'));
        expect(output, contains('What do you see in this image?'));
        expect(output, contains('I see a landscape photo.'));
        expect(output, contains('https://example.com/photo.jpg'));
        expect(output, contains('"preferences":{"style":"detailed"}'));
      });

      test('metadata context variable access', () {
        const promptString = '''
---
name: test_metadata
input:
  schema:
    type: object
---
Name: {{@metadata.prompt.name}}
Model: {{@metadata.prompt.model}}
{{#@metadata.messages}}{{content}}{{/@metadata.messages}}''';
        final dotPrompt = DotPrompt.fromString(promptString);
        // ignore: unused_local_variable
        final messages = [
          {'role': 'user', 'content': 'Hello'},
          {'role': 'assistant', 'content': 'Hi there'},
        ];
        final output = dotPrompt.render({} /* messages: messages */);
        expect(output, contains('Name: test_metadata'));
        expect(output, contains('Hello'));
        expect(output, contains('Hi there'));
      });

      test('escaped expressions', () {
        const promptString = r'''
---
name: test_escaped
input:
  schema:
    type: object
    properties:
      name:
        type: string
---
Literal: \{{name}}
Unescaped: {{{name}}}
Escaped: {{name}}''';
        final dotPrompt = DotPrompt.fromString(promptString);
        final output = dotPrompt.render({'name': '<b>John</b>'});
        expect(output, contains('Literal: {{name}}'));
        expect(output, contains('Unescaped: <b>John</b>'));
        expect(output, contains('Escaped: &lt;b&gt;John&lt;/b&gt;'));
      });

      test('partial templates', () {
        const promptString = '''
---
name: test_partial
input:
  schema:
    type: object
    properties:
      user:
        type: object
---
Header: {{>header}}
Content: {{>content user}}
Footer: {{>footer style="bold"}}''';
        final dotPrompt = DotPrompt.fromString(promptString);
        final output = dotPrompt.render({
          'user': {'name': 'John', 'role': 'admin'},
        });
        expect(output, contains('Header:'));
        expect(output, contains('Content:'));
        expect(output, contains('Footer:'));
      });

      test('custom helper registration', () {
        const promptString = '''
---
name: test_custom
input:
  schema:
    type: object
    properties:
      text:
        type: string
---
{{uppercase text}}
{{lowercase text}}''';
        final dotPrompt = DotPrompt.fromString(promptString);
        final output = dotPrompt.render({'text': 'Hello World'});
        expect(output, contains('HELLO WORLD'));
        expect(output, contains('hello world'));
      });
    });

    // https://google.github.io/dotprompt/reference/template/#custom-helpers
    group('Custom Helpers', skip: 'TODO: make these work', () {
      test(
        'basic custom helper with positional args',
        skip: 'TODO: make these work',
        () {
          const promptString = '''
---
name: test_custom_basic
input:
  schema:
    type: object
    properties:
      name:
        type: string
      title:
        type: string
---
{{greet name title}}''';
          final dotPrompt = DotPrompt.fromString(promptString);
          final output = dotPrompt.render({'name': 'John', 'title': 'Dr'});
          expect(output, contains('Dr John'));
        },
      );

      test('custom helper with named args', () {
        const promptString = '''
---
name: test_custom_named
input:
  schema:
    type: object
    properties:
      amount:
        type: number
      currency:
        type: string
---
{{formatMoney amount=amount currency=currency decimals=2}}''';
        final dotPrompt = DotPrompt.fromString(promptString);
        final output = dotPrompt.render({'amount': 42.4242, 'currency': 'USD'});
        expect(output, contains(r'$42.42'));
      });

      test('custom helper with mixed args', () {
        const promptString = '''
---
name: test_custom_mixed
input:
  schema:
    type: object
    properties:
      text:
        type: string
      count:
        type: integer
---
{{repeat text times=count separator=", "}}''';
        final dotPrompt = DotPrompt.fromString(promptString);
        final output = dotPrompt.render({'text': 'hello', 'count': 3});
        expect(output, contains('hello, hello, hello'));
      });

      test('custom helper with block content', () {
        const promptString = '''
---
name: test_custom_block
input:
  schema:
    type: object
    properties:
      items:
        type: array
        items:
          type: string
---
{{#wrap tag="ul" class="list"}}
  {{#each items}}
    <li>{{this}}</li>
  {{/each}}
{{/wrap}}''';
        final dotPrompt = DotPrompt.fromString(promptString);
        final output = dotPrompt.render({
          'items': ['one', 'two', 'three'],
        });
        expect(output, contains('<ul class="list">'));
        expect(output, contains('</ul>'));
        expect(output, contains('<li>one</li>'));
      });

      test('custom helper with context access', () {
        const promptString = '''
---
name: test_custom_context
input:
  schema:
    type: object
    properties:
      user:
        type: object
        properties:
          name:
            type: string
          role:
            type: string
---
{{#hasPermission "admin"}}
  Welcome, {{user.name}}!
{{else}}
  Access denied.
{{/hasPermission}}''';
        final dotPrompt = DotPrompt.fromString(promptString);
        final output = dotPrompt.render({
          'user': {'name': 'John', 'role': 'admin'},
        });
        expect(output, contains('Welcome, John!'));
      });

      test('custom helper with error handling', () {
        const promptString = '''
---
name: test_custom_error
input:
  schema:
    type: object
    properties:
      value:
        type: number
---
{{validate value min=0 max=100}}''';
        final dotPrompt = DotPrompt.fromString(promptString);
        expect(
          () => dotPrompt.render({'value': 150}),
          throwsA(isA<TemplateException>()),
        );
      });
    });

    group('Section Tests', () {
      test('section with true condition', () {
        const promptString = '''
---
name: test_template
input:
  schema:
    type: object
    properties:
      name:
        type: string
      greeting:
        type: string
---
{{#greeting}}{{greeting}} {{/greeting}}{{name}}!''';
        final dotPrompt = DotPrompt.fromString(promptString);
        final output = dotPrompt.render({'name': 'World', 'greeting': 'Hello'});
        expect(output, equals('Hello World!'));
      });

      test('section with false condition', () {
        const promptString = '''
---
name: test_template
input:
  schema:
    type: object
    properties:
      name:
        type: string
      greeting:
        type: string
---
{{#greeting}}{{greeting}} {{/greeting}}{{name}}!''';
        final dotPrompt = DotPrompt.fromString(promptString);
        final output = dotPrompt.render({'name': 'World', 'greeting': null});
        expect(output, equals('World!'));
      });

      test('inverted section', () {
        const promptString = '''
---
name: test_inverted
input:
  schema:
    type: object
    properties:
      isLoggedIn:
        type: boolean
---
{{^isLoggedIn}}Please log in.{{/isLoggedIn}}''';
        final dotPrompt = DotPrompt.fromString(promptString);
        final output = dotPrompt.render({'isLoggedIn': false});
        expect(output, equals('Please log in.'));
      });
    });

    group('List Iteration Tests', () {
      test('section with list', () {
        const promptString = '''
---
name: test_list
input:
  schema:
    type: object
    properties:
      items:
        type: array
        items:
          type: string
---
{{#items}}- {{.}}{{/items}}''';
        final dotPrompt = DotPrompt.fromString(promptString);
        final output = dotPrompt.render({
          'items': ['apple', 'banana', 'orange'],
        });
        expect(output, equals('- apple- banana- orange'));
      });
    });

    group('Error Cases', () {
      test('unclosed section throws', () {
        const promptString = '''
---
name: test_error
input:
  schema:
    type: object
---
{{#items}}unclosed section''';
        expect(
          () => DotPrompt.fromString(promptString).render({
            'items': [1, 2, 3],
          }),
          throwsA(isA<TemplateException>()),
        );
      });

      test('mismatched section tags throw', () {
        const promptString = '''
---
name: test_error
input:
  schema:
    type: object
---
{{#items}}content{{/wrong}}''';
        expect(
          () => DotPrompt.fromString(promptString).render({
            'items': [1, 2, 3],
          }),
          throwsA(isA<TemplateException>()),
        );
      });

      test('missing section value throws', () {
        const promptString = '''
---
name: test_error
input:
  schema:
    type: object
---
{{#missing}}content{{/missing}}''';
        expect(
          () => DotPrompt.fromString(promptString).render({}),
          throwsA(isA<TemplateException>()),
        );
      });
    });
  });
}
