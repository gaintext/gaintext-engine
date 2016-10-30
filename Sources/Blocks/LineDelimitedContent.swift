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

public struct LineDelimitedContent: NodeParser {

    public init() {}

    func detectDelimiter(_ cursor: Cursor) -> (Element, Cursor)? {
        var cursor = cursor
        guard !cursor.atEndOfBlock && !cursor.atEndOfLine else {
            return nil
        }
        let key = cursor.char

        guard let element = cursor.scope.block(name: "block:\(key)") else {
            return nil
        }
        try! cursor.advance()

        var count = 1
        while !cursor.atEndOfLine {
            guard cursor.char == key else {
                break
            }
            try! cursor.advance()
            count += 1
        }
        guard count >= 3 else {
            return nil
        }

        return (element, cursor)
    }

    public func parse(_ cursor: Cursor) throws -> ([Node], Cursor) {
        let start = cursor.position
        guard let (element, endOfDelimiter) = detectDelimiter(cursor) else {
            throw ParserError.notFound(position: start)
        }
        let delimiter = endOfDelimiter.head(from: start)
        var cursor = endOfDelimiter
        cursor.skipWhitespace()
        element.parseTitle(cursor: cursor)
        try cursor.advanceLine()

        guard !cursor.atEndOfBlock else {
            throw ParserError.endOfScope(position: cursor.position)
        }

        var lines: [Line] = []
        while cursor.tail != delimiter {
            lines.append(cursor.line)
            try! cursor.advanceLine()
            guard !cursor.atEndOfBlock else {
                throw ParserError.endOfScope(position: cursor.position)
            }
        }
        try! cursor.advanceLine()

        element.parseBody(block: lines, parent: cursor)
        element.addAttribute(.text("delimiter", delimiter))

        let node = element.createNode(start: start, end: cursor)

        cursor.skipEmptyLines()

        return ([node], cursor)
    }
}
