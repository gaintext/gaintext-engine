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


class EntityTests: XCTestCase {

    func testNoAmp() throws {
        let doc = simpleDocument("amp;")
        let p = htmlEntity

        expect {try p.parse(doc.start())}.to(throwError())
    }

    func testNotComplete() throws {
        let doc = simpleDocument("&amp")
        let p = htmlEntity

        expect {try p.parse(doc.start())}.to(throwError())
    }

    func testWhitespace1() throws {
        let doc = simpleDocument("& amp;")
        let p = htmlEntity

        expect {try p.parse(doc.start())}.to(throwError())
    }

    func testWhitespace2() throws {
        let doc = simpleDocument("&am p;")
        let p = htmlEntity

        expect {try p.parse(doc.start())}.to(throwError())
    }

    func testWhitespace3() throws {
        let doc = simpleDocument("&amp ;")
        let p = htmlEntity

        expect {try p.parse(doc.start())}.to(throwError())
    }

    func testPara() throws {
        let doc = simpleDocument("&para;")
        let p = htmlEntity

        let (nodes, cursor) = try parse(p, doc)
        expect(nodes).to(haveCount(1))

        expect(nodes[0].nodeType.name) == "html"
        expect(nodes[0].sourceContent) == "&para;"
        expect(nodes[0].children).to(haveCount(0))

        expect(cursor.atEndOfLine) == true
    }

    func testDecimal() throws {
        let doc = simpleDocument("&#182;")
        let p = htmlEntity

        let (nodes, cursor) = try parse(p, doc)
        expect(nodes).to(haveCount(1))

        expect(nodes[0].nodeType.name) == "html"
        expect(nodes[0].sourceContent) == "&#182;"
        expect(nodes[0].children).to(haveCount(0))

        expect(cursor.atEndOfLine) == true
    }

    func testHexadecimal() throws {
        let doc = simpleDocument("&#x00b6;")
        let p = htmlEntity

        let (nodes, cursor) = try parse(p, doc)
        expect(nodes).to(haveCount(1))

        expect(nodes[0].nodeType.name) == "html"
        expect(nodes[0].sourceContent) == "&#x00b6;"
        expect(nodes[0].children).to(haveCount(0))

        expect(cursor.atEndOfLine) == true
    }

    static var allTests : [(String, (EntityTests) -> () throws -> Void)] {
        return [
            ("testNoAmp", testNoAmp),
            ("testNotComplete", testNotComplete),
            ("testWhitespace1", testWhitespace1),
            ("testWhitespace2", testWhitespace2),
            ("testPara", testPara),
            ("testDecimal", testDecimal),
            ("testHexadecimal", testHexadecimal),
        ]
    }
}
