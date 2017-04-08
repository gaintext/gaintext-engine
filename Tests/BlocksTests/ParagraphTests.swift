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

class ParagraphTests: XCTestCase {

    func testReject1() throws {
        let doc = Document(source: "")
        let p = paragraph

        expect { try p.parse(doc.start()) }.to(throwError())
    }

    func testReject2() throws {
        let doc = Document(source: "\n")
        let p = paragraph

        expect { try p.parse(doc.start()) }.to(throwError())
    }

    func testReject3() throws {
        let doc = Document(source: "\n\n")
        let p = paragraph

        expect { try p.parse(doc.start()) }.to(throwError())
    }

    func testSingleLine1() throws {
        let doc = Document(source: "a\n")
        let p = paragraph

        let (nodes, cursor) = try parse(p, doc)
        expect(nodes).to(haveCount(1))
        let node = nodes[0]

        expect(node.document) == doc
        expect(node.sourceRange) == "1:1..1:1"
        expect(node.nodeType.name) == "p"
        expect(node.children).to(haveCount(1))

        let text1 = node.children[0]
        expect(text1.sourceContent) == "a"
        expect(text1.nodeType.name) == "line"

        expect(cursor.atEndOfBlock) == true
    }

    func testSingleLine2() throws {
        let doc = Document(source: "a\n\n")
        let p = paragraph

        let (nodes, cursor) = try parse(p, doc)
        expect(nodes).to(haveCount(1))
        let node = nodes[0]

        expect(node.document) == doc
        expect(node.sourceRange) == "1:1..2:0"
        expect(node.nodeType.name) == "p"
        expect(node.children).to(haveCount(1))

        let text1 = node.children[0]
        expect(text1.sourceContent) == "a"
        expect(text1.nodeType.name) == "line"

        expect(cursor.atEndOfBlock) == true
    }

    func testMultiLine1() throws {
        let doc = Document(source: "a\nb\nc\n")
        let p = paragraph

        let (nodes, cursor) = try parse(p, doc)
        expect(nodes).to(haveCount(1))
        let node = nodes[0]

        expect(node.sourceRange) == "1:1..3:1"
        expect(node.nodeType.name) == "p"
        expect(node.children).to(haveCount(3))

        expect(node.children[0].nodeType.name) == "line"
        expect(node.children[0].sourceRange) == "1:1..1:1"
        expect(node.children[1].sourceRange) == "2:1..2:1"
        expect(node.children[2].sourceRange) == "3:1..3:1"

        expect(cursor.atEndOfBlock) == true
    }

    func testMultiLine2() throws {
        let doc = Document(source: "a\nb\n\nc\n")
        let p = list(paragraph, separator: skipEmptyLines)

        let (nodes, cursor) = try parse(p, doc)
        expect(nodes).to(haveCount(2))

        let para1 = nodes[0]
        expect(para1.sourceRange) == "1:1..3:0"
        expect(para1.nodeType.name) == "p"
        expect(para1.children).to(haveCount(2))

        let text1 = para1.children[0]
        expect(text1.sourceContent) == "a"
        expect(text1.nodeType.name) == "line"

        let text2 = para1.children[1]
        expect(text2.sourceContent) == "b"
        expect(text2.nodeType.name) == "line"

        let para2 = nodes[1]
        expect(para2.sourceRange) == "4:1..4:1"
        expect(para2.nodeType.name) == "p"
        expect(para2.children).to(haveCount(1))

        let text3 = para2.children[0]
        expect(text3.sourceContent) == "c"
        expect(text3.nodeType.name) == "line"

        expect(cursor.atEndOfBlock) == true
    }

    func testWhitespaceSeparated1() throws {
        let doc = Document(source: "a\nb\n   c\nd\n")
        let p = list(paragraph, separator: skipEmptyLines)

        let (nodes, cursor) = try parse(p, doc)
        expect(nodes).to(haveCount(2))

        let para1 = nodes[0]
        expect(para1.sourceRange) == "1:1..3:0"
        expect(para1.nodeType.name) == "p"
        expect(para1.children).to(haveCount(2))

        let para2 = nodes[1]
        expect(para2.sourceRange) == "3:1..4:1"
        expect(para2.nodeType.name) == "p"
        expect(para2.children).to(haveCount(2))

        expect(cursor.atEndOfBlock) == true
    }

    func testWhitespaceSeparated2() throws {
        let doc = Document(source: "a\nb\n - c\n")

        let nodes = doc.parse()
        expect(nodes).to(haveCount(2))

        let para1 = nodes[0]
        expect(para1.sourceRange) == "1:1..3:0"
        expect(para1.nodeType.name) == "p"
        expect(para1.children).to(haveCount(2))

        let ul = nodes[1]
        expect(ul.sourceRange) == "3:1..3:4"
        expect(ul.nodeType.name) == "ul"
        expect(ul.children).to(haveCount(1))
    }

    func testListSeparated1() throws {
        let doc = Document(source: "a\nb\n- c\n")

        let nodes = doc.parse()
        expect(nodes).to(haveCount(2))

        let para1 = nodes[0]
        expect(para1.sourceRange) == "1:1..3:0"
        expect(para1.nodeType.name) == "p"
        expect(para1.children).to(haveCount(2))

        let ul = nodes[1]
        expect(ul.sourceRange) == "3:1..3:3"
        expect(ul.nodeType.name) == "ul"
        expect(ul.children).to(haveCount(1))
    }

    func testListSeparated2() throws {
        let doc = Document(source: "a\nb\n* c\n")

        let nodes = doc.parse()
        expect(nodes).to(haveCount(2))

        let para1 = nodes[0]
        expect(para1.sourceRange) == "1:1..3:0"
        expect(para1.nodeType.name) == "p"
        expect(para1.children).to(haveCount(2))

        let ul = nodes[1]
        expect(ul.sourceRange) == "3:1..3:3"
        expect(ul.nodeType.name) == "ul"
        expect(ul.children).to(haveCount(1))
    }

    static var allTests : [(String, (ParagraphTests) -> () throws -> Void)] {
        return [
            ("testReject1", testReject1),
            ("testReject2", testReject2),
            ("testReject3", testReject3),
            ("testSingleLine1", testSingleLine1),
            ("testSingleLine2", testSingleLine2),
            ("testMultiLine1", testMultiLine1),
            ("testMultiLine2", testMultiLine2),
            ("testWhitespaceSeparated1", testWhitespaceSeparated1),
            ("testWhitespaceSeparated2", testWhitespaceSeparated2),
            ("testListSeparated1", testListSeparated1),
            ("testListSeparated2", testListSeparated2),
        ]
    }
}
