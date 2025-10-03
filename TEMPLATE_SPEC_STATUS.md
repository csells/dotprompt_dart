# Dotprompt Template Specification Implementation Status

Based on https://google.github.io/dotprompt/reference/template/

## ✅ Implemented (Spec-Compliant)

### Core Template Features
- ✅ Basic variable interpolation: `{{variableName}}`
- ✅ Nested property access: `{{object.propertyName}}`
- ✅ Current context: `{{.}}` and `{{this}}`

### Conditional Blocks
- ✅ `{{#if condition}}...{{/if}}` - Simple truthy checks
- ✅ `{{#unless condition}}...{{/unless}}` - Inverted if
- ⚠️ `{{#if condition}}...{{else}}...{{/if}}` - **NOT IMPLEMENTED**

### Iteration
- ✅ `{{#each array}}...{{/each}}` - Array iteration
- ✅ `{{this}}` - Current item in iteration
- ⚠️ `{{@index}}` - **NOT IMPLEMENTED**
- ⚠️ `{{@first}}` - **NOT IMPLEMENTED**
- ⚠️ `{{@last}}` - **NOT IMPLEMENTED**
- ⚠️ `{{@key}}` - **NOT IMPLEMENTED** (for object iteration)

### Scoping
- ✅ `{{#with object}}...{{/with}}` - Change context

### Partials
- ✅ `{{>partialName}}` - Basic partial inclusion
- ⚠️ `{{>partialName arg=value}}` - **Partial implementation** (basic support exists, argument passing may need work)

## ❌ Not Implemented (In Spec)

### Built-in Helpers
- ❌ `{{json variable}}` - JSON serialization
- ❌ `{{role "roleName"}}` - Message role assignment
- ❌ `{{history}}` - Conversation history insertion
- ❌ `{{media url=imageUrl}}` - Media content insertion
- ❌ `{{section "sectionName"}}` - Content positioning

### Context Variables
- ❌ `{{@root}}` - Root context access
- ❌ `{{@metadata.prompt}}` - Prompt metadata
- ❌ `{{@metadata.docs}}` - Documentation metadata
- ❌ `{{@metadata.messages}}` - Messages metadata

### Escape Syntax
- ❌ `\{{variable}}` - Literal display (escaped)
- ❌ `{{{variable}}}` - Raw/unescaped output

### Custom Helpers
- ⚠️ Custom helper registration API exists but may need refinement

## 🚫 Removed (NOT in Spec)

These Mustache/Handlebars features were removed as they're not in the dotprompt spec:

- 🚫 Generic sections: `{{#variable}}...{{/variable}}` (without if/each/unless)
- 🚫 Inverted sections: `{{^variable}}...{{/variable}}` (caret syntax)

## Test Status

- **106 tests passing** ✅
- **22 tests skipped** (all spec-compliant, waiting for implementation)
  - 6 tests for `{{else}}`, `@index`, `@first`, `@last`, `@key`
  - 10 tests for built-in helpers and metadata
  - 6 tests for custom helpers
- **2 tests failing** (edge cases in `#if` parsing)

## Next Steps for Full Spec Compliance

1. **High Priority**
   - Implement `{{else}}` block support in `#if`
   - Implement iteration context variables: `@index`, `@first`, `@last`, `@key`

2. **Medium Priority**
   - Implement built-in helpers: `json`, `role`, `history`, `media`, `section`
   - Implement `@metadata` context variables
   - Implement escape syntax: `\{{` and `{{{`

3. **Low Priority**
   - Refine custom helper registration API
   - Add `@root` context variable
   - Fix remaining 2 test failures

## Architecture Notes

- Removed dependency on `mustache_template` package
- Using internal template engine in `lib/src/template/`
- Only spec-defined blocks (`if`, `unless`, `each`, `with`) are supported
- All other `{{#helper}}` blocks require registered helpers
