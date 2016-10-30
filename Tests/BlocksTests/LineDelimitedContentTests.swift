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

    func testSimple() throws {
        let doc = Document(source: "```\nabc\ndef\n```\n")
        let p = LineDelimitedContent()

        let (nodes, cursor) = try report(try parse(p, doc))
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
        let p = LineDelimitedContent()

        expect { try p.parse(doc.start()) }.to(throwError())
    }

    func testReject2() throws {
        let doc = Document(source: "```\n")
        let p = LineDelimitedContent()

        expect(try p.parse(doc.start())).to(throwError())
    }

    static var allTests : [(String, (LineDelimitedTests) -> () throws -> Void)] {
        return [
            ("testSimple", testSimple),
            ("testReject1", testReject1),
            ("testReject2", testReject2),
        ]
    }
}
