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
     testCase(LiteralCharacterParserTests.allTests),
     testCase(LiteralStringParserTests.allTests),
     testCase(CollectWhileParserTests.allTests),
     testCase(CollectUntilParserTests.allTests),
     testCase(CharacterParserTests.allTests),
     testCase(MappedParserTests.allTests),
     testCase(LookaheadParserTests.allTests),
     testCase(LazyParserTests.allTests),
     testCase(SequenceParserTests.allTests),
     testCase(DisjunctiveParserTests.allTests),
     testCase(CachedParserTests.allTests),
     testCase(CursorTests.allTests),
     testCase(DocumentTests.allTests),
     testCase(IndentParserTests.allTests),
     testCase(LiteralParserTests.allTests),
     testCase(NewlineParserTests.allTests),
     testCase(ParagraphParserTests.allTests),

     // BlockTests
     testCase(SectionParserDetectionTests.allTests),
     testCase(SectionParserTests.allTests),
     testCase(LineDelimitedTests.allTests),

     // MarkupTests
     testCase(SpanWithBracketsTests.allTests),
     testCase(SpanWithDelimitersTests.allTests)

     // GainTextTests
     testCase(ExampleTests.allTests)
])
