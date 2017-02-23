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

class LineDelimitedTests: XCTestCase {

    func testEmpty() throws {
        let doc = Document(source: "```\n```\n")
        let p = lineDelimitedContent

        let (nodes, cursor) = try parse(p, doc)
        expect(nodes).to(haveCount(1))
        let node = nodes[0]

        expect(node.document) == doc
        expect(node.sourceRange) == "1:1..2:3"
        expect(node.nodeType.name) == "code"
        expect(node.children).to(haveCount(0))

        expect(cursor.atEndOfBlock) == true
    }

    func testSimple() throws {
        let doc = Document(source: "```\nabc\ndef\n```\n")
        let p = lineDelimitedContent

        let (nodes, cursor) = try parse(p, doc)
        expect(nodes).to(haveCount(1))
        let node = nodes[0]

        expect(node.document) == doc
        expect(node.sourceRange) == "1:1..4:3"
        expect(node.nodeType.name) == "code"
        expect(node.children).to(haveCount(2))

        expect(node.children[0].nodeType.name) == "code-text"
        expect(node.children[0].sourceContent) == "abc"

        expect(node.children[1].nodeType.name) == "code-text"
        expect(node.children[1].sourceContent) == "def"

        expect(cursor.atEndOfBlock) == true
    }

    func testReject1() throws {
        let doc = Document(source: "```\nabc\ndef\n\n")
        let p = lineDelimitedContent

        expect { try p.parse(doc.start()) }.to(throwError())
    }

    func testReject2() throws {
        let doc = Document(source: "```\n")
        let p = lineDelimitedContent

        expect(try p.parse(doc.start())).to(throwError())
    }

    func testTitle() throws {
        let doc = Document(source: "```#name x=y: title text\nabc\ndef\n```\n")
        let p = lineDelimitedContent

        let (nodes, tail) = try parse(p, doc)
        expect(nodes).to(haveCount(1))
        let node = nodes[0]

        expect(node.nodeType.name) == "code"
        expect(node.children).to(haveCount(5))

        let title = node.children[0]
        expect(title.nodeType.name) == "gaintext-title"
        expect(title.sourceContent) == "title text"

        let id = node.children[1]
        expect(id.nodeType.name) == "attribute"
        expect(id.children).to(haveCount(2))
        expect(id.children[0].attributes) == [.text("name", "id")]
        expect(id.children[1].attributes) == [.text("value", "name")]

        let attr = node.children[2]
        expect(attr.nodeType.name) == "attribute"
        expect(attr.children).to(haveCount(2))
        expect(attr.children[0].attributes) == [.text("name", "x")]
        expect(attr.children[1].attributes) == [.text("value", "y")]

        expect(node.children[3].nodeType.name) == "code-text"
        expect(node.children[3].sourceContent) == "abc"
        expect(node.children[4].nodeType.name) == "code-text"
        expect(node.children[4].sourceContent) == "def"

        expect(tail.atEndOfBlock) == true
    }

    func testId() throws {
        let doc = Document(source: "``` title text\nabc\ndef\n```\n")
        let p = lineDelimitedContent

        let (nodes, tail) = try parse(p, doc)
        expect(nodes).to(haveCount(1))
        let node = nodes[0]

        expect(node.nodeType.name) == "code"
        expect(node.children).to(haveCount(3))

        let title = node.children[0]
        expect(title.nodeType.name) == "gaintext-title"
        expect(title.sourceContent) == "title text"

        expect(node.children[1].nodeType.name) == "code-text"
        expect(node.children[1].sourceContent) == "abc"
        expect(node.children[2].nodeType.name) == "code-text"
        expect(node.children[2].sourceContent) == "def"

        expect(tail.atEndOfBlock) == true
    }

    func testClass() throws {
        let doc = Document(source: "``` .name:\nabc\ndef\n```\n")
        let p = lineDelimitedContent

        let (nodes, tail) = try parse(p, doc)
        expect(nodes).to(haveCount(1))
        let node = nodes[0]

        expect(node.nodeType.name) == "code"
        expect(node.children).to(haveCount(3))

        let attr = node.children[0]
        expect(attr.nodeType.name) == "attribute"
        expect(attr.children).to(haveCount(2))
        expect(attr.children[0].nodeType.name) == "attribute-key"
        expect(attr.children[0].attributes) == [.text("name", "class")]
        expect(attr.children[1].nodeType.name) == "attribute-value"
        expect(attr.children[1].attributes) == [.text("value", "name")]

        expect(node.children[1].nodeType.name) == "code-text"
        expect(node.children[1].sourceContent) == "abc"
        expect(node.children[2].nodeType.name) == "code-text"
        expect(node.children[2].sourceContent) == "def"

        expect(tail.atEndOfBlock) == true
    }

    func testCombination() throws {
        let doc = Document(source: "```#name x=y: title text\nabc\ndef\n```\n")
        let p = lineDelimitedContent

        let (nodes, tail) = try parse(p, doc)
        expect(nodes).to(haveCount(1))
        let node = nodes[0]

        expect(node.nodeType.name) == "code"
        expect(node.children).to(haveCount(5))

        let title = node.children[0]
        expect(title.nodeType.name) == "gaintext-title"
        expect(title.sourceContent) == "title text"

        let id = node.children[1]
        expect(id.nodeType.name) == "attribute"
        expect(id.children).to(haveCount(2))
        expect(id.children[0].attributes) == [.text("name", "id")]
        expect(id.children[1].attributes) == [.text("value", "name")]

        let attr = node.children[2]
        expect(attr.nodeType.name) == "attribute"
        expect(attr.children).to(haveCount(2))
        expect(attr.children[0].attributes) == [.text("name", "x")]
        expect(attr.children[1].attributes) == [.text("value", "y")]

        expect(node.children[3].nodeType.name) == "code-text"
        expect(node.children[3].sourceContent) == "abc"
        expect(node.children[4].nodeType.name) == "code-text"
        expect(node.children[4].sourceContent) == "def"

        expect(tail.atEndOfBlock) == true
    }

    static var allTests : [(String, (LineDelimitedTests) -> () throws -> Void)] {
        return [
            ("testEmpty", testEmpty),
            ("testSimple", testSimple),
            ("testReject1", testReject1),
            ("testReject2", testReject2),
            ("testId", testId),
            ("testClass", testClass),
            ("testCombination", testCombination),
        ]
    }
}
