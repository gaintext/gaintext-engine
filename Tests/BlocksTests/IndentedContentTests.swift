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
        expect(title.nodeType.name) == "gaintext-title"
        expect(title.sourceContent) == "title"

        expect(cursor.atEndOfBlock) == true
    }

    func testContent1() throws {
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
        expect(title.nodeType.name) == "gaintext-title"
        expect(title.sourceContent) == "title"

        let content = node.children[1]
        expect(content.nodeType.name) == "p"
        expect(content.sourceContent) == "content"

        expect(cursor.atEndOfBlock) == true
    }

    func testContent2() throws {
        let doc = Document(source: "test: title\n\n content\n")
        doc.global.register(block: ElementType("test"))
        let p = elementWithIndentedContent

        let (nodes, cursor) = try parse(p, doc)
        expect(nodes).to(haveCount(1))
        let node = nodes[0]

        expect(node.document) == doc
        expect(node.sourceRange) == "1:1..3:8"
        expect(node.nodeType.name) == "test"
        expect(node.children).to(haveCount(2))

        let title = node.children[0]
        expect(title.nodeType.name) == "gaintext-title"
        expect(title.sourceContent) == "title"

        let content = node.children[1]
        expect(content.nodeType.name) == "p"
        expect(content.sourceContent) == "content"

        expect(cursor.atEndOfBlock) == true
    }

    func testId1() throws {
        let doc = Document(source: "test #name:\n")
        doc.global.register(block: ElementType("test"))
        let p = elementWithIndentedContent

        let (nodes, tail) = try parse(p, doc)
        expect(nodes).to(haveCount(1))
        let node = nodes[0]

        expect(node.nodeType.name) == "test"
        expect(node.children).to(haveCount(1))

        let attr = node.children[0]
        expect(attr.nodeType.name) == "attribute"
        expect(attr.children).to(haveCount(2))
        expect(attr.children[0].nodeType.name) == "attribute-key"
        expect(attr.children[0].attributes["name"]) == "id"
        expect(attr.children[1].nodeType.name) == "attribute-value"
        expect(attr.children[1].attributes["value"]) == "name"

        expect(tail.atEndOfBlock) == true
    }

    func testId2() throws {
        let doc = Document(source: "test: {#name}\n")
        doc.global.register(block: ElementType("test"))
        let p = elementWithIndentedContent

        let (nodes, tail) = try parse(p, doc)
        expect(nodes).to(haveCount(1))
        let node = nodes[0]

        expect(node.nodeType.name) == "test"
        expect(node.children).to(haveCount(1))

        let attr = node.children[0]
        expect(attr.nodeType.name) == "attribute"
        expect(attr.children).to(haveCount(2))
        expect(attr.children[0].nodeType.name) == "attribute-key"
        expect(attr.children[0].attributes["name"]) == "id"
        expect(attr.children[1].nodeType.name) == "attribute-value"
        expect(attr.children[1].attributes["value"]) == "name"

        expect(tail.atEndOfBlock) == true
    }

    func testClass1() throws {
        let doc = Document(source: "test .name:\n")
        doc.global.register(block: ElementType("test"))
        let p = elementWithIndentedContent

        let (nodes, tail) = try parse(p, doc)
        expect(nodes).to(haveCount(1))
        let node = nodes[0]

        expect(node.nodeType.name) == "test"
        expect(node.children).to(haveCount(1))

        let attr = node.children[0]
        expect(attr.nodeType.name) == "attribute"
        expect(attr.children).to(haveCount(2))
        expect(attr.children[0].nodeType.name) == "attribute-key"
        expect(attr.children[0].attributes["name"]) == "class"
        expect(attr.children[1].nodeType.name) == "attribute-value"
        expect(attr.children[1].attributes["value"]) == "name"

        expect(tail.atEndOfBlock) == true
    }

    func testClass2() throws {
        let doc = Document(source: "test: {.name}\n")
        doc.global.register(block: ElementType("test"))
        let p = elementWithIndentedContent

        let (nodes, tail) = try parse(p, doc)
        expect(nodes).to(haveCount(1))
        let node = nodes[0]

        expect(node.nodeType.name) == "test"
        expect(node.children).to(haveCount(1))

        let attr = node.children[0]
        expect(attr.nodeType.name) == "attribute"
        expect(attr.children).to(haveCount(2))
        expect(attr.children[0].nodeType.name) == "attribute-key"
        expect(attr.children[0].attributes["name"]) == "class"
        expect(attr.children[1].nodeType.name) == "attribute-value"
        expect(attr.children[1].attributes["value"]) == "name"

        expect(tail.atEndOfBlock) == true
    }

    func testCombination1() throws {
        let doc = Document(source: "test #name x=y: title text\n  content\n")
        doc.global.register(block: ElementType("test"))
        let p = elementWithIndentedContent

        let (nodes, tail) = try parse(p, doc)
        expect(nodes).to(haveCount(1))
        let node = nodes[0]

        expect(node.nodeType.name) == "test"
        expect(node.children).to(haveCount(4))

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

        let content = node.children[3]
        expect(content.nodeType.name) == "p"
        expect(content.sourceContent) == "content"

        expect(tail.atEndOfBlock) == true
    }

    func testCombination2() throws {
        let doc = Document(source: "test #name: title text {x=y}\n  content\n")
        doc.global.register(block: ElementType("test"))
        let p = elementWithIndentedContent

        let (nodes, tail) = try parse(p, doc)
        expect(nodes).to(haveCount(1))
        let node = nodes[0]

        expect(node.nodeType.name) == "test"
        expect(node.children).to(haveCount(4))

        let title = node.children[0]
        expect(title.nodeType.name) == "gaintext-title"
        expect(title.children).to(haveCount(1))
        expect(title.children[0].nodeType.name) == "text"
        expect(title.children[0].sourceContent) == "title text"

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

        let content = node.children[3]
        expect(content.nodeType.name) == "p"
        expect(content.sourceContent) == "content"

        expect(tail.atEndOfBlock) == true
    }

    func testCombination3() throws {
        let doc = Document(source: "test: title text {#name x=y}\n  content\n")
        doc.global.register(block: ElementType("test"))
        let p = elementWithIndentedContent

        let (nodes, tail) = try parse(p, doc)
        expect(nodes).to(haveCount(1))
        let node = nodes[0]

        expect(node.nodeType.name) == "test"
        expect(node.children).to(haveCount(4))

        let title = node.children[0]
        expect(title.nodeType.name) == "gaintext-title"
        expect(title.children).to(haveCount(1))
        expect(title.children[0].nodeType.name) == "text"
        expect(title.children[0].sourceContent) == "title text"

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

        let content = node.children[3]
        expect(content.nodeType.name) == "p"
        expect(content.sourceContent) == "content"

        expect(tail.atEndOfBlock) == true
    }

    static var allTests : [(String, (IndentedContentTests) -> () throws -> Void)] {
        return [
            ("testSimple", testSimple),
            ("testTitle", testTitle),
            ("testContent1", testContent1),
            ("testContent2", testContent2),
            ("testId1", testId1),
            ("testId2", testId2),
            ("testClass1", testClass1),
            ("testClass2", testClass2),
            ("testCombination1", testCombination1),
            ("testCombination2", testCombination2),
            ("testCombination3", testCombination3),
        ]
    }
}
