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


class SpanWithDelimitersTests: XCTestCase {

    func testNoMath1() throws {
        let source = "The costs are $5 and $10.\n"
        let doc = Document(source: source)
        let p = lineParser
        let (nodes, cursor) = try parse(p, doc)
        expect(nodes).to(haveCount(1))
        let node = nodes[0]
        expect(node.sourceRange) == "1:1..1:25"
        expect(node.nodeType.name) == "text"
        expect(node.children).to(beEmpty())

        expect(cursor.atEndOfBlock) == true
    }

    func testNoMath2() throws {
        let source = "The balance is between -$10 and -$5."
        let doc = Document(source: source)
        let p = lineParser
        let (nodes, cursor) = try parse(p, doc)
        expect(nodes).to(haveCount(1))
        expect(cursor.atEndOfBlock) == true
    }

    func testNoMath3() throws {
        let source = "The costs are ~10$."
        let doc = Document(source: source)
        let p = lineParser
        let (nodes, cursor) = try parse(p, doc)
        expect(nodes).to(haveCount(1))
        expect(cursor.atEndOfBlock) == true
    }

    func testMath1() throws {
        let source = "The formula is $E = mc^2$.\n"

        let doc = Document(source: source)
        let p = lineParser
        let (nodes, cursor) = try parse(p, doc)
        expect(nodes).to(haveCount(3))

        let text = nodes[0]
        expect(text.nodeType.name) == "text"
        expect(text.sourceRange) == "1:1..1:15"

        // math: "E = mc^2"
        let math = nodes[1]
        expect(math.nodeType.name) == "math"
        expect(math.sourceRange) == "1:16..1:25"
        expect(math.children).to(haveCount(1))
        expect(math.children[0].nodeType.name) == "text"
        expect(math.children[0].sourceContent) == "E = mc^2"
        expect(math.children[0].sourceRange) == "1:17..1:24"

        let fullstop = nodes[2]
        expect(fullstop.nodeType.name) == "text"
        expect(fullstop.sourceContent) == "."
        expect(fullstop.sourceRange) == "1:26..1:26"

        expect(cursor.atEndOfBlock) == true
    }

    func testNested1() throws {
        let source = "*~**foo**~*"

        let doc = Document(source: source)
        let p = lineParser
        let (nodes, cursor) = try parse(p, doc)
        expect(nodes).to(haveCount(1))

        let em = nodes[0]
        expect(em.nodeType.name) == "em"
        expect(em.children).to(haveCount(1))

        let raw = em.children[0]
        expect(raw.sourceContent) == "~**foo**~"
        expect(raw.nodeType.name) == "raw"
        expect(raw.children).to(haveCount(1))
        expect(raw.children[0].sourceContent) == "**foo**"

        expect(cursor.atEndOfBlock) == true
    }

    #if false // TBD!
    func testNested2() throws {
        let source = "From *~20* to *~30*."

        let doc = Document(source: source)
    let p = lineParser
        let (nodes, cursor) = try parse(p, doc)
        expect(nodes).to(haveCount(5))
        #if false
        let em1 = nodes[1]
        expect(em1.nodeType.name) == "em"
        expect(em1.children).to(haveCount(1))
        expect(em1.children[0].sourceContent) == "~20"

        let em2 = nodes[3]
        expect(em2.nodeType.name) == "em"
        expect(em2.children).to(haveCount(1))
        expect(em2.children[0].sourceContent) == "~30"

        expect(cursor.atEndOfBlock) == true
        #endif
    }
    #endif

    func testNested3() throws {
        let source = "*~20*x*30~*"

        let doc = Document(source: source)
        let p = lineParser
        let (nodes, cursor) = try parse(p, doc)
        expect(nodes).to(haveCount(1))

        let em = nodes[0]
        expect(em.nodeType.name) == "em"
        expect(em.sourceContent) == source
        expect(em.children).to(haveCount(1))

        let raw = em.children[0]
        expect(raw.nodeType.name) == "raw"
        expect(raw.sourceContent) == "~20*x*30~"
        expect(raw.children).to(haveCount(1))

        let text = raw.children[0]
        expect(text.nodeType.name) == "text"
        expect(text.sourceContent) == "20*x*30"

        expect(cursor.atEndOfBlock) == true
    }

    func testNestedRaw1() throws {
        let source = "*~*"

        let doc = Document(source: source)
        let p = lineParser
        let (nodes, cursor) = try parse(p, doc)
        expect(nodes).to(haveCount(1))

        let em = nodes[0]
        expect(em.nodeType.name) == "em"
        expect(em.sourceContent) == source
        expect(em.children).to(haveCount(1))

        let text = em.children[0]
        expect(text.nodeType.name) == "text"
        expect(text.sourceContent) == "~"

        expect(cursor.atEndOfBlock) == true
    }

    #if false // TBD
    func testNestedRaw2() throws {
        let source = "*~*~"

        let doc = Document(source: source)
    let p = lineParser
        let (nodes, cursor) = try parse(p, doc)
        expect(nodes).to(haveCount(2))

        let em = nodes[0]
        expect(em.nodeType.name) == "em"
        expect(em.children).to(haveCount(1))

        let text1 = em.children[0]
        expect(text1.nodeType.name) == "text"
        expect(text1.sourceContent) == "~"

        let text2 = nodes[1]
        expect(text2.nodeType.name) == "text"
        expect(text2.sourceContent) == "~"

        expect(cursor.atEndOfBlock) == true
    }
    #endif

    func testNestedRaw3() throws {
        let source = "*~*~*"

        let doc = Document(source: source)
        let p = lineParser
        let (nodes, cursor) = try parse(p, doc)
        expect(nodes).to(haveCount(1))

        let em = nodes[0]
        expect(em.nodeType.name) == "em"
        expect(em.sourceContent) == source
        expect(em.children).to(haveCount(1))

        let raw = em.children[0]
        expect(raw.nodeType.name) == "raw"
        expect(raw.sourceContent) == "~*~"
        expect(raw.children).to(haveCount(1))

        let text = raw.children[0]
        expect(text.nodeType.name) == "text"
        expect(text.sourceContent) == "*"

        expect(cursor.atEndOfBlock) == true
    }

    func testNestedRaw4() throws {
        let source = "*~*~*~"

        let doc = Document(source: source)
        let p = lineParser
        let (nodes, cursor) = try parse(p, doc)
        expect(nodes).to(haveCount(2))

        let em = nodes[0]
        expect(em.nodeType.name) == "em"
        expect(em.children).to(haveCount(1))

        let raw = em.children[0]
        expect(raw.nodeType.name) == "raw"
        expect(raw.sourceContent) == "~*~"
        expect(raw.children).to(haveCount(1))

        let text = raw.children[0]
        expect(text.nodeType.name) == "text"
        expect(text.sourceContent) == "*"

        let text2 = nodes[1]
        expect(text2.nodeType.name) == "text"
        expect(text2.sourceContent) == "~"

        expect(cursor.atEndOfBlock) == true
    }

    func testRaw1() throws {
        let source = "brackets: ~[~ and ~]~"

        let doc = Document(source: source)
        let p = lineParser
        let (nodes, cursor) = try parse(p, doc)
        expect(nodes).to(haveCount(4))

        expect(nodes[0].nodeType.name) == "text"
        expect(nodes[1].nodeType.name) == "raw"
        expect(nodes[1].sourceContent) == "~[~"
        expect(nodes[1].children[0].sourceContent) == "["
        expect(nodes[2].nodeType.name) == "text"
        expect(nodes[3].nodeType.name) == "raw"
        expect(nodes[3].sourceContent) == "~]~"
        expect(nodes[3].children[0].sourceContent) == "]"

        expect(cursor.atEndOfBlock) == true
    }

    func testRaw2() throws {
        let source = "tilde: [raw:~]"

        let doc = Document(source: source)
        let p = lineParser
        let (nodes, cursor) = try parse(p, doc)
        expect(nodes).to(haveCount(2))

        expect(nodes[0].nodeType.name) == "text"
        expect(nodes[1].nodeType.name) == "raw"
        expect(nodes[1].sourceContent) == "[raw:~]"
        expect(nodes[1].children).to(haveCount(1))

        let tilde = nodes[1].children[0]
        expect(tilde.nodeType.name) == "text"
        expect(tilde.sourceContent) == "~"


        expect(cursor.atEndOfBlock) == true
    }

    static var allTests : [(String, (SpanWithDelimitersTests) -> () throws -> Void)] {
        return [
            ("testNoMath1", testNoMath1),
            ("testNoMath2", testNoMath1),
            ("testNoMath3", testNoMath1),
            ("testMath1", testMath1),
            ("testNested1", testNested1),
//            ("testNested2", testNested2),
            ("testNested3", testNested3),
            ("testNestedRaw1", testNestedRaw1),
//            ("testNestedRaw2", testNestedRaw2),
            ("testNestedRaw3", testNestedRaw3),
            ("testNestedRaw4", testNestedRaw4),
            ("testRaw1", testRaw1),
            ("testRaw2", testRaw2),
        ]
    }
}
