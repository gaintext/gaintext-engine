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
        let doc = simpleDocument(
            """
            Headline
            ========

            Text with _embedded_ `markup`.

             * Layout in source is important
               - allows to write beautiful source documents
               - also readable by non-techies
             * TBD
            """)
        let html = doc.parseHTML()

        expect(html.querySelector("p")?.innerHTML)
            == "Text with <em>embedded</em> <code>markup</code>.\n"
    }

    func testParagraph() throws {
        let doc = simpleDocument(
            """
            Line one.
            Line two.
            """)
        let html = doc.parseHTML()

        expect(html.body!.innerHTML)
            == "<p>Line one.\nLine two.\n</p>"
    }

    func testBlockquote() throws {
        let doc = simpleDocument(
            """
            > Line one.
            > Line two.
            """)
        let html = doc.parseHTML()

        expect(html.body!.innerHTML) ==
            """
            <blockquote><p>Line one.
            Line two.
            </p></blockquote>
            """
    }

    func testPreformatted() throws {
        let doc = simpleDocument(
            """
            ```
            Line one.
             Line two.
            ```
            """
        )
        let html = doc.parseHTML()

        expect(html.body!.innerHTML) ==
            """
            <pre><code>Line one.
             Line two.
            </code></pre>
            """
    }

    func testPreformattedBlockquote() throws {
        let doc = simpleDocument(
            """
            > ```
            > Line one.
            >  Line two.
            > ```
            """
        )
        let html = doc.parseHTML()

        expect(html.body!.innerHTML) ==
            """
            <blockquote><pre><code>Line one.
             Line two.
            </code></pre></blockquote>
            """
    }

    func testAttributes1() throws {
        let doc = simpleDocument("p .cls1 .cls2 key=\"value\": stop")

        let html = doc.parseHTML()
        let p = html.body!.firstChild! as! HTMLElement

        expect(p.attributes).to(haveCount(2))
        expect(p.attributes) == ["class": "cls1 cls2", "key": "value"]
    }
    
    func testStructuredElements() throws {
        let doc = simpleDocument(
            """
            author: Martin Waitz
              city: Nuremberg
              country: Germany
            """)
        doc.global.register(block: ElementType("author"))
        doc.global.register(block: ElementType("city"))
        doc.global.register(block: ElementType("country"))
        let html = doc.parseHTML()

        expect(html.querySelector("author")?.innerHTML) ==
            """
            Martin Waitz
            <city>Nuremberg
            </city><country>Germany
            </country>
            """
    }

    func testStructuredText() throws {
        let doc = simpleDocument(
            """
            title: GainText example
            author: Martin Waitz

            abstract:
              This is a small example which shows some *GainText* features.

            Chapter 1
            =========

            Blah blah, see [figure:f1].

            figure: #f1
              image: fig1.png
              caption: A nice graphic explaining the text

            """)
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

        let doc = simpleDocument(text)
        let html = doc.parseHTML()

        expect(html.querySelector("p")?.innerHTML) == text
    }

    func testEntities2() throws {
        let doc = simpleDocument("&mdash; &quot; &#182;\n")
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
