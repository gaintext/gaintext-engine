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

class DetectSectionStartTests: XCTestCase {

    func testSuccess() throws {
        let doc = simpleDocument("abc\n===\n")
        let p = detectSectionStart()

        let _ = try parse(p, doc)
    }

    func testSpecificUnderline() throws {
        let doc = simpleDocument("abc\n===\n")
        let p = detectSectionStart(underlineChars: "=")

        let _ = try parse(p, doc)
    }

    func testWrongUnderline() throws {
        let doc = simpleDocument("abc\n===\n")
        let p = detectSectionStart(underlineChars: "-")

        expect(try p.parse(doc.start())).to(throwError())
    }

    static var allTests : [(String, (DetectSectionStartTests) -> () throws -> Void)] {
        return [
            ("testSuccess", testSuccess),
            ("testSpecificUnderline", testSpecificUnderline),
            ("testWrongUnderline", testWrongUnderline),
        ]
    }
}

class TitledContentTests: XCTestCase {

    func testEmpty() throws {
        let doc = simpleDocument("")
        let p = titledContent

        expect(try p.parse(doc.start())).to(throwError())
    }

    func testNoHeader() throws {
        let doc = simpleDocument("abc\ndef\n\n")
        let p = titledContent

        expect(try p.parse(doc.start())).to(throwError())
    }

    func testEmptySection0() throws {
        let doc = simpleDocument(
            """
            abc
            ===
            """)
        let p = titledContent

        let (nodes, cursor) = try parse(p, doc)
        expect(nodes).to(haveCount(1))
        let node = nodes[0]

        expect(node.document) == doc
        expect(node.sourceRange) == "1:1..2:3"
        expect(node.nodeType.name) == "section"
        expect(node.children).to(haveCount(1))

        let title = node.children[0]
        expect(title.document) == doc
        expect(title.sourceRange) == "1:1..1:3"
        expect(title.nodeType.name) == "gaintext-title"

        expect(cursor.atEndOfBlock) == true
    }

    func testEmptySection1() throws {
        let doc = simpleDocument(
            """
            abc
            ===

            """)
        let p = titledContent

        let (nodes, cursor) = try parse(p, doc)
        expect(nodes).to(haveCount(1))
        let node = nodes[0]

        expect(node.document) == doc
        expect(node.sourceRange) == "1:1..2:3"
        expect(node.nodeType.name) == "section"
        expect(node.children).to(haveCount(1))

        let title = node.children[0]
        expect(title.document) == doc
        expect(title.sourceRange) == "1:1..1:3"
        expect(title.nodeType.name) == "gaintext-title"

        expect(cursor.atEndOfBlock) == true
    }

    func testEmptySection2() throws {
        let doc = simpleDocument("""
            abc
            ===


            """)
        let p = titledContent

        let (nodes, cursor) = try parse(p, doc)
        expect(nodes).to(haveCount(1))
        let node = nodes[0]

        expect(node.document) == doc
        expect(node.sourceRange) == "1:1..3:0"
        expect(node.nodeType.name) == "section"
        expect(node.children).to(haveCount(1))

        let title = node.children[0]
        expect(title.document) == doc
        expect(title.sourceRange) == "1:1..1:3"
        expect(title.nodeType.name) == "gaintext-title"

        expect(cursor.atEndOfBlock) == true
    }

    func testDashedLine() throws {
        let doc = simpleDocument(
            """
            abcde
            = = =
            """)
        let p = titledContent

        let (nodes, cursor) = try parse(p, doc)
        expect(nodes).to(haveCount(1))
        expect(nodes[0].nodeType.name) == "section"

        expect(cursor.atEndOfBlock) == true
    }

    func testEmptyElement() throws {
        let doc = simpleDocument(
            """
            test: abc
            ===


            """)
        doc.global.register(block: ElementType("test"))
        let p = titledContent

        let (nodes, cursor) = try parse(p, doc)
        expect(nodes).to(haveCount(1))
        let node = nodes[0]

        expect(node.document) == doc
        expect(node.sourceRange) == "1:1..3:0"
        expect(node.nodeType.name) == "test"
        expect(node.children).to(haveCount(1))

        let title = node.children[0]
        expect(title.document) == doc
        expect(title.sourceContent) == "abc"
        expect(title.nodeType.name) == "gaintext-title"

        expect(cursor.atEndOfBlock) == true
    }

    func testSimpleSection() throws {
        let doc = simpleDocument("""
            abc
            ===

            def
            """)
        let p = titledContent

        let (nodes, cursor) = try parse(p, doc)
        expect(nodes).to(haveCount(1))
        let node = nodes[0]

        expect(node.document) == doc
        expect(node.sourceRange) == "1:1..4:3"
        expect(node.nodeType.name) == "section"
        expect(node.children).to(haveCount(2))

        let title = node.children[0]
        expect(title.document) == doc
        expect(title.sourceRange) == "1:1..1:3"
        expect(title.nodeType.name) == "gaintext-title"

        let para1 = node.children[1]
        expect(para1.document) == doc
        expect(para1.sourceRange) == "4:1..4:3"
        expect(para1.nodeType.name) == "p"
        expect(para1.children).to(haveCount(1))

        let line1 = para1.children[0]
        expect(line1.document) == doc
        expect(line1.sourceRange) == "4:1..4:3"
        expect(line1.nodeType.name) == "line"
        expect(line1.children).to(haveCount(1))
        expect(line1.children[0].nodeType.name) == "text"
        expect(line1.children[0].sourceRange) == "4:1..4:3"

        expect(cursor.atEndOfBlock) == true
    }

    func testBiggerSection() throws {
        let doc = simpleDocument(
            """
            abc
            ===

            def

            ghi
            jkl
            """)
        let p = titledContent

        let (nodes, cursor) = try parse(p, doc)
        expect(nodes).to(haveCount(1))
        let node = nodes[0]

        expect(node.sourceRange) == "1:1..7:3"
        expect(node.nodeType.name) == "section"
        expect(node.children).to(haveCount(3))

        let title = node.children[0]
        expect(title.sourceRange) == "1:1..1:3"
        expect(title.nodeType.name) == "gaintext-title"

        let para1 = node.children[1]
        expect(para1.sourceRange) == "4:1..5:0"
        expect(para1.nodeType.name) == "p"
        expect(para1.children).to(haveCount(1))

        let para2 = node.children[2]
        expect(para2.sourceRange) == "6:1..7:3"
        expect(para2.nodeType.name) == "p"
        expect(para2.children).to(haveCount(2))

        expect(cursor.atEndOfBlock) == true
    }

    func testHierarchical() throws {
        let doc = simpleDocument(
            """
            abc
            ===

            def
            ---

            ghi
            ===
            """)
        let p = list(titledContent, separator: skipEmptyLines)

        let (nodes, cursor) = try parse(p, doc)
        expect(nodes).to(haveCount(2))

        let node1 = nodes[0]
        expect(node1.nodeType.name) == "section"
        expect(node1.attributes) == ["underline": "="]
        expect(node1.children.count) == 2
        expect(node1.children[0].nodeType.name) == "gaintext-title"
        let node11 = node1.children[1]
        expect(node11.nodeType.name) == "section"
        expect(node11.attributes) == ["underline": "-"]
        expect(node11.children.count) == 1
        expect(node11.children[0].nodeType.name) == "gaintext-title"

        let node2 = nodes[1]
        expect(node2.nodeType.name) == "section"
        expect(node2.attributes) == ["underline": "="]
        expect(node2.children.count) == 1
        expect(node2.children[0].nodeType.name) == "gaintext-title"

        expect(cursor.atEndOfBlock) == true
    }

    func testId() throws {
        let doc = simpleDocument(
            """
            section #name: abc
            ===
            """)
        let p = titledContent

        let (nodes, tail) = try parse(p, doc)
        expect(nodes).to(haveCount(1))
        let node = nodes[0]

        expect(node.nodeType.name) == "section"
        expect(node.children).to(haveCount(2))

        let title = node.children[0]
        expect(title.nodeType.name) == "gaintext-title"
        expect(title.sourceContent) == "abc"

        let attr = node.children[1]
        expect(attr.nodeType.name) == "attribute"
        expect(attr.children).to(haveCount(2))
        expect(attr.children[0].nodeType.name) == "attribute-key"
        expect(attr.children[0].attributes) == ["name": "id"]
        expect(attr.children[1].nodeType.name) == "attribute-value"
        expect(attr.children[1].attributes) == ["value": "name"]

        expect(tail.atEndOfBlock) == true
    }

    func testClass() throws {
        let doc = simpleDocument(
            """
            section .name: abc
            ===
            """)
        let p = titledContent

        let (nodes, tail) = try parse(p, doc)
        expect(nodes).to(haveCount(1))
        let node = nodes[0]

        expect(node.nodeType.name) == "section"
        expect(node.children).to(haveCount(2))

        let title = node.children[0]
        expect(title.nodeType.name) == "gaintext-title"
        expect(title.sourceContent) == "abc"

        let attr = node.children[1]
        expect(attr.nodeType.name) == "attribute"
        expect(attr.children).to(haveCount(2))
        expect(attr.children[0].nodeType.name) == "attribute-key"
        expect(attr.children[0].attributes) == ["name": "class"]
        expect(attr.children[1].nodeType.name) == "attribute-value"
        expect(attr.children[1].attributes) == ["value": "name"]

        expect(tail.atEndOfBlock) == true
    }

    func testCombination() throws {
        let doc = simpleDocument(
            """
            section #name x=y: title text
            ===

            content
            """)
        let p = titledContent

        let (nodes, tail) = try parse(p, doc)
        expect(nodes).to(haveCount(1))
        let node = nodes[0]

        expect(node.nodeType.name) == "section"
        expect(node.children).to(haveCount(4))

        let title = node.children[0]
        expect(title.nodeType.name) == "gaintext-title"
        expect(title.sourceContent) == "title text"

        let id = node.children[1]
        expect(id.nodeType.name) == "attribute"
        expect(id.children).to(haveCount(2))
        expect(id.children[0].attributes) == ["name": "id"]
        expect(id.children[1].attributes) == ["value": "name"]

        let attr = node.children[2]
        expect(attr.nodeType.name) == "attribute"
        expect(attr.children).to(haveCount(2))
        expect(attr.children[0].attributes) == ["name": "x"]
        expect(attr.children[1].attributes) == ["value": "y"]

        let content = node.children[3]
        expect(content.nodeType.name) == "p"
        expect(content.sourceContent) == "content"

        expect(tail.atEndOfBlock) == true
    }

    static var allTests : [(String, (TitledContentTests) -> () throws -> Void)] {
        return [
            ("testEmpty", testEmpty),
            ("testNoHeader", testNoHeader),
            ("testEmptySection1", testEmptySection1),
            ("testEmptySection2", testEmptySection2),
            ("testEmptyElement", testEmptyElement),
            ("testSimpleSection", testSimpleSection),
            ("testHierarchical", testHierarchical),
            ("testId", testId),
            ("testClass", testClass),
            ("testCombination", testCombination),
        ]
    }
}

