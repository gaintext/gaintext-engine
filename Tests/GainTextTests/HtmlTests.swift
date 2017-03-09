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


class HtmlTests: XCTestCase {

    func testWritingText() throws {
        let doc = Document(source:
            "Headline\n" +
            "========\n" +
            "\n" +
            "Text with _embedded_ `markup`.\n" +
            "\n" +
            " * Layout in source is important\n" +
            "   - allows to write beautiful source documents\n" +
            "   - also readable by non-techies\n" +
            " * TBD\n")
        let html = doc.parseHTML()

        expect(html.querySelector("p")?.innerHTML)
            == "Text with <em>embedded</em> <code>markup</code>.\n"
    }

    func testParagraph() throws {
        let doc = Document(source:
            "Line one.\n" +
            "Line two.\n")
        let html = doc.parseHTML()

        expect(html.querySelector("p")?.innerHTML)
            == "Line one.\nLine two.\n"
    }

    func testPreformatted() throws {
        let doc = Document(source:
            "```\n" +
            "Line one.\n" +
            " Line two.\n" +
            "```\n"
        )
        let html = doc.parseHTML()

        expect(html.querySelector("code")?.innerHTML)
            == "Line one.\n Line two.\n"
    }

    func testStructuredElements() throws {
        let doc = Document(source:
            "author: Martin Waitz\n" +
            "  city: Nuremberg\n" +
            "  country: Germany\n")
        doc.global.register(block: ElementType("author"))
        let nodes = doc.parse()

        expect(nodes).to(haveCount(1))

        expect(nodes[0].nodeType.name) == "author"
    }

    func testStructuredText() throws {
        let doc = Document(source:
            "title: GainText example\n" +
            "author: Martin Waitz\n" +
            "\n" +
            "abstract:\n" +
            "  This is a small example which shows some *GainText* features.\n" +
            "\n" +
            "Chapter 1\n" +
            "=========\n" +
            "\n" +
            "Blah blah, see [figure:f1].\n" +
            "\n" +
            "figure: #f1\n" +
            "  image: fig1.png\n" +
            "  caption: A nice graphic explaining the text\n" +
            "\n")
        doc.global.register(block: ElementType("title"))
        doc.global.register(block: ElementType("author"))
        doc.global.register(block: ElementType("abstract"))
        doc.global.register(block: ElementType("figure"))

        let nodes = doc.parse()

        expect(nodes).to(haveCount(4))

        expect(nodes[0].nodeType.name) == "title"
        expect(nodes[1].nodeType.name) == "author"
        expect(nodes[2].nodeType.name) == "abstract"
        expect(nodes[3].nodeType.name) == "section"

    }

    static var allTests : [(String, (HtmlTests) -> () throws -> Void)] {
        return [
            ("testWritingText", testWritingText),
            ("testParagraph", testParagraph),
            ("testStructuredElements", testStructuredElements),
            ("testStructuredText", testStructuredText),
        ]
    }
}
