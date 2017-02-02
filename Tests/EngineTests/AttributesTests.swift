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
import Runes

import XCTest
import Nimble

class AttributeTests: XCTestCase {

    func testId() throws {
        let doc = Document(source: "#id: stop")
        let p = attributesParser
        let endMarker = literal(":") *> pure(())

        let (nodes, cursor) = try parse(p, doc, until: endMarker)
        expect(nodes).to(haveCount(1))

        let node = nodes[0]
        expect(node.document) == doc
        expect(node.sourceRange) == "1:1..1:3"
        expect(node.nodeType.name) == "attribute"
        expect(node.children).to(haveCount(2))
        expect(node.children[0].nodeType.name) == "attribute-key"
        expect(node.children[0].attributes) == [.text("name", "id")]
        expect(node.children[1].nodeType.name) == "attribute-value"
        expect(node.children[1].attributes) == [.text("value", "id")]

        expect(cursor.position.left) == "1:4"
    }

    func testClass() throws {
        let doc = Document(source: ".class: stop")
        let p = attributesParser
        let endMarker = literal(":") *> pure(())

        let (nodes, cursor) = try parse(p, doc, until: endMarker)
        expect(nodes).to(haveCount(1))

        let node = nodes[0]
        expect(node.document) == doc
        expect(node.sourceRange) == "1:1..1:6"
        expect(node.nodeType.name) == "attribute"
        expect(node.children).to(haveCount(2))
        expect(node.children[0].nodeType.name) == "attribute-key"
        expect(node.children[0].attributes) == [.text("name", "class")]
        expect(node.children[1].nodeType.name) == "attribute-value"
        expect(node.children[1].attributes) == [.text("value", "class")]

        expect(cursor.position.left) == "1:7"
    }

    func testQuoted1() throws {
        let doc = Document(source: "key=\"value\": stop")
        let p = attributesParser
        let endMarker = literal(":") *> pure(())

        let (nodes, cursor) = try parse(p, doc, until: endMarker)
        expect(nodes).to(haveCount(1))

        let node = nodes[0]
        expect(node.document) == doc
        expect(node.sourceRange) == "1:1..1:11"
        expect(node.nodeType.name) == "attribute"
        expect(node.children).to(haveCount(2))
        expect(node.children[0].nodeType.name) == "attribute-key"
        expect(node.children[0].attributes) == [.text("name", "key")]
        expect(node.children[1].nodeType.name) == "attribute-value"
        expect(node.children[1].attributes) == [.text("value", "value")]

        expect(cursor.position.left) == "1:12"
    }

    func testQuoted2() throws {
        let doc = Document(source: "key=\"a: \\\"b\": stop")
        let p = attributesParser
        let endMarker = literal(":") *> pure(())

        let (nodes, cursor) = try parse(p, doc, until: endMarker)
        expect(nodes).to(haveCount(1))

        let node = nodes[0]
        expect(node.document) == doc
        expect(node.sourceRange) == "1:1..1:12"
        expect(node.nodeType.name) == "attribute"
        expect(node.children).to(haveCount(2))
        expect(node.children[0].nodeType.name) == "attribute-key"
        expect(node.children[0].attributes) == [.text("name", "key")]
        expect(node.children[1].nodeType.name) == "attribute-value"
        expect(node.children[1].attributes) == [.text("value", "a: \"b")]

        expect(cursor.position.left) == "1:13"
    }

    func testValue1() throws {
        let doc = Document(source: "key=value: stop")
        let p = attributesParser
        let endMarker = literal(":") *> pure(())

        let (nodes, cursor) = try parse(p, doc, until: endMarker)
        expect(nodes).to(haveCount(1))

        let node = nodes[0]
        expect(node.document) == doc
        expect(node.sourceRange) == "1:1..1:9"
        expect(node.nodeType.name) == "attribute"
        expect(node.children).to(haveCount(2))
        expect(node.children[0].nodeType.name) == "attribute-key"
        expect(node.children[0].attributes) == [.text("name", "key")]
        expect(node.children[1].nodeType.name) == "attribute-value"
        expect(node.children[1].attributes) == [.text("value", "value")]

        expect(cursor.position.left) == "1:10"
    }

    func testMultiple1() throws {
        let doc = Document(source: ".id .class key=\"value\": stop")
        let p = attributesParser
        let endMarker = literal(":") *> pure(())

        let (nodes, cursor) = try parse(p, doc, until: endMarker)
        expect(nodes).to(haveCount(3))

        let node = nodes[0]
        expect(node.document) == doc
        expect(node.sourceRange) == "1:1..1:3"
        expect(node.nodeType.name) == "attribute"
        expect(node.children).to(haveCount(2))

        expect(cursor.position.left) == "1:23"
    }

    static var allTests : [(String, (AttributeTests) -> () throws -> Void)] {
        return [
            ("testId", testId),
            ("testClass", testClass),
            ("testQuoted1", testQuoted1),
            ("testQuoted2", testQuoted2),
            ("testValue1", testValue1),
            ("testMultiple1", testMultiple1),
        ]
    }
}
