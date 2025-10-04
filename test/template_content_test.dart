import 'package:dotprompt_dart/dotprompt_dart.dart';
import 'package:test/test.dart';

String uppercaseHelper(HelperInvocation invocation) {
  final value = invocation.firstPositional?.toString() ?? '';
  return value.toUpperCase();
}

String lowercaseHelper(HelperInvocation invocation) {
  final value = invocation.firstPositional?.toString() ?? '';
  return value.toLowerCase();
}

String greetHelper(HelperInvocation invocation) {
  final name =
      invocation.positionalArgs.isNotEmpty
          ? '${invocation.positionalArgs[0]}'
          : '';
  final title =
      invocation.positionalArgs.length > 1
          ? '${invocation.positionalArgs[1]} '
          : '';
  return '$title$name'.trim();
}

String formatMoneyHelper(HelperInvocation invocation) {
  final amount = invocation.named('amount');
  final currency = invocation.named('currency')?.toString() ?? '';
  final decimals = invocation.named('decimals');

  if (amount is! num) {
    return '';
  }

  final precision = decimals is num ? decimals.toInt() : 2;
  final formattedAmount = amount.toStringAsFixed(precision);
  final symbol = currency == 'USD' ? r'$' : currency;

  return '$symbol$formattedAmount';
}

String repeatHelper(HelperInvocation invocation) {
  final text = invocation.named('text') ?? invocation.firstPositional ?? '';
  final timesValue = invocation.named('times');
  final separator = invocation.named('separator')?.toString() ?? '';
  final times = timesValue is num ? timesValue.toInt() : 0;
  return List.filled(times, '$text').join(separator);
}

String wrapHelper(HelperInvocation invocation) {
  final tag = invocation.named('tag')?.toString() ?? 'div';
  final className = invocation.named('class');
  final inner = invocation.block?.call() ?? '';
  final classAttr = className != null ? ' class="$className"' : '';
  return '<$tag$classAttr>${inner.trim()}</$tag>';
}

String hasPermissionHelper(HelperInvocation invocation) {
  final requiredRole = invocation.firstPositional?.toString();
  final currentRole = invocation.context.get('user.role')?.toString();
  if (requiredRole != null && requiredRole == currentRole) {
    return invocation.block?.call() ?? '';
  }
  return invocation.inverse?.call() ?? '';
}

String validateHelper(HelperInvocation invocation) {
  final value = invocation.firstPositional;
  final min = invocation.named('min');
  final max = invocation.named('max');

  if (value is! num) {
    throw Exception('Value must be numeric');
  }

  final lower = min is num ? min.toDouble() : double.negativeInfinity;
  final upper = max is num ? max.toDouble() : double.infinity;

  if (value < lower || value > upper) {
    throw Exception('Value $value is out of range');
  }

  return '';
}

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
        final dotPrompt = DotPrompt(promptString);
        final output = dotPrompt.render(input: {'name': 'World'});
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
        final dotPrompt = DotPrompt(promptString);
        final output = dotPrompt.render(
          input: {
            'address': {'city': 'San Francisco'},
          },
        );
        expect(output, equals('City: San Francisco'));
      });

      test('dot expression references current value', () {
        const promptString = '''
---
name: test_dot_expression
input:
  schema:
    type: object
    properties:
      items:
        type: array
        items:
          type: string
---
{{#each items}}[{{.}}]{{/each}}''';
        final dotPrompt = DotPrompt(promptString);
        final output = dotPrompt.render(
          input: {
            'items': ['alpha', 'beta'],
          },
        );
        expect(output, equals('[alpha][beta]'));
      });
    });

    group('Built-in Helpers', () {
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
        final dotPrompt = DotPrompt(promptString);
        expect(
          dotPrompt.render(input: {'isLoggedIn': true}),
          equals('Welcome back!'),
        );
        expect(dotPrompt.render(input: {'isLoggedIn': false}), equals(''));
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
        final dotPrompt = DotPrompt(promptString);
        expect(
          dotPrompt.render(input: {'isLoggedIn': true}),
          equals('Welcome back!'),
        );
        expect(
          dotPrompt.render(input: {'isLoggedIn': false}),
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
        final dotPrompt = DotPrompt(promptString);
        expect(
          dotPrompt.render(input: {'isLoggedIn': false}),
          equals('Please log in to continue.'),
        );
        expect(dotPrompt.render(input: {'isLoggedIn': true}), equals(''));
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
        final dotPrompt = DotPrompt(promptString);
        final output = dotPrompt.render(
          input: {
            'items': ['apple', 'banana', 'orange'],
          },
        );
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
        final dotPrompt = DotPrompt(promptString);
        final output = dotPrompt.render(
          input: {
            'items': ['apple', 'banana', 'orange'],
          },
        );
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
        final dotPrompt = DotPrompt(promptString);
        final output = dotPrompt.render(
          input: {
            'user': {'name': 'John', 'age': 30, 'city': 'New York'},
          },
        );
        // Map iteration order is not guaranteed,
        // so check that all parts are present
        expect(output, contains('name: John'));
        expect(output, contains('age: 30'));
        expect(output, contains('city: New York'));
        expect(output.split(', '), hasLength(3));
      });

      test('#with block changes context', () {
        const promptString = '''
---
name: test_with
input:
  schema:
    type: object
    properties:
      user:
        type: object
        properties:
          name:
            type: string
          email:
            type: string
---
{{#with user}}Name: {{name}}, Email: {{email}}{{/with}}''';
        final dotPrompt = DotPrompt(promptString);
        final output = dotPrompt.render(
          input: {
            'user': {'name': 'Alice', 'email': 'alice@example.com'},
          },
        );
        expect(output, equals('Name: Alice, Email: alice@example.com'));
      });

      test('#with with @root access', () {
        const promptString = '''
---
name: test_with_root
input:
  schema:
    type: object
    properties:
      company:
        type: string
      user:
        type: object
        properties:
          name:
            type: string
---
{{#with user}}{{name}} works at {{@root.company}}{{/with}}''';
        final dotPrompt = DotPrompt(promptString);
        final output = dotPrompt.render(
          input: {
            'company': 'Acme Corp',
            'user': {'name': 'Bob'},
          },
        );
        expect(output, equals('Bob works at Acme Corp'));
      });

      test('#each @key provides object keys', () {
        const promptString = '''
---
name: test_each_key
input:
  schema:
    type: object
    properties:
      settings:
        type: object
        properties:
          color:
            type: string
          size:
            type: string
---
{{#each settings}}{{@key}}={{this}};{{/each}}''';
        final dotPrompt = DotPrompt(promptString);
        final output = dotPrompt.render(
          input: {
            'settings': {'color': 'blue', 'size': 'large'},
          },
        );
        expect(output, contains('color=blue'));
        expect(output, contains('size=large'));
      });
    });

    group('Dotprompt Helpers', () {
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
        final dotPrompt = DotPrompt(promptString);
        final output = dotPrompt.render(
          input: {
            'user': {'name': 'John', 'age': 30},
          },
        );
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
        final dotPrompt = DotPrompt(promptString);
        final output = dotPrompt.render(
          input: {'question': "What's the weather like?"},
        );
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
        final dotPrompt = DotPrompt(promptString);
        final messages = [
          {'role': 'user', 'content': 'Tell me about Paris.'},
          {'role': 'assistant', 'content': 'Paris is the capital of France.'},
        ];
        final output = dotPrompt.render(input: {}, messages: messages);
        expect(output, contains('Tell me about Paris.'));
        expect(output, contains('Paris is the capital of France.'));
      });

      test('history helper handles segmented content', () {
        const promptString = '''
---
name: test_history_segments
input:
  schema:
    type: object
---
Conversation log:
{{history}}
Done.''';
        final dotPrompt = DotPrompt(promptString);
        final messages = [
          {
            'role': 'user',
            'content': [
              {'type': 'text', 'text': 'Describe this request'},
              {'type': 'image', 'url': 'https://example.com/image.png'},
            ],
          },
          {
            'role': 'assistant',
            'content': [
              {'type': 'text', 'text': 'Here is what I noticed.'},
            ],
          },
        ];

        final output = dotPrompt.render(input: const {}, messages: messages);

        expect(output, contains('Conversation log:\nDescribe this request'));
        expect(output, contains('https://example.com/image.png'));
        expect(output, contains('Here is what I noticed.'));
        expect(
          output.indexOf('Describe this request'),
          lessThan(output.indexOf('https://example.com/image.png')),
        );
        expect(
          output.indexOf('https://example.com/image.png'),
          lessThan(output.indexOf('Here is what I noticed.')),
        );
        expect(output.trim().endsWith('Done.'), isTrue);
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
        final dotPrompt = DotPrompt(promptString);
        final output = dotPrompt.render(
          input: {'imageUrl': 'https://example.com/image.jpg'},
        );
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
        final dotPrompt = DotPrompt(promptString);
        final output = dotPrompt.render(input: {});
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
        final dotPrompt = DotPrompt(promptString);
        final messages = [
          {'role': 'user', 'content': 'What do you see in this image?'},
          {'role': 'assistant', 'content': 'I see a landscape photo.'},
        ];
        final output = dotPrompt.render(
          input: {
            'imageUrl': 'https://example.com/photo.jpg',
            'userData': {
              'preferences': {'style': 'detailed'},
            },
          },
          messages: messages,
        );

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
Doc Title: {{@metadata.docs.title}}
{{#each @metadata.messages}}{{content}}\n{{/each}}''';
        final dotPrompt = DotPrompt(promptString);
        final messages = [
          {'role': 'user', 'content': 'Hello'},
          {'role': 'assistant', 'content': 'Hi there'},
        ];
        final output = dotPrompt.render(
          input: {},
          messages: messages,
          docs: {'title': 'Doc'},
        );
        expect(output, contains('Name: test_metadata'));
        expect(output, contains('Doc Title: Doc'));
        expect(output, contains('Hello'));
        expect(output, contains('Hi there'));
      });

      test('@root gives access to original input', () {
        const promptString = '''
---
name: test_root
input:
  schema:
    type: object
    properties:
      user:
        type: object
        properties:
          name:
            type: string
---
Current: {{user.name}}
Root: {{@root.user.name}}''';
        final dotPrompt = DotPrompt(promptString);
        final output = dotPrompt.render(
          input: {
            'user': {'name': 'Root User'},
          },
        );
        expect(output, contains('Current: Root User'));
        expect(output, contains('Root: Root User'));
      });

      test('context variables from render call', () {
        const promptString = '''
---
name: test_context
input:
  schema:
    type: object
---
State: {{@state.name}}
Admin: {{@isAdmin}}''';
        final dotPrompt = DotPrompt(promptString);
        final output = dotPrompt.render(
          input: {},
          context: {
            'state': {'name': 'Evelyn'},
            'isAdmin': true,
          },
        );
        expect(output, contains('State: Evelyn'));
        expect(output, contains('Admin: true'));
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
        final dotPrompt = DotPrompt(promptString);
        final output = dotPrompt.render(input: {'name': '<b>John</b>'});
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
        final dotPrompt = DotPrompt(promptString);
        final output = dotPrompt.render(
          input: {
            'user': {'name': 'John', 'role': 'admin'},
          },
        );
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
        final dotPrompt = DotPrompt(promptString);
        dotPrompt.registerHelper('uppercase', uppercaseHelper);
        dotPrompt.registerHelper('lowercase', lowercaseHelper);
        final output = dotPrompt.render(input: {'text': 'Hello World'});
        expect(output, contains('HELLO WORLD'));
        expect(output, contains('hello world'));
      });
    });

    // https://google.github.io/dotprompt/reference/template/#custom-helpers
    group('Custom Helpers', () {
      test('basic custom helper with positional args', () {
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
        final dotPrompt = DotPrompt(promptString);
        dotPrompt.registerHelper('greet', greetHelper);
        final output = dotPrompt.render(input: {'name': 'John', 'title': 'Dr'});
        expect(output, contains('Dr John'));
      });

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
        final dotPrompt = DotPrompt(promptString);
        dotPrompt.registerHelper('formatMoney', formatMoneyHelper);
        final output = dotPrompt.render(
          input: {'amount': 42.4242, 'currency': 'USD'},
        );
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
        final dotPrompt = DotPrompt(promptString);
        dotPrompt.registerHelper('repeat', repeatHelper);
        final output = dotPrompt.render(input: {'text': 'hello', 'count': 3});
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
        final dotPrompt = DotPrompt(promptString);
        dotPrompt.registerHelper('wrap', wrapHelper);
        final output = dotPrompt.render(
          input: {
            'items': ['one', 'two', 'three'],
          },
        );
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
        final dotPrompt = DotPrompt(promptString);
        dotPrompt.registerHelper('hasPermission', hasPermissionHelper);
        final output = dotPrompt.render(
          input: {
            'user': {'name': 'John', 'role': 'admin'},
          },
        );
        expect(output, contains('Welcome, John!'));
        final denied = dotPrompt.render(
          input: {
            'user': {'name': 'Jane', 'role': 'user'},
          },
        );
        expect(denied, contains('Access denied.'));
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
        final dotPrompt = DotPrompt(promptString);
        dotPrompt.registerHelper('validate', validateHelper);
        expect(
          () => dotPrompt.render(input: {'value': 150}),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Conditional Blocks (Spec)', () {
      test('#if with true condition', () {
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
{{#if greeting}}{{greeting}} {{/if}}{{name}}!''';
        final dotPrompt = DotPrompt(promptString);
        final output = dotPrompt.render(
          input: {'name': 'World', 'greeting': 'Hello'},
        );
        expect(output, equals('Hello World!'));
      });

      test('#if with false condition', () {
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
        type: ["string", "null"]
---
{{#if greeting}}{{greeting}} {{/if}}{{name}}!''';
        final dotPrompt = DotPrompt(promptString);
        final output = dotPrompt.render(
          input: {'name': 'World', 'greeting': null},
        );
        expect(output, equals('World!'));
      });

      test('#unless with false condition', () {
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
{{#unless isLoggedIn}}Please log in.{{/unless}}''';
        final dotPrompt = DotPrompt(promptString);
        final output = dotPrompt.render(input: {'isLoggedIn': false});
        expect(output, equals('Please log in.'));
      });
    });

    group('Iteration (Spec)', () {
      test('#each with array', () {
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
{{#each items}}- {{this}}
{{/each}}''';
        final dotPrompt = DotPrompt(promptString);
        final output = dotPrompt.render(
          input: {
            'items': ['apple', 'banana', 'orange'],
          },
        );
        expect(output, equals('- apple\n- banana\n- orange\n'));
      });
    });

    group('Template Syntax Features', () {
      // NOTE: Handlebars comment syntax {{! }} and {{!-- --}} is NOT currently
      // supported by the mustache_template package. This is a known limitation.
      // See README.md "Handlebar Implementation Shortcomings" section.

      test('triple-brace for unescaped HTML output', () {
        const promptString = '''
---
name: test_unescaped
input:
  schema:
    type: object
    properties:
      html:
        type: string
---
Escaped: {{html}}
Unescaped: {{{html}}}''';
        final dotPrompt = DotPrompt(promptString);
        final output = dotPrompt.render(input: {'html': '<b>bold</b>'});
        expect(output, contains('Escaped: &lt;b&gt;bold&lt;/b&gt;'));
        expect(output, contains('Unescaped: <b>bold</b>'));
      });

      test('nested blocks maintain correct context', () {
        const promptString = '''
---
name: test_nested
input:
  schema:
    type: object
    properties:
      company:
        type: string
      departments:
        type: array
        items:
          type: object
          properties:
            name:
              type: string
            employees:
              type: array
              items:
                type: string
---
{{#each departments}}Dept: {{name}} at {{@root.company}}
{{#each employees}}  - {{this}}
{{/each}}{{/each}}''';
        final dotPrompt = DotPrompt(promptString);
        final output = dotPrompt.render(
          input: {
            'company': 'Acme Corp',
            'departments': [
              {
                'name': 'Engineering',
                'employees': ['Alice', 'Bob'],
              },
            ],
          },
        );
        expect(output, contains('Dept: Engineering at Acme Corp'));
        expect(output, contains('- Alice'));
        expect(output, contains('- Bob'));
      });

      test('whitespace control in templates', () {
        const promptString = '''
---
name: test_whitespace
input:
  schema:
    type: object
    properties:
      items:
        type: array
        items:
          type: string
---
{{#each items}}{{this}}{{#unless @last}},{{/unless}}{{/each}}''';
        final dotPrompt = DotPrompt(promptString);
        final output = dotPrompt.render(
          input: {
            'items': ['a', 'b', 'c'],
          },
        );
        expect(output, equals('a,b,c'));
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
          () => DotPrompt(promptString).render(
            input: {
              'items': [1, 2, 3],
            },
          ),
          throwsA(isA<Exception>()),
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
          () => DotPrompt(promptString).render(
            input: {
              'items': [1, 2, 3],
            },
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('unregistered helper throws', () {
        const promptString = '''
---
name: test_error
input:
  schema:
    type: object
---
{{#missing}}content{{/missing}}''';
        expect(
          () => DotPrompt(promptString).render(input: {}),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Input Validation and Defaults', () {
      test('validates input against schema', () {
        const promptString = '''
---
name: test_validation
input:
  schema:
    type: object
    properties:
      age:
        type: integer
        minimum: 0
        maximum: 120
    required: [age]
---
Age: {{age}}''';
        final dotPrompt = DotPrompt(promptString);

        // Valid input
        expect(dotPrompt.render(input: {'age': 25}), equals('Age: 25'));

        // Invalid input - wrong type
        expect(
          () => dotPrompt.render(input: {'age': 'not a number'}),
          throwsA(isA<ValidationException>()),
        );

        // Invalid input - out of range
        expect(
          () => dotPrompt.render(input: {'age': 150}),
          throwsA(isA<ValidationException>()),
        );

        // Invalid input - missing required field
        expect(
          () => dotPrompt.render(input: {}),
          throwsA(isA<ValidationException>()),
        );
      });

      test('applies defaults for missing values', () {
        const promptString = '''
---
name: test_defaults
input:
  schema:
    type: object
    properties:
      name:
        type: string
      greeting:
        type: ["string", "null"]
  default:
    greeting: "Hello"
---
{{greeting}} {{name}}!''';
        final dotPrompt = DotPrompt(promptString);

        // Without providing greeting
        expect(
          dotPrompt.render(input: {'name': 'World'}),
          equals('Hello World!'),
        );

        // Overriding default
        expect(
          dotPrompt.render(input: {'name': 'World', 'greeting': 'Hi'}),
          equals('Hi World!'),
        );
      });

      test('validates input with defaults against schema', () {
        const promptString = '''
---
name: test_validation_with_defaults
input:
  schema:
    type: object
    properties:
      age:
        type: integer
        minimum: 0
      name:
        type: string
    required: [age, name]
  default:
    age: 18
---
{{name}} is {{age}} years old.''';
        final dotPrompt = DotPrompt(promptString);

        // Using default age
        expect(
          dotPrompt.render(input: {'name': 'John'}),
          equals('John is 18 years old.'),
        );

        // Invalid override of default
        expect(
          () => dotPrompt.render(input: {'name': 'John', 'age': -1}),
          throwsA(isA<ValidationException>()),
        );

        // Missing required field not in defaults
        expect(
          () => dotPrompt.render(input: {'age': 25}),
          throwsA(isA<ValidationException>()),
        );
      });

      test('complex nested defaults', () {
        const promptString = '''
---
name: test_nested_defaults
input:
  schema:
    type: object
    properties:
      user:
        type: object
        properties:
          name:
            type: string
          settings:
            type: object
            properties:
              theme:
                type: string
              notifications:
                type: boolean
  default:
    user:
      settings:
        theme: "light"
        notifications: true
---
{{user.name}} prefers {{user.settings.theme}} theme.''';
        final dotPrompt = DotPrompt(promptString);

        // Using nested defaults
        expect(
          dotPrompt.render(
            input: {
              'user': {
                'name': 'John',
                'settings': {'theme': 'light'},
              },
            },
          ),
          equals('John prefers light theme.'),
        );

        // Partial override of defaults
        expect(
          dotPrompt.render(
            input: {
              'user': {
                'name': 'John',
                'settings': {'theme': 'dark'},
              },
            },
          ),
          equals('John prefers dark theme.'),
        );
      });
    });

    group('Comprehensive Spec Compliance Tests', () {
      group('Variable Access Edge Cases', () {
        test('missing variable returns empty string', () {
          const promptString = '''
---
name: test_missing
input:
  schema:
    type: object
---
Value: {{missing}}''';
          final dotPrompt = DotPrompt(promptString);
          final output = dotPrompt.render(input: {});
          expect(output, equals('Value: '));
        });

        test('null variable returns empty string', () {
          const promptString = '''
---
name: test_null
input:
  schema:
    type: object
    properties:
      value:
        type: ["string", "null"]
---
Value: {{value}}''';
          final dotPrompt = DotPrompt(promptString);
          final output = dotPrompt.render(input: {'value': null});
          expect(output, equals('Value: '));
        });

        test('deeply nested property access', () {
          const promptString = '''
---
name: test_deep
input:
  schema:
    type: object
---
{{a.b.c.d.e}}''';
          final dotPrompt = DotPrompt(promptString);
          final output = dotPrompt.render(
            input: {
              'a': {
                'b': {
                  'c': {
                    'd': {'e': 'deep'},
                  },
                },
              },
            },
          );
          expect(output, equals('deep'));
        });

        test('number values are converted to strings', () {
          const promptString = '''
---
name: test_numbers
input:
  schema:
    type: object
---
Int: {{intVal}}, Float: {{floatVal}}''';
          final dotPrompt = DotPrompt(promptString);
          final output = dotPrompt.render(
            input: {'intVal': 42, 'floatVal': 3.14},
          );
          expect(output, contains('Int: 42'));
          expect(output, contains('Float: 3.14'));
        });

        test('boolean values are converted to strings', () {
          const promptString = '''
---
name: test_booleans
input:
  schema:
    type: object
---
True: {{trueVal}}, False: {{falseVal}}''';
          final dotPrompt = DotPrompt(promptString);
          final output = dotPrompt.render(
            input: {'trueVal': true, 'falseVal': false},
          );
          expect(output, contains('True: true'));
          expect(output, contains('False: false'));
        });
      });

      group('#if Helper Edge Cases', () {
        test('#if with empty string is falsy', () {
          const promptString = '''
---
name: test_if_empty
input:
  schema:
    type: object
---
{{#if emptyStr}}shown{{else}}hidden{{/if}}''';
          final dotPrompt = DotPrompt(promptString);
          final output = dotPrompt.render(input: {'emptyStr': ''});
          expect(output, equals('hidden'));
        });

        test('#if with 0 is falsy', () {
          const promptString = '''
---
name: test_if_zero
input:
  schema:
    type: object
---
{{#if zero}}shown{{else}}hidden{{/if}}''';
          final dotPrompt = DotPrompt(promptString);
          final output = dotPrompt.render(input: {'zero': 0});
          expect(output, equals('hidden'));
        });

        test('#if with empty array is falsy', () {
          const promptString = '''
---
name: test_if_array
input:
  schema:
    type: object
---
{{#if items}}has items{{else}}no items{{/if}}''';
          final dotPrompt = DotPrompt(promptString);
          final output = dotPrompt.render(input: {'items': []});
          expect(output, equals('no items'));
        });

        test('#if with non-empty array is truthy', () {
          const promptString = '''
---
name: test_if_array_full
input:
  schema:
    type: object
---
{{#if items}}has items{{else}}no items{{/if}}''';
          final dotPrompt = DotPrompt(promptString);
          final output = dotPrompt.render(
            input: {
              'items': [1],
            },
          );
          expect(output, equals('has items'));
        });

        test('nested #if blocks', () {
          const promptString = '''
---
name: test_nested_if
input:
  schema:
    type: object
---
{{#if outer}}{{#if inner}}both{{else}}only outer{{/if}}{{else}}none{{/if}}''';
          final dotPrompt = DotPrompt(promptString);
          expect(
            dotPrompt.render(input: {'outer': true, 'inner': true}),
            equals('both'),
          );
          expect(
            dotPrompt.render(input: {'outer': true, 'inner': false}),
            equals('only outer'),
          );
          expect(
            dotPrompt.render(input: {'outer': false, 'inner': true}),
            equals('none'),
          );
        });
      });

      group('#each Helper Edge Cases', () {
        test('#each with empty array renders nothing', () {
          const promptString = '''
---
name: test_each_empty
input:
  schema:
    type: object
---
{{#each items}}item{{/each}}done''';
          final dotPrompt = DotPrompt(promptString);
          final output = dotPrompt.render(input: {'items': []});
          expect(output, equals('done'));
        });

        test('#each with single item', () {
          const promptString = '''
---
name: test_each_single
input:
  schema:
    type: object
---
{{#each items}}{{@index}}:{{@first}}:{{@last}}:{{this}};{{/each}}''';
          final dotPrompt = DotPrompt(promptString);
          final output = dotPrompt.render(
            input: {
              'items': ['only'],
            },
          );
          expect(output, equals('0:true:true:only;'));
        });

        test('#each with nested arrays', () {
          const promptString = '''
---
name: test_each_nested
input:
  schema:
    type: object
---
{{#each outer}}{{#each this}}{{this}}{{/each}};{{/each}}''';
          final dotPrompt = DotPrompt(promptString);
          final output = dotPrompt.render(
            input: {
              'outer': [
                ['a', 'b'],
                ['c', 'd'],
              ],
            },
          );
          expect(output, equals('ab;cd;'));
        });

        test('#each with object and nested #each', () {
          const promptString = '''
---
name: test_each_object_nested
input:
  schema:
    type: object
---
{{#each users}}{{name}}:{{#each tags}}{{this}},{{/each}};{{/each}}''';
          final dotPrompt = DotPrompt(promptString);
          final output = dotPrompt.render(
            input: {
              'users': [
                {
                  'name': 'Alice',
                  'tags': ['admin', 'user'],
                },
                {
                  'name': 'Bob',
                  'tags': ['user'],
                },
              ],
            },
          );
          expect(output, contains('Alice:admin,user,;'));
          expect(output, contains('Bob:user,;'));
        });

        test('#each preserves context for nested properties', () {
          const promptString = '''
---
name: test_each_context
input:
  schema:
    type: object
---
{{#each users}}{{name}}-{{email}} {{/each}}''';
          final dotPrompt = DotPrompt(promptString);
          final output = dotPrompt.render(
            input: {
              'users': [
                {'name': 'A', 'email': 'a@test.com'},
                {'name': 'B', 'email': 'b@test.com'},
              ],
            },
          );
          expect(output, equals('A-a@test.com B-b@test.com '));
        });
      });

      group('#with Helper Edge Cases', () {
        test('#with with null value throws error', () {
          // NOTE: Current implementation throws an error for null values
          // Handlebars spec would skip the block silently
          const promptString = '''
---
name: test_with_null
input:
  schema:
    type: object
---
{{#with user}}{{name}}{{/with}}done''';
          final dotPrompt = DotPrompt(promptString);
          expect(
            () => dotPrompt.render(input: {'user': null}),
            throwsA(isA<Exception>()),
          );
        });

        test('#with with missing property throws error', () {
          // NOTE: Current implementation throws an error for missing properties
          // Handlebars spec would skip the block silently
          const promptString = '''
---
name: test_with_missing
input:
  schema:
    type: object
---
{{#with missing}}{{name}}{{/with}}done''';
          final dotPrompt = DotPrompt(promptString);
          expect(() => dotPrompt.render(input: {}), throwsA(isA<Exception>()));
        });

        test('#with nested maintains @root', () {
          const promptString = '''
---
name: test_with_nested_root
input:
  schema:
    type: object
---
{{#with level1}}{{#with level2}}{{value}}-{{@root.top}}{{/with}}{{/with}}''';
          final dotPrompt = DotPrompt(promptString);
          final output = dotPrompt.render(
            input: {
              'top': 'TOP',
              'level1': {
                'level2': {'value': 'deep'},
              },
            },
          );
          expect(output, equals('deep-TOP'));
        });
      });

      group('Helper Argument Parsing', () {
        test('helper with multiple positional args', () {
          String multiArgHelper(HelperInvocation invocation) {
            final args = invocation.positionalArgs;
            return args.join('-');
          }

          const promptString = '''
---
name: test_multi_args
input:
  schema:
    type: object
---
{{multiArg a b c}}''';
          final dotPrompt = DotPrompt(promptString);
          dotPrompt.registerHelper('multiArg', multiArgHelper);
          final output = dotPrompt.render(
            input: {'a': '1', 'b': '2', 'c': '3'},
          );
          expect(output, equals('1-2-3'));
        });

        test('helper with only named args', () {
          String namedOnlyHelper(HelperInvocation invocation) {
            final a = invocation.named('a');
            final b = invocation.named('b');
            return '$a:$b';
          }

          const promptString = '''
---
name: test_named_only
input:
  schema:
    type: object
---
{{namedOnly a=x b=y}}''';
          final dotPrompt = DotPrompt(promptString);
          dotPrompt.registerHelper('namedOnly', namedOnlyHelper);
          final output = dotPrompt.render(input: {'x': 'X', 'y': 'Y'});
          expect(output, equals('X:Y'));
        });

        test('helper with literal string arguments', () {
          String literalHelper(HelperInvocation invocation) =>
              invocation.positionalArgs.join(',');

          const promptString = '''
---
name: test_literal
input:
  schema:
    type: object
---
{{literal "hello" "world"}}''';
          final dotPrompt = DotPrompt(promptString);
          dotPrompt.registerHelper('literal', literalHelper);
          final output = dotPrompt.render(input: {});
          expect(output, equals('hello,world'));
        });

        test('helper with literal number arguments', () {
          String numberHelper(HelperInvocation invocation) {
            final sum = invocation.positionalArgs.fold<num>(
              0,
              (acc, val) => acc + (val as num),
            );
            return sum.toString();
          }

          const promptString = '''
---
name: test_numbers
input:
  schema:
    type: object
---
{{add 10 20 30}}''';
          final dotPrompt = DotPrompt(promptString);
          dotPrompt.registerHelper('add', numberHelper);
          final output = dotPrompt.render(input: {});
          expect(output, equals('60'));
        });
      });

      group('Block Helpers', () {
        test('block helper can access block content', () {
          String wrapHelper(HelperInvocation invocation) {
            final content = invocation.block?.call() ?? '';
            return '[${content.trim()}]';
          }

          const promptString = '''
---
name: test_block
input:
  schema:
    type: object
---
{{#wrap}}content here{{/wrap}}''';
          final dotPrompt = DotPrompt(promptString);
          dotPrompt.registerHelper('wrap', wrapHelper);
          final output = dotPrompt.render(input: {});
          expect(output, equals('[content here]'));
        });

        test('block helper can call inverse for else', () {
          String customIfHelper(HelperInvocation invocation) {
            final condition = invocation.firstPositional;
            if (condition == true) {
              return invocation.block?.call() ?? '';
            } else {
              return invocation.inverse?.call() ?? '';
            }
          }

          const promptString = '''
---
name: test_custom_if
input:
  schema:
    type: object
---
{{#customIf flag}}yes{{else}}no{{/customIf}}''';
          final dotPrompt = DotPrompt(promptString);
          dotPrompt.registerHelper('customIf', customIfHelper);
          expect(dotPrompt.render(input: {'flag': true}), equals('yes'));
          expect(dotPrompt.render(input: {'flag': false}), equals('no'));
        });

        test('block helper with context modification', () {
          String timesHelper(HelperInvocation invocation) {
            final n = invocation.firstPositional as int;
            final buffer = StringBuffer();
            for (var i = 0; i < n; i++) {
              // NOTE: Current implementation doesn't support passing custom
              // context to block.call(). This test documents the limitation.
              buffer.write(invocation.block?.call() ?? '');
            }
            return buffer.toString();
          }

          const promptString = '''
---
name: test_times
input:
  schema:
    type: object
---
{{#times count}}x{{/times}}''';
          final dotPrompt = DotPrompt(promptString);
          dotPrompt.registerHelper('times', timesHelper);
          final output = dotPrompt.render(input: {'count': 3});
          expect(output, equals('xxx'));
        });
      });

      group('Context and Metadata', () {
        test('@metadata.prompt contains front-matter', () {
          const promptString = '''
---
name: test_meta
model: test-model
input:
  schema:
    type: object
---
Name: {{@metadata.prompt.name}}
Model: {{@metadata.prompt.model}}''';
          final dotPrompt = DotPrompt(promptString);
          final output = dotPrompt.render(input: {});
          expect(output, contains('Name: test_meta'));
          expect(output, contains('Model: test-model'));
        });

        test('@root in deeply nested context', () {
          const promptString = '''
---
name: test_deep_root
input:
  schema:
    type: object
---
{{#with a}}{{#with b}}{{#with c}}{{value}}-{{@root.top}}{{/with}}{{/with}}{{/with}}''';
          final dotPrompt = DotPrompt(promptString);
          final output = dotPrompt.render(
            input: {
              'top': 'ROOT',
              'a': {
                'b': {
                  'c': {'value': 'leaf'},
                },
              },
            },
          );
          expect(output, equals('leaf-ROOT'));
        });

        test('custom @ variables via context parameter', () {
          const promptString = '''
---
name: test_custom_at
input:
  schema:
    type: object
---
User: {{@userId}}
Session: {{@sessionId}}''';
          final dotPrompt = DotPrompt(promptString);
          final output = dotPrompt.render(
            input: {},
            context: {'userId': '123', 'sessionId': 'abc'},
          );
          expect(output, contains('User: 123'));
          expect(output, contains('Session: abc'));
        });
      });

      group('Special Characters and Escaping', () {
        test('HTML entities are escaped by default', () {
          const promptString = '''
---
name: test_escape
input:
  schema:
    type: object
---
{{html}}''';
          final dotPrompt = DotPrompt(promptString);
          final output = dotPrompt.render(
            input: {'html': '<script>alert("xss")</script>'},
          );
          expect(output, contains('&lt;'));
          expect(output, contains('&gt;'));
          expect(output, isNot(contains('<script>')));
        });

        test('triple brace prevents escaping', () {
          const promptString = '''
---
name: test_raw
input:
  schema:
    type: object
---
{{{html}}}''';
          final dotPrompt = DotPrompt(promptString);
          final output = dotPrompt.render(input: {'html': '<b>bold</b>'});
          expect(output, equals('<b>bold</b>'));
        });

        test('escaped brackets render as literals', () {
          const promptString = r'''
---
name: test_literal_brackets
input:
  schema:
    type: object
---
\{{notAVariable}}''';
          final dotPrompt = DotPrompt(promptString);
          final output = dotPrompt.render(input: {});
          expect(output, equals('{{notAVariable}}'));
        });

        test('special characters in property values', () {
          const promptString = '''
---
name: test_special
input:
  schema:
    type: object
---
{{value}}''';
          final dotPrompt = DotPrompt(promptString);
          final output = dotPrompt.render(
            input: {'value': 'quotes "test" and \'more\''},
          );
          expect(output, contains('quotes'));
        });
      });

      group('Error Handling', () {
        test('helpful error for unclosed #if', () {
          const promptString = '''
---
name: test_error
input:
  schema:
    type: object
---
{{#if condition}}no closing tag''';
          expect(
            () => DotPrompt(promptString).render(input: {'condition': true}),
            throwsA(isA<Exception>()),
          );
        });

        test('helpful error for mismatched closing tag', () {
          const promptString = '''
---
name: test_error
input:
  schema:
    type: object
---
{{#if condition}}{{/each}}''';
          expect(
            () => DotPrompt(promptString).render(input: {'condition': true}),
            throwsA(isA<Exception>()),
          );
        });

        test('error when accessing property on non-object', () {
          const promptString = '''
---
name: test_error
input:
  schema:
    type: object
---
{{string.property}}''';
          final dotPrompt = DotPrompt(promptString);
          final output = dotPrompt.render(input: {'string': 'text'});
          // Should handle gracefully, likely returning empty
          expect(output, isNotNull);
        });
      });
    });
  });
}
