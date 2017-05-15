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
        let doc = simpleDocument(
            "define: author\n" +
            "author: me\n"
            )
        let html = doc.parseHTML()
        expect(html.querySelector("body")?.innerHTML)
            == "<author>me\n</author>"
    }


    static var allTests : [(String, (DefineTests) -> () throws -> Void)] {
        return [
            ("testDefine1", testDefine1),
        ]
    }
}
