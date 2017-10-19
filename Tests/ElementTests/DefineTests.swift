//
// GainText parser
// Copyright Martin Waitz
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//

import Engine
import GainText
import HTMLKit

import XCTest
import Nimble


class DefineTests: XCTestCase {

    func testDefine1() throws {
        let doc = simpleDocument("""
            define: author
            author: me
            """)
        let html = doc.parseHTML()
        expect(html.querySelector("body")?.innerHTML)
            == "<author>me\n</author>"
    }

    func testDefine2() throws {
        let doc = simpleDocument(
            "define: author\n" +
            "  param: city\n" +
            "author: me\n" +
            "  city: Nuremberg\n"
        )
        let html = doc.parseHTML()
        expect(html.querySelector("body")?.innerHTML) == """
            <author>me
            <city>Nuremberg
            </city></author>
            """
    }

    func testDefine3() throws {
        let doc = simpleDocument("""
            define: author
              param: city
            author: me
              city: Nuremberg

            city: other
            """)
        let html = doc.parseHTML()
        expect(html.querySelector("body")?.innerHTML) == """
            <author>me
            <city>Nuremberg
            </city></author><p>city: other
            </p>
            """
    }

    static var allTests : [(String, (DefineTests) -> () throws -> Void)] {
        return [
            ("testDefine1", testDefine1),
            ("testDefine2", testDefine2),
            ("testDefine3", testDefine3),
        ]
    }
}
