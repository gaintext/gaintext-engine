import XCTest
@testable import EngineTests
@testable import BlockTests
@testable import MarkupTests
//@testable import ElementsTests

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
])
