/// Notification type constants for state machine communication.
library;

/// Signals that a second open bracket was found ({{).
const notifySecondOpenBracketFound = 1;

/// Signals that a second close bracket was found (}}).
const notifySecondCloseBracketFound = 2;

/// Signals that a helper sequence was detected.
const notifyIsHelperSequence = 3;

/// Signals that a block sequence was detected.
const notifyIsBlockSequence = 4;

/// Signals that a data sequence was detected.
const notifyIsDataSequence = 5;

/// Signals that a block helper sequence was detected.
const notifyIsBlockHelperSequence = 6;

/// Signals that an if block sequence was detected.
const notifyIsIfBlockSequence = 7;

/// Signals that an each block sequence was detected.
const notifyIsEqchBlockSequence = 8;

/// Signals that a with sequence was detected.
const notifyIsWithSequence = 9;

/// Signals a path resolution result.
const notifyPathResult = 10;

/// Signals a name resolution result.
const notifyNameResult = 11;

/// Signals an attribute resolution result.
const notifyAttrResult = 12;

/// Signals a block end result.
const notifyBlockEndResult = 13;

/// Signals a condition evaluation result.
const notifyConditionResult = 14;

/// Signals that a partial sequence was detected.
const notifyIsPartialSequence = 15;

/// Signals that an else clause was found.
const notifyElseFound = 16;

/// Signals that an unescaped data sequence was detected ({{{...}}}).
const notifyIsUnescapedDataSequence = 17;
