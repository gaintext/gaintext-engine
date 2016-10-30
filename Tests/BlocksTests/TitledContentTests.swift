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
        let doc = Document(source: "abc\n===\n")
        let section = TitledContent()

        let cursor = section.detectSectionStart(doc.start())
        expect(cursor).toNot(beNil())
    }

    func testSpecificUnderline() throws {
        let doc = Document(source: "abc\n===\n")
        let section = TitledContent()

        let cursor = section.detectSectionStart(doc.start(), underlineChars: "=")
        expect(cursor).toNot(beNil())
    }

    func testWrongUnderline() throws {
        let doc = Document(source: "abc\n===\n")
        let section = TitledContent()

        let cursor = section.detectSectionStart(doc.start(), underlineChars: "-")
        expect(cursor).to(beNil())
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
        let doc = Document(source: "")
        let p = TitledContent()

        expect(try p.parse(doc.start())).to(throwError())
    }

    func testNoHeader() throws {
        let doc = Document(source: "abc\ndef\n\n")
        let p = TitledContent()

        expect(try p.parse(doc.start())).to(throwError())
    }

    func testEmptySection() throws {
        let doc = Document(source: "abc\n===\n\n")
        let p = TitledContent()

        let (nodes, cursor) = try report(try parse(p, doc))
        expect(nodes).to(haveCount(1))
        let node = nodes[0]

        expect(node.document) == doc
        expect(node.sourceRange) == "1:1..3:0"
        expect(node.nodeType.name) == "section"
        expect(node.children).to(haveCount(1))

        let title = node.children[0]
        expect(title.document) == doc
        expect(title.sourceRange) == "1:1..1:3"
        expect(title.nodeType.name) == "title"

        expect(cursor.atEndOfBlock) == true
    }

    func testEmptyElement() throws {
        let doc = Document(source: "test: abc\n===\n\n")
        doc.global.register(block: ElementType("test"))
        let p = TitledContent()

        let (nodes, cursor) = try report(try parse(p, doc))
        expect(nodes).to(haveCount(1))
        let node = nodes[0]

        expect(node.document) == doc
        expect(node.sourceRange) == "1:1..3:0"
        expect(node.nodeType.name) == "test"
        expect(node.children).to(haveCount(1))

        let title = node.children[0]
        expect(title.document) == doc
        expect(title.sourceContent) == "abc"
        expect(title.nodeType.name) == "title"

        expect(cursor.atEndOfBlock) == true
    }

    func testSimpleSection() throws {
        let doc = Document(source: "abc\n===\n\ndef\n")
        let p = TitledContent()

        let (nodes, cursor) = try report(try parse(p, doc))
        expect(nodes).to(haveCount(1))
        let node = nodes[0]

        expect(node.document) == doc
        expect(node.sourceRange) == "1:1..4:3"
        expect(node.nodeType.name) == "section"
        expect(node.children).to(haveCount(2))

        let title = node.children[0]
        expect(title.document) == doc
        expect(title.sourceRange) == "1:1..1:3"
        expect(title.nodeType.name) == "title"

        let para1 = node.children[1]
        expect(para1.document) == doc
        expect(para1.sourceRange) == "4:1..4:3"
        expect(para1.nodeType.name) == "p"
        expect(para1.children).to(haveCount(1))

        let text = para1.children[0]
        expect(text.document) == doc
        expect(text.sourceRange) == "4:1..4:3"
        expect(text.nodeType.name) == "text"
        expect(text.children).to(beEmpty())

        expect(cursor.atEndOfBlock) == true
    }

    func testHierarchical() throws {
        let doc = Document(source: "abc\n===\n\ndef\n---\n\nghi\n===\n")
        let section = TitledContent()

        let (nodes, cursor) = try report(try parse(ListParser(section), doc))
        expect(nodes).to(haveCount(2))

        let node1 = nodes[0]
        expect(node1.nodeType.name) == "section"
        expect(node1.children.count) == 2
        expect(node1.children[0].nodeType.name) == "title"
        expect(node1.children[0].attributes) == [NodeAttribute.text("underline", "=")]
        let node11 = node1.children[1]
        expect(node11.nodeType.name) == "section"
        expect(node11.children.count) == 1
        expect(node11.children[0].nodeType.name) == "title"
        expect(node11.children[0].attributes) == [NodeAttribute.text("underline", "-")]

        let node2 = nodes[1]
        expect(node2.nodeType.name) == "section"
        expect(node2.children.count) == 1
        expect(node2.children[0].nodeType.name) == "title"
        expect(node2.children[0].attributes) == [NodeAttribute.text("underline", "=")]

        expect(cursor.atEndOfBlock) == true
    }

    static var allTests : [(String, (TitledContentTests) -> () throws -> Void)] {
        return [
            ("testEmpty", testEmpty),
            ("testNoHeader", testNoHeader),
            ("testEmptySection", testEmptySection),
            ("testSimpleSection", testSimpleSection),
            ("testHierarchical", testHierarchical),
        ]
    }
}

