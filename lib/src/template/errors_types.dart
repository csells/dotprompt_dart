/// Error type constants for template parsing and rendering.
library;

/// Expected an open bracket ({) but found a different character.
const errorCharNotAOpenBracket = 1;

/// Expected a close bracket (}) but found a different character.
const errorChartNotACloseBracket = 2;

/// Invalid character in block name.
const errorNotAValidBlockNameChar = 3;

/// Invalid character in path expression.
const errorNotAValidPathChar = 4;

/// Unexpected character in sequence.
const errorWrongSequenceCharacter = 5;

/// Unexpected character in data sequence.
const errorWrongDataSequenceCharacter = 6;

/// Path expression is malformed.
const errorPathWrongSpecified = 7;

/// Block name is malformed.
const errorBlockNameWrongSpecified = 8;

/// Error occurred while invoking a helper function.
const errorCallingHelper = 9;

/// Error occurred while getting an attribute value.
const errorGettingAttribute = 10;

/// Number attribute syntax is invalid.
const errorNumberAttributeMalformed = 11;

/// Unsupported notification type received.
const errorUnsupportedNotify = 12;

/// Path expression is missing where required.
const errorPathNotSpecified = 13;

/// With block syntax is malformed.
const errorWithDataMalformed = 14;

/// If block syntax is malformed.
const errorIfBlockMalformed = 15;

/// If block condition is malformed.
const errorIfBlockConditionMalformed = 16;

/// Block was not properly closed.
const errorUnterminatedBlock = 17;

/// Helper function is not registered.
const errorHelperUnregistered = 18;

/// String attribute syntax is invalid.
const errorStringAttributeMalformed = 19;

/// Unexpected end of template source.
const errorUnexpectedEndOfSource = 20;
