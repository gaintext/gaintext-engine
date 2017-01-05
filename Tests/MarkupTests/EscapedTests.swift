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
@testable import Markup
import GainText

import XCTest
import Nimble


class EscapedTests: XCTestCase {

    func testRawElement() throws {
        let doc = Document(source: "\\[raw:]\n")
        let p = LineParser()

        let (nodes, cursor) = try parse(p, doc)
        expect(nodes).to(haveCount(2))

        expect(nodes[0].nodeType.name) == "raw"
        expect(nodes[0].sourceContent) == "\\["
        expect(nodes[0].children).to(haveCount(1))

        let raw = nodes[0].children[0]
        expect(raw.nodeType.name) == "text"
        expect(raw.sourceContent) == "["

        expect(nodes[1].nodeType.name) == "text"
        expect(nodes[1].sourceContent) == "raw:]"

        expect(cursor.atEndOfBlock) == true
    }

    func testEOL() throws {
        let doc = Document(source: "\\\n")
        let p = LineParser()

        let (nodes, cursor) = try parse(p, doc)
        expect(nodes).to(haveCount(1))

        expect(nodes[0].nodeType.name) == "raw"
        expect(nodes[0].sourceRange) == "1:1..1:1"
        expect(nodes[0].children).to(haveCount(1))

        expect(nodes[0].children[0].nodeType.name) == "error"

        expect(cursor.atEndOfBlock) == true
    }

    static var allTests : [(String, (EscapedTests) -> () throws -> Void)] {
        return [
            ("testRawElement", testRawElement),
            ("testEOL", testEOL),
        ]
    }
}
