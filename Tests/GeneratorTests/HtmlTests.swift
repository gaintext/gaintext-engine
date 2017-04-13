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

        expect(html.body!.innerHTML)
            == "<p>Line one.\nLine two.\n</p>"
    }

    func testBlockquote() throws {
        let doc = Document(source:
            "> Line one.\n" +
            "> Line two.\n")
        let html = doc.parseHTML()

        expect(html.body!.innerHTML)
            == "<blockquote><p>Line one.\nLine two.\n</p></blockquote>"
    }

    func testPreformatted() throws {
        let doc = Document(source:
            "```\n" +
            "Line one.\n" +
            " Line two.\n" +
            "```\n"
        )
        let html = doc.parseHTML()

        expect(html.body!.innerHTML)
            == "<pre><code>Line one.\n Line two.\n</code></pre>"
    }

    func testPreformattedBlockquote() throws {
        let doc = Document(source:
            "> ```\n" +
            "> Line one.\n" +
            ">  Line two.\n" +
            "> ```\n"
        )
        let html = doc.parseHTML()

        expect(html.body!.innerHTML)
            == "<blockquote><pre><code>Line one.\n Line two.\n</code></pre></blockquote>"
    }

    func testAttributes1() throws {
        let doc = Document(source: "p .cls1 .cls2 key=\"value\": stop")

        let html = doc.parseHTML()
        let p = html.body!.firstChild! as! HTMLElement

        expect(p.attributes).to(haveCount(2))
        expect(p.attributes) == ["class": "cls1 cls2", "key": "value"]
    }
    
    func testStructuredElements() throws {
        let doc = Document(source:
            "author: Martin Waitz\n" +
            "  city: Nuremberg\n" +
            "  country: Germany\n")
        doc.global.register(block: ElementType("author"))
        doc.global.register(block: ElementType("city"))
        doc.global.register(block: ElementType("country"))
        let html = doc.parseHTML()

        expect(html.querySelector("author")?.innerHTML) ==
            "Martin Waitz\n<city>Nuremberg\n</city><country>Germany\n</country>"
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

        let html = doc.parseHTML()

        expect(html.querySelector("abstract")?.innerHTML) ==
            "<p>This is a small example which shows some <em>GainText</em> features.\n</p>"
        expect(html.querySelector("section h1")?.innerHTML) ==
        "Chapter 1"
    }

    func testEntities1() throws {
        let text = "HTML &amp; entities &lt;html&gt;&lt;/html&gt; elements\n"

        let doc = Document(source: text)
        let html = doc.parseHTML()

        expect(html.querySelector("p")?.innerHTML) == text
    }

    func testEntities2() throws {
        let doc = Document(source: "&mdash; &quot; &#182;\n")
        let html = doc.parseHTML()

        expect(html.querySelector("p")?.innerHTML) == "— \" ¶\n"
    }

    static var allTests : [(String, (HtmlTests) -> () throws -> Void)] {
        return [
            ("testWritingText", testWritingText),
            ("testParagraph", testParagraph),
            ("testBlockquote", testBlockquote),
            ("testPreformatted", testPreformatted),
            ("testPreformattedBlockquote", testPreformattedBlockquote),
            ("testAttributes1", testAttributes1),
            ("testStructuredElements", testStructuredElements),
            ("testStructuredText", testStructuredText),
        ]
    }
}
