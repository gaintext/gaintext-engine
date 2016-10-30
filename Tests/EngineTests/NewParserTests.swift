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


class LiteralParserTests: XCTestCase {

    func testSuccess() throws {
        let doc = Document(source: "abc")
        let p = LiteralParser(token: "abc")

        let (nodes, cursor) = try parse(p, doc)
        expect(nodes).to(haveCount(1))
        let node = nodes[0]

        expect(node.document) == doc
        expect(node.sourceRange) == "1:1..1:3"
        expect(node.nodeType.name) == "token"

        expect(cursor.atEndOfLine) == true
    }
    func testFailure1() {
        let doc = Document(source: "")
        let p = LiteralParser(token: "abc")
        expect(try p.parse(doc.start())).to(throwError())
    }
    func testFailure2() {
        let doc = Document(source: "ab")
        let p = LiteralParser(token: "abc")
        expect(try p.parse(doc.start())).to(throwError())
    }
    func testFailure3() {
        let doc = Document(source: "ababc")
        let p = LiteralParser(token: "abc")
        expect(try p.parse(doc.start())).to(throwError())
    }

    static var allTests : [(String, (LiteralParserTests) -> () throws -> Void)] {
        return [
            ("testSuccess", testSuccess),
            ("testFailure1", testFailure1),
            ("testFailure2", testFailure2),
            ("testFailure3", testFailure3),
        ]
    }
}

class NewlineParserTests: XCTestCase {

    func test1() throws {
        let doc = Document(source: "a\nb\nc\n")
        let p = SequenceParser(list: [
            LiteralParser(token: "a"), NewlineParser(),
            LiteralParser(token: "b"), NewlineParser(),
            LiteralParser(token: "c"), NewlineParser(),
        ])

        let (nodes, cursor) = try parse(p, doc)
        expect(nodes).to(haveCount(6))

        let node1 = nodes[0]
        expect(node1.document) == doc
        expect(node1.sourceRange) == "1:1..1:1"
        expect(node1.nodeType.name) == "token"

        let node5 = nodes[4]
        expect(node5.document) == doc
        expect(node5.sourceRange) == "3:1..3:1"
        expect(node5.nodeType.name) == "token"

        expect(cursor.atEndOfBlock) == true
    }

    func test2() throws {
        let doc = Document(source: "\nabc\ndef\n\nghi\n")
        let p = SequenceParser(list: [
            NewlineParser(),
            TextLineParser(),
            TextLineParser(),
            NewlineParser(),
            TextLineParser(),
        ])

        let (nodes, cursor) = try parse(p, doc)
        expect(nodes).to(haveCount(5))

        let node1 = nodes[0]
        expect(node1.document) == doc
        expect(node1.sourceRange) == "1:1..2:0"
        expect(node1.nodeType.name) == "newline"

        let node2 = nodes[1]
        expect(node2.document) == doc
        expect(node2.sourceRange) == "2:1..2:3"
        expect(node2.nodeType.name) == "text"

        expect(cursor.atEndOfBlock) == true
    }

    func testEmpty() {
        let doc = Document(source: "")
        let p = NewlineParser()

        expect(try p.parse(doc.start())).to(throwError())
    }

    static var allTests : [(String, (NewlineParserTests) -> () throws -> Void)] {
        return [
            ("test1", test1),
            ("test2", test2),
            ("testEmpty", testEmpty),
        ]
    }
}
