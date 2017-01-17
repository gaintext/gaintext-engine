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
@testable import Blocks
import GainText

import XCTest
import Nimble

class IndentedContentTests: XCTestCase {

    func testSimple() throws {
        let doc = Document(source: "test:\n")
        doc.global.register(block: ElementType("test"))
        let p = elementWithIndentedContent

        let (nodes, cursor) = try parse(p, doc)
        expect(nodes).to(haveCount(1))
        let node = nodes[0]

        expect(node.document) == doc
        expect(node.sourceRange) == "1:1..1:5"
        expect(node.nodeType.name) == "test"
        expect(node.children).to(haveCount(0))

        expect(cursor.atEndOfBlock) == true

    }

    func testTitle() throws {
        let doc = Document(source: "test: title\n")
        doc.global.register(block: ElementType("test"))
        let p = elementWithIndentedContent

        let (nodes, cursor) = try parse(p, doc)
        expect(nodes).to(haveCount(1))
        let node = nodes[0]

        expect(node.document) == doc
        expect(node.sourceRange) == "1:1..1:11"
        expect(node.nodeType.name) == "test"
        expect(node.children).to(haveCount(1))

        let title = node.children[0]
        expect(title.nodeType.name) == "title"
        expect(title.sourceContent) == "title"

        expect(cursor.atEndOfBlock) == true
    }

    func testContent() throws {
        let doc = Document(source: "test: title\n content\n")
        doc.global.register(block: ElementType("test"))
        let p = elementWithIndentedContent

        let (nodes, cursor) = try parse(p, doc)
        expect(nodes).to(haveCount(1))
        let node = nodes[0]

        expect(node.document) == doc
        expect(node.sourceRange) == "1:1..2:8"
        expect(node.nodeType.name) == "test"
        expect(node.children).to(haveCount(2))

        let title = node.children[0]
        expect(title.nodeType.name) == "title"
        expect(title.sourceContent) == "title"

        let content = node.children[1]
        expect(content.nodeType.name) == "p"
        expect(content.sourceContent) == "content"

        expect(cursor.atEndOfBlock) == true
    }

    static var allTests : [(String, (IndentedContentTests) -> () throws -> Void)] {
        return [
            ("testSimple", testSimple),
            ("testReject1", testTitle),
            ("testReject2", testContent),
        ]
    }
}
