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
import GainText

import XCTest
import Nimble


class CursorTests: XCTestCase {

    func testCursor() throws {
        let doc = simpleDocument("abc\ndef\n")
        var cursor = doc.start()
        expect(cursor.atEndOfLine) == false
        expect(cursor.atEndOfBlock) == false

        let pos2 = cursor.position.next()
        try report(try cursor.advance(by: 1)) // "b"
        expect(cursor.position) == pos2
        expect(cursor.position.right) == "1:2"
        expect(cursor.atEndOfLine) == false
        expect(cursor.atEndOfBlock) == false
        try report(try cursor.advance(by: 2)) // to linefeed
        expect(cursor.position) != pos2
        expect(cursor.position.right) == "1:4"
        expect(cursor.atEndOfLine) == true
        expect(cursor.atEndOfBlock) == false
        expect(try cursor.advance(by: 1)).to(throwError()) // end of line

        try report(try cursor.advanceLine())
        expect(cursor.position.right) == "2:1"
        expect(cursor.atEndOfLine) == false
        expect(cursor.atEndOfBlock) == false

        try report(try cursor.advanceLine())
        expect(cursor.atEndOfBlock) == true
    }

    static var allTests : [(String, (CursorTests) -> () throws -> Void)] {
        return [
            ("testCursor", testCursor),
        ]
    }
}
