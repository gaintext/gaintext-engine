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
        expect(text1.nodeType.name) == "text"

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
        expect(text1.nodeType.name) == "text"

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

        let text1 = node.children[0]
        expect(text1.sourceRange) == "1:1..1:1"
        expect(text1.nodeType.name) == "text"

        expect(cursor.atEndOfBlock) == true
    }

    func testMultiLine2() throws {
        let doc = Document(source: "a\nb\n\nc\n")
//        let section = ListParser(para)
        let p = list(paragraph, separator: skipEmptyLines)

        let (nodes, cursor) = try parse(p, doc)
        expect(nodes).to(haveCount(2))

        let para1 = nodes[0]
        expect(para1.sourceRange) == "1:1..3:0"
        expect(para1.nodeType.name) == "p"
        expect(para1.children).to(haveCount(2))

        let text1 = para1.children[0]
        expect(text1.sourceContent) == "a"
        expect(text1.nodeType.name) == "text"

        let text2 = para1.children[1]
        expect(text2.sourceContent) == "b"
        expect(text2.nodeType.name) == "text"

        let para2 = nodes[1]
        expect(para2.sourceRange) == "4:1..4:1"
        expect(para2.nodeType.name) == "p"
        expect(para2.children).to(haveCount(1))

        let text3 = para2.children[0]
        expect(text3.sourceContent) == "c"
        expect(text3.nodeType.name) == "text"

        expect(cursor.atEndOfBlock) == true
    }

    static var allTests : [(String, (ParagraphTests) -> () throws -> Void)] {
        return [
            ("testReject1", testReject1),
            ("testReject2", testReject2),
            ("testReject3", testReject3),
            ("testSingleLin1", testSingleLine1),
            ("testSingleLine2", testSingleLine2),
            ("testMultiLine1", testMultiLine1),
            ("testMultiLine2", testMultiLine2),
        ]
    }
}
