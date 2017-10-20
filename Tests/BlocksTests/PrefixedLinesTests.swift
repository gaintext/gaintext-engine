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
import Runes

import XCTest
import Nimble


class PrefixedLinesTests: XCTestCase {

    func testSuccess() throws {
        let doc = simpleDocument(
            """
              a
              b
            """)
        let indented = whitespace >>- prefixedLines
        let (lines, cursor) = try parse(indented, doc)
        expect(lines).to(haveCount(2))

        expect(lines[0].start.right) == "1:3"
        expect(lines[1].start.right) == "2:3"

        expect(cursor.atEndOfBlock) == true
    }

    static var allTests : [(String, (PrefixedLinesTests) -> () throws -> Void)] {
        return [
            ("testSuccess", testSuccess),
        ]
    }
}

