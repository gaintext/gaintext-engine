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
import XCTest
import Nimble


class DocumentTests: XCTestCase {

    func testDocument() {
        let doc = Document(source: "abc")
        expect(doc.root).to(beNil())
        expect(doc.source) == "abc"
        let start = doc.start()
        expect(start.position.index) == doc.source.startIndex
        expect(start.position.right) == "1:1"
    }

    static var allTests : [(String, (DocumentTests) -> () throws -> Void)] {
        return [
            ("testDocument", testDocument),
        ]
    }
}

