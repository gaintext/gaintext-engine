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

class BlockQuoteTests: XCTestCase {

    func testReject1() throws {
        let doc = Document(source: "")
        let p = quotedBlock

        expect { try p.parse(doc.start()) }.to(throwError())
    }

    func testReject2() throws {
        let doc = Document(source: "\n")
        let p = quotedBlock

        expect { try p.parse(doc.start()) }.to(throwError())
    }

    func testReject3() throws {
        let doc = Document(source: "\n\n")
        let p = quotedBlock

        expect { try p.parse(doc.start()) }.to(throwError())
    }

    func testSingleLine1() throws {
        let doc = Document(source: "> a\n")
        let p = quotedBlock

        let (nodes, cursor) = try parse(p, doc)
        expect(nodes).to(haveCount(1))
        let node = nodes[0]

        expect(node.sourceRange) == "1:1..1:3"
        expect(node.nodeType.name) == "blockquote"
        expect(node.children).to(haveCount(1))

        let quoted = node.children[0]
        expect(quoted.nodeType.name) == "p"
        expect(quoted.sourceContent) == "a"

        expect(cursor.atEndOfBlock) == true
    }

    func testSingleLine2() throws {
        let doc = Document(source: "> a\nb\n")
        let p = quotedBlock

        let (nodes, cursor) = try parse(p, doc)
        expect(nodes).to(haveCount(1))
        let node = nodes[0]

        expect(node.sourceRange) == "1:1..2:0"
        expect(node.nodeType.name) == "blockquote"
        expect(node.children).to(haveCount(1))

        let quoted = node.children[0]
        expect(quoted.nodeType.name) == "p"
        expect(quoted.sourceContent) == "a"

        expect(cursor.position) == node.range.end
    }

    func testMultiLine1() throws {
        let doc = Document(source: "> a\n> b\n")
        let p = quotedBlock

        let (nodes, cursor) = try parse(p, doc)
        expect(nodes).to(haveCount(1))
        let node = nodes[0]

        expect(node.sourceRange) == "1:1..2:3"
        expect(node.nodeType.name) == "blockquote"
        expect(node.children).to(haveCount(1))

        let quoted = node.children[0]
        expect(quoted.nodeType.name) == "p"
        expect(quoted.children).to(haveCount(2))

        expect(cursor.atEndOfBlock) == true
    }

    static var allTests : [(String, (BlockQuoteTests) -> () throws -> Void)] {
        return [
            ("testReject1", testReject1),
            ("testReject2", testReject2),
            ("testReject3", testReject3),
            ("testSingleLine1", testSingleLine1),
            ("testSingleLine2", testSingleLine2),
            ("testMultiLine1", testMultiLine1),
        ]
    }}
