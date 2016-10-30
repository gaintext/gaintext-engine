//
// GainText parser
// Copyright Martin Waitz
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//

@testable import Engine
@testable import Markup
import GainText

import XCTest
import Nimble


class SpanWithBracketsTests: XCTestCase {

    func testNoBracket() throws {
        let doc = Document(source: "no[]")
        let p = SpanWithBrackets()
        expect(try p.parse(doc.start())).to(throwError())
    }

    func testEmptyBracket() throws {
        let doc = Document(source: "[]")
        let p = SpanWithBrackets()
        expect(try p.parse(doc.start())).to(throwError())
    }

    func testNoClosingBracket() throws {
        let doc = Document(source: "[raw:")
        let p = SpanWithBrackets()
        expect(try p.parse(doc.start())).to(throwError())
    }

    func testRawElement1() throws {
        let doc = Document(source: "[test:text]stuff")
        doc.global.markupRegistry.register(ElementType("test"))
        let p = SpanWithBrackets()

        let (nodes, cursor) = try parse(p, doc)
        expect(nodes).to(haveCount(1))
        let node = nodes[0]

        expect(node.document) == doc
        expect(node.sourceRange) == "1:1..1:11"
        expect(node.nodeType.name) == "test"
        expect(node.children).to(haveCount(1))

        let body = node.children[0]
        expect(body.sourceRange) == "1:7..1:10"
        expect(body.nodeType.name) == "text"

        expect(cursor.position) == node.range.end
    }

    func testRawElement2() throws {
        let doc = Document(source: "[test: text] stuff")
        doc.global.markupRegistry.register(ElementType("test"))
        let p = SpanWithBrackets()

        let (nodes, cursor) = try parse(p, doc)
        expect(nodes).to(haveCount(1))
        let node = nodes[0]

        expect(node.document) == doc
        expect(node.sourceRange) == "1:1..1:12"
        expect(node.nodeType.name) == "test"
        expect(node.children).to(haveCount(1))

        let body = node.children[0]
        expect(body.sourceRange) == "1:8..1:11"
        expect(body.nodeType.name) == "text"

        expect(cursor.position) == node.range.end
    }

    static var allTests : [(String, (SpanWithBracketsTests) -> () throws -> Void)] {
        return [
            ("testNoBracket", testNoBracket),
            ("testEmptyBracket", testEmptyBracket),
            ("testNoClosingBracket", testNoClosingBracket),
            ("testRawElement1", testRawElement1),
            ("testRawElement2", testRawElement2),
        ]
    }
}
