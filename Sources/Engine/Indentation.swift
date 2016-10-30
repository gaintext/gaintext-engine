//
// GainText parser
// Copyright Martin Waitz
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//


public struct IndentParser: BlockParser {

    public init(indent: String? = nil) {
        self.indent = indent
    }

    public func parseIndent(_ cursor: Cursor) throws -> String {
        var cursor = cursor
        let start = cursor.position
        while cursor.atWhitespace {
            try! cursor.advance()
        }
        guard cursor.position != start else {
            throw ParserError.notFound(position: start)
        }
        return cursor.head(from: start)
    }

    func parseBlock(indented prefix: String, _ cursor: Cursor) throws -> ([Line], Cursor) {
        assert(!prefix.isEmpty)
        var outerCursor = cursor
        var nextCursor = outerCursor
        var lines: [Line] = []
        var tentative: [Line] = []
        while !outerCursor.atEndOfBlock {
            if outerCursor.atWhitespaceOnlyLine {
                // only use this line if other indented content follows
                tentative.append(outerCursor.line)
                try! outerCursor.advanceLine()
                continue
            }
            guard outerCursor.tail.hasPrefix(prefix) else { break }
            try! outerCursor.advance(by: prefix.characters.count)
            let line = Line(start: outerCursor.position, endIndex: outerCursor.line.endIndex)
            if !tentative.isEmpty {
                lines.append(contentsOf: tentative)
                tentative = []
            }
            lines.append(line)
            try! outerCursor.advanceLine()
            nextCursor = outerCursor
        }
        return (lines, nextCursor)
    }

    public func parse(_ cursor: Cursor) throws -> ([Line], Cursor) {
        if let indent = indent {
            return try parseBlock(indented: indent, cursor)
        } else {
            let indent = try parseIndent(cursor)
            return try parseBlock(indented: indent, cursor)
        }
    }

    static let nodeType = ElementNodeType(name: "indented")

    let indent: String?
}
