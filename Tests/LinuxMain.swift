//
// GainText parser
// Copyright Martin Waitz
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//

import XCTest

@testable import EngineTests
@testable import BlockTests
@testable import MarkupTests
//@testable import ElementsTests
@testable import GainTextTests

XCTMain([

     // EngineTests
     testCase(CachedParserTests.allTests),
     testCase(CharacterParserTests.allTests),
     testCase(CollectUntilParserTests.allTests),
     testCase(CollectWhileParserTests.allTests),
     testCase(CombinatorLazyTests.allTests),
     testCase(CombinatorListTests.allTests),
     testCase(CombinatorLookaheadTests.allTests),
     testCase(CombinatorMapTests.allTests),
     testCase(CombinatorNotTests.allTests),
     testCase(CombinatorOptionalTests.allTests),
     testCase(CursorTests.allTests),
     testCase(DocumentTests.allTests),
     testCase(IndentParserTests.allTests),
     testCase(LiteralCharacterParserTests.allTests),
     testCase(LiteralStringParserTests.allTests),
     testCase(LiteralTests.allTests),
     testCase(LookaheadParserTests.allTests),
     testCase(OperatorAddTests.allTests),
     testCase(OperatorApplyTests.allTests),
     testCase(OperatorComposeFuncTests.allTests),
     testCase(OperatorLeftTests.allTests),
     testCase(OperatorMapParserTests.allTests),
     testCase(OperatorMapTests.allTests),
     testCase(OperatorOrTests.allTests),
     testCase(OperatorRightTests.allTests),

     // BlocksTests
     testCase(DetectSectionStartTests.allTests),
     testCase(IndentedContentTests.allTests),
     testCase(LineDelimitedTests.allTests),
     testCase(ParagraphTests.allTests),
     testCase(TitledContentTests.allTests),

     // MarkupTests
     testCase(EscapedTests.allTests),
     testCase(SpanWithBracketsTests.allTests),
     testCase(SpanWithDelimitersTests.allTests),

     // GainTextTests
     testCase(ExampleTests.allTests)
])
