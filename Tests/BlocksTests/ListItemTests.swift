
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

class ListItemTests: XCTestCase {

    func testEmpty1() throws {
        let doc = simpleDocument("")
        expect {try listItem.parse(doc.start())}.to(throwError())
    }

    func testEmpty2() throws {
        let doc = simpleDocument("\n")
        expect {try listItem.parse(doc.start())}.to(throwError())
    }

    func testNoWhitespace() throws {
        let doc = simpleDocument("-abc\n")
        expect {try listItem.parse(doc.start())}.to(throwError())
    }

    func testSimple() throws {
        let doc = simpleDocument("- item1\n")

        let (nodes, cursor) = try parse(listItem, doc)
        expect(nodes).to(haveCount(1))
        let node = nodes[0]

        expect(node.sourceRange) == "1:1..1:7"
        expect(node.nodeType.name) == "li"
        expect(node.children).to(haveCount(1))

        let p = node.children[0]
        expect(p.nodeType.name) == "p"
        expect(p.children).to(haveCount(1))
        expect(p.children[0].nodeType.name) == "line"
        expect(p.children[0].sourceContent) == "item1"

        expect(cursor.atEndOfBlock) == true
    }

    func testMultiline1() throws {
        let doc = simpleDocument(
            """
            - line one
              line two
            """)

        let (nodes, cursor) = try parse(listItem, doc)
        expect(nodes).to(haveCount(1))
        let node = nodes[0]

        expect(node.sourceRange) == "1:1..2:10"
        expect(node.nodeType.name) == "li"
        expect(node.children).to(haveCount(1))

        let p = node.children[0]
        expect(p.nodeType.name) == "p"
        expect(p.children).to(haveCount(2))
        expect(p.children[0].nodeType.name) == "line"
        expect(p.children[0].sourceContent) == "line one"
        expect(p.children[1].nodeType.name) == "line"
        expect(p.children[1].sourceContent) == "line two"

        expect(cursor.atEndOfBlock) == true
    }

    func testSimpleList1() throws {
        let doc = simpleDocument(
            """
            - item1
            - item2
            """)

        let (nodes, cursor) = try parse(listParser, doc)
        expect(nodes).to(haveCount(1))

        expect(nodes[0].sourceRange) == "1:1..2:7"
        expect(nodes[0].nodeType.name) == "ul"
        expect(nodes[0].children).to(haveCount(2))

        let li1 = nodes[0].children[0]
        expect(li1.sourceRange) == "1:1..2:0"
        expect(li1.nodeType.name) == "li"
        expect(li1.children).to(haveCount(1))
        expect(li1.children[0].sourceContent) == "item1"

        let li2 = nodes[0].children[1]
        expect(li2.sourceRange) == "2:1..2:7"
        expect(li2.nodeType.name) == "li"
        expect(li2.children).to(haveCount(1))
        expect(li2.children[0].sourceContent) == "item2"

        expect(cursor.atEndOfBlock) == true
    }

    func testSimpleIndentedList1() throws {
        let doc = simpleDocument(
            """
             - item1
             - item2
            """)

        let (nodes, cursor) = try parse(listParser, doc)
        expect(nodes).to(haveCount(1))

        expect(nodes[0].sourceRange) == "1:1..2:8"
        expect(nodes[0].nodeType.name) == "ul"
        expect(nodes[0].children).to(haveCount(2))

        let li1 = nodes[0].children[0]
        expect(li1.sourceRange) == "1:2..2:1"
        expect(li1.nodeType.name) == "li"
        expect(li1.children).to(haveCount(1))
        expect(li1.children[0].sourceContent) == "item1"

        let li2 = nodes[0].children[1]
        expect(li2.sourceRange) == "2:2..2:8"
        expect(li2.nodeType.name) == "li"
        expect(li2.children).to(haveCount(1))
        expect(li2.children[0].sourceContent) == "item2"

        expect(cursor.atEndOfBlock) == true
    }

    func testNestedList1() throws {
        let doc = simpleDocument(
            """
            - item1
              - item 1a
              - item 1b
            - item2

            """)

        let (nodes, cursor) = try parse(listParser, doc)
        expect(nodes).to(haveCount(1))

        expect(nodes[0].sourceRange) == "1:1..4:7"
        expect(nodes[0].nodeType.name) == "ul"
        expect(nodes[0].children).to(haveCount(2))

        let li1 = nodes[0].children[0]
        expect(li1.sourceRange) == "1:1..4:0"
        expect(li1.nodeType.name) == "li"
        expect(li1.children).to(haveCount(2))
        expect(li1.children[0].nodeType.name) == "p"
        expect(li1.children[0].children).to(haveCount(1))
        expect(li1.children[1].nodeType.name) == "ul"

        let li2 = nodes[0].children[1]
        expect(li2.sourceRange) == "4:1..4:7"
        expect(li2.nodeType.name) == "li"
        expect(li2.children).to(haveCount(1))
        expect(li2.children[0].sourceContent) == "item2"

        expect(cursor.atEndOfBlock) == true
    }

    static var allTests: [(String, (ListItemTests) -> () throws -> Void)] {
        return [
            ("testEmpty1", testEmpty1),
            ("testEmpty2", testEmpty2),
            ("testNoWhitespace", testNoWhitespace),
            ("testSimple", testSimple),
            ("testMultiline1", testMultiline1),
            ("testSimpleList1", testSimpleList1),
            ("testSimpleIndentedList1", testSimpleIndentedList1),
            ("testNestedList1", testNestedList1),
        ]
    }
}
