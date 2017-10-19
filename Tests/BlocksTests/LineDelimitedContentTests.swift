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
        let doc = simpleDocument(
            """
            ```
            ```
            """)
        let p = lineDelimitedContent

        let (nodes, cursor) = try parse(p, doc)
        expect(nodes).to(haveCount(1))
        let node = nodes[0]

        expect(node.document) == doc
        expect(node.sourceRange) == "1:1..2:3"
        expect(node.nodeType.name) == "code-block"
        expect(node.children).to(haveCount(0))

        expect(cursor.atEndOfBlock) == true
    }

    func testSimple() throws {
        let doc = simpleDocument(
            """
            ```
            abc
            def
            ```
            """)
        let p = lineDelimitedContent

        let (nodes, cursor) = try parse(p, doc)
        expect(nodes).to(haveCount(1))
        let node = nodes[0]

        expect(node.document) == doc
        expect(node.sourceRange) == "1:1..4:3"
        expect(node.nodeType.name) == "code-block"
        expect(node.children).to(haveCount(2))

        expect(node.children[0].nodeType.name) == "line"
        expect(node.children[0].sourceContent) == "abc"

        expect(node.children[1].nodeType.name) == "line"
        expect(node.children[1].sourceContent) == "def"

        expect(cursor.atEndOfBlock) == true
    }

    func testReject1() throws {
        let doc = simpleDocument(
            """
            ```
            abc
            def

            """)
        let p = lineDelimitedContent

        expect { try p.parse(doc.start()) }.to(throwError())
    }

    func testReject2() throws {
        let doc = simpleDocument(
            """
            ```

            """)
        let p = lineDelimitedContent

        expect(try p.parse(doc.start())).to(throwError())
    }

    func testTitle() throws {
        let doc = simpleDocument(
            """
            ```#name x=y: title text
            abc
            def
            ```
            """)
        let p = lineDelimitedContent

        let (nodes, tail) = try parse(p, doc)
        expect(nodes).to(haveCount(1))
        let node = nodes[0]

        expect(node.nodeType.name) == "code-block"
        expect(node.children).to(haveCount(5))

        let title = node.children[0]
        expect(title.nodeType.name) == "gaintext-title"
        expect(title.sourceContent) == "title text"

        let id = node.children[1]
        expect(id.nodeType.name) == "attribute"
        expect(id.children).to(haveCount(2))
        expect(id.children[0].attributes["name"]) == "id"
        expect(id.children[1].attributes["value"]) == "name"

        let attr = node.children[2]
        expect(attr.nodeType.name) == "attribute"
        expect(attr.children).to(haveCount(2))
        expect(attr.children[0].attributes["name"]) == "x"
        expect(attr.children[1].attributes["value"]) == "y"
        expect(node.children[3].nodeType.name) == "line"
        expect(node.children[3].sourceContent) == "abc"
        expect(node.children[3].children[0].nodeType.name) == "text"
        expect(node.children[4].nodeType.name) == "line"
        expect(node.children[4].sourceContent) == "def"
        expect(node.children[4].children[0].nodeType.name) == "text"

        expect(tail.atEndOfBlock) == true
    }

    func testId() throws {
        let doc = simpleDocument(
            """
            ``` title text
            abc
            def
            ```
            """)
        let p = lineDelimitedContent

        let (nodes, tail) = try parse(p, doc)
        expect(nodes).to(haveCount(1))
        let node = nodes[0]

        expect(node.nodeType.name) == "code-block"
        expect(node.children).to(haveCount(3))

        let title = node.children[0]
        expect(title.nodeType.name) == "gaintext-title"
        expect(title.sourceContent) == "title text"

        expect(node.children[1].nodeType.name) == "line"
        expect(node.children[1].sourceContent) == "abc"
        expect(node.children[1].children[0].nodeType.name) == "text"
        expect(node.children[2].nodeType.name) == "line"
        expect(node.children[2].sourceContent) == "def"
        expect(node.children[2].children[0].nodeType.name) == "text"

        expect(tail.atEndOfBlock) == true
    }

    func testClass() throws {
        let doc = simpleDocument(
            """
            ``` .name:
            abc
            def
            ```
            """)
        let p = lineDelimitedContent

        let (nodes, tail) = try parse(p, doc)
        expect(nodes).to(haveCount(1))
        let node = nodes[0]

        expect(node.nodeType.name) == "code-block"
        expect(node.children).to(haveCount(3))

        let attr = node.children[0]
        expect(attr.nodeType.name) == "attribute"
        expect(attr.children).to(haveCount(2))
        expect(attr.children[0].nodeType.name) == "attribute-key"
        expect(attr.children[0].attributes["name"]) == "class"
        expect(attr.children[1].nodeType.name) == "attribute-value"
        expect(attr.children[1].attributes["value"]) == "name"

        expect(node.children[1].nodeType.name) == "line"
        expect(node.children[1].sourceContent) == "abc"
        expect(node.children[2].nodeType.name) == "line"
        expect(node.children[2].sourceContent) == "def"

        expect(tail.atEndOfBlock) == true
    }

    func testCombination() throws {
        let doc = simpleDocument(
            """
            ```#name x=y: title text
            abc
            def
            ```
            """)
        let p = lineDelimitedContent

        let (nodes, tail) = try parse(p, doc)
        expect(nodes).to(haveCount(1))
        let node = nodes[0]

        expect(node.nodeType.name) == "code-block"
        expect(node.children).to(haveCount(5))

        let title = node.children[0]
        expect(title.nodeType.name) == "gaintext-title"
        expect(title.sourceContent) == "title text"

        let id = node.children[1]
        expect(id.nodeType.name) == "attribute"
        expect(id.children).to(haveCount(2))
        expect(id.children[0].attributes["name"]) == "id"
        expect(id.children[1].attributes["value"]) == "name"

        let attr = node.children[2]
        expect(attr.nodeType.name) == "attribute"
        expect(attr.children).to(haveCount(2))
        expect(attr.children[0].attributes["name"]) == "x"
        expect(attr.children[1].attributes["value"]) == "y"

        expect(node.children[3].nodeType.name) == "line"
        expect(node.children[3].sourceContent) == "abc"
        expect(node.children[4].nodeType.name) == "line"
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
