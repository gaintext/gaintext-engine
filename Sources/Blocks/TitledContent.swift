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

public struct TitledContent: ElementParser {

    public init() {}

    func detectSectionStart(_ cursor: Cursor) -> (Cursor, Character)? {
        return detectSectionStart(cursor, underlineChars: "=-~_+'\"")
    }

    func detectSectionStart(_ cursor: Cursor, underlineChars: String) -> (Cursor, Character)? {
        var cursor = cursor
        guard !cursor.atEndOfBlock else { return nil }
        guard !cursor.atWhitespaceOnlyLine else { return nil }
        try! cursor.advanceLine()
        guard !cursor.atEndOfBlock else { return nil }

        // check that second line only contains the underline
        let c = cursor.char
        guard underlineChars.characters.contains(c) else {
            return nil
        }
        var count = 1
        try! cursor.advance()
        while !cursor.atEndOfLine {
            if cursor.atWhitespace { continue }
            guard cursor.char == c else {
                return nil
            }
            count += 1
            try! cursor.advance()
        }
        guard count >= 3 else {
            return nil
        }

        try! cursor.advanceLine()
        if !cursor.atEndOfBlock {
            guard cursor.atWhitespaceOnlyLine else {
                return nil
            }
            try! cursor.advanceLine()
        }

        return (cursor, c)
    }

    func detectElement(_ cursor: Cursor) -> (Element, Cursor)? {
        if let (element, titleCursor) = detectBlockElementStart(cursor) {
            return (element, titleCursor)
        }
        if let section = cursor.scope.block(name: "section") {
            return (section, cursor)
        }
        return nil
    }

    public func parse(_ cursor: Cursor) throws -> ([Node], Cursor) {
        let start = cursor.position

        guard let (contentCursor, underline) = detectSectionStart(cursor) else {
            throw ParserError.notFound(position: cursor.position)
        }
        guard let (element, titleCursor) = detectElement(cursor) else {
            throw ParserError.notFound(position: cursor.position)
        }

        element.addTitleAttribute(.text("underline", String(underline)))
        element.parseTitle(cursor: titleCursor)

        var cursor = contentCursor
        var lines: [Line] = []
        while !cursor.atEndOfBlock {
            guard detectSectionStart(cursor, underlineChars: String(underline)) == nil else { break }
            lines.append(cursor.line)
            try! cursor.advanceLine()
        }
        element.parseBody(block: lines, parent: cursor)

        let node = element.createNode(start: start, end: cursor)

        cursor.skipEmptyLines()

        return ([node], cursor)
    }
}
