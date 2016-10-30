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

class SequenceParserTests: XCTestCase {

    func testSuccess() throws {
        let doc = Document(source: "abcdef")
        let p1 = LiteralParser(token: "abc")
        let p2 = LiteralParser(token: "def")
        let p = SequenceParser(list: [p1, p2])

        let (nodes, cursor) = try parse(p, doc)
        expect(nodes).to(haveCount(2))

        let node1 = nodes[0]
        expect(node1.document) == doc
        expect(node1.sourceRange) == "1:1..1:3"
        expect(node1.nodeType.name) == "token"
        expect(node1.children).to(beEmpty())

        let node2 = nodes[1]
        expect(node2.document) == doc
        expect(node2.sourceRange) == "1:4..1:6"
        expect(node2.nodeType.name) == "token"
        expect(node2.children).to(beEmpty())

        expect(cursor.atEndOfLine).to(beTrue())
    }

    func testFailure1() {
        let doc = Document(source: "abcde")
        let p1 = LiteralParser(token: "abc")
        let p2 = LiteralParser(token: "def")
        let p = SequenceParser(list: [p1, p2])

        expect(try p.parse(doc.start())).to(throwError())
    }

    func testFailure2() {
        let doc = Document(source: "bcdef")
        let p1 = LiteralParser(token: "abc")
        let p2 = LiteralParser(token: "def")
        let p = SequenceParser(list: [p1, p2])

        expect(try p.parse(doc.start())).to(throwError())
    }

    static var allTests : [(String, (SequenceParserTests) -> () throws -> Void)] {
        return [
            ("testSuccess", testSuccess),
            ("testFailure1", testFailure1),
            ("testFailure2", testFailure2),
        ]
    }
}

class DisjunctiveParserTests: XCTestCase {

    func testSuccess1() throws {
        let doc = Document(source: "abc")
        let p1 = LiteralParser(token: "abc")
        let p2 = LiteralParser(token: "def")
        let p = DisjunctiveParser(list: [p1, p2])

        let (nodes, cursor) = try parse(p, doc)
        expect(nodes).to(haveCount(1))
        let node = nodes[0]

        expect(node.document) == doc
        expect(node.sourceRange) == "1:1..1:3"
        expect(node.nodeType.name) == "token"
        expect(node.children).to(beEmpty())

        expect(cursor.atEndOfLine) == true
    }

    func testSuccess2() throws {
        let doc = Document(source: "def")
        let p1 = LiteralParser(token: "abc")
        let p2 = LiteralParser(token: "def")
        let p = DisjunctiveParser(list: [p1, p2])

        let (nodes, cursor) = try parse(p, doc)
        expect(nodes).to(haveCount(1))
        let node = nodes[0]

        expect(node.document) == doc
        expect(node.sourceRange) == "1:1..1:3"
        expect(node.nodeType.name) == "token"
        expect(node.children).to(beEmpty())

        expect(cursor.atEndOfLine) == true
    }

    func testFailure() {
        let doc = Document(source: "ghi")
        let p1 = LiteralParser(token: "abc")
        let p2 = LiteralParser(token: "def")
        let p = DisjunctiveParser(list: [p1, p2])

        expect(try p.parse(doc.start())).to(throwError())
    }

    static var allTests : [(String, (DisjunctiveParserTests) -> () throws -> Void)] {
        return [
            ("testSuccess1", testSuccess1),
            ("testSuccess2", testSuccess2),
            ("testFailure", testFailure),
        ]
    }
}

class CachedParserTests: XCTestCase {

    private class StubParser: NodeParser {
        func parse(_ cursor: Cursor) throws -> ([Node], Cursor) {
            count += 1
            return try LiteralParser(token: "abc").parse(cursor)
        }

        var count: Int = 0
    }

    func testCachedParser() throws {
        let doc = Document(source: "abc")
        let start = doc.start()
        let stub = StubParser()
        let p = CachedParser(stub)

        let (nodes, cursor) = try parse(p, start)
        expect(nodes).to(haveCount(1))
        let node = nodes[0]

        expect(node.document) == doc
        expect(node.sourceRange) == "1:1..1:3"
        expect(cursor.atEndOfLine) == true
        expect(stub.count) == 1

        let (nodes2, cursor2) = try parse(p, start)
        expect(nodes2).to(haveCount(1))
        let node2 = nodes[0]
        expect(node2) == node
        expect(cursor2) == cursor
        expect(stub.count) == 1
    }

    func testRightRecursionSuccess1() throws {
        let doc = Document(source: "abcabcabc")
        let start = doc.start()
        let p = DeferredParser()
        let p1 = CachedParser(LiteralParser(token: "abc"))
        let p2 = SequenceParser(list: [p1, p])
        p.resolve(DisjunctiveParser(list: [p2, p1]))

        let (nodes, cursor) = try parse(p, start)
        expect(nodes).to(haveCount(3))

        let node1 = nodes[0]
        expect(node1.sourceRange) == "1:1..1:3"

        let node2 = nodes[1]
        expect(node2.sourceRange) == "1:4..1:6"

        let node3 = nodes[2]
        expect(node3.sourceRange) == "1:7..1:9"

        expect(cursor.atEndOfLine) == true
    }

    func testRightRecursionSuccess2() throws {
        let doc = Document(source: "abcabcABC")
        let p = DeferredParser()
        let p1 = CachedParser(LiteralParser(token: "abc"))
        let p2 = SequenceParser(list: [p1, p])
        p.resolve(DisjunctiveParser(list: [p2, p1]))

        let (nodes, cursor) = try parse(p, doc)
        expect(nodes).to(haveCount(2))

        let node1 = nodes[0]
        expect(node1.sourceRange) == "1:1..1:3"

        let node2 = nodes[1]
        expect(node2.sourceRange) == "1:4..1:6"

        expect(cursor.position) == node2.range.end
    }

    func testRightRecursionFailure() {
        let doc = Document(source: "abCabc")
        let p = DeferredParser()
        let p1 = CachedParser(LiteralParser(token: "abc"))
        let p2 = SequenceParser(list: [p1, p])
        p.resolve(DisjunctiveParser(list: [p2, p1]))

        expect(try p.parse(doc.start())).to(throwError())
    }

    func testLeftRecursionSuccess1() throws {
        let doc = Document(source: "abcabcabc")
        let p = DeferredParser()
        let p1 = CachedParser(LiteralParser(token: "abc"))
        let p2 = SequenceParser(list: [p1, p])
        p.resolve(DisjunctiveParser(list: [p2, p1]))

        let (nodes, cursor) = try report(try p.parse(doc.start()))
        expect(nodes).to(haveCount(3))

        let node1 = nodes[0]
        expect(node1.sourceRange) == "1:1..1:3"

        let node2 = nodes[1]
        expect(node2.sourceRange) == "1:4..1:6"

        let node3 = nodes[2]
        expect(node3.sourceRange) == "1:7..1:9"

        expect(cursor.atEndOfLine) == true
    }

    static var allTests : [(String, (CachedParserTests) -> () throws -> Void)] {
        return [
            ("testCachedParser", testCachedParser),
            ("testRightRecursionSuccess1", testRightRecursionSuccess1),
            ("testRightRecursionSuccess2", testRightRecursionSuccess2),
            ("testRightRecursionFailure", testRightRecursionFailure),
            ("testLeftRecursionSuccess1", testLeftRecursionSuccess1),
        ]
    }
}
