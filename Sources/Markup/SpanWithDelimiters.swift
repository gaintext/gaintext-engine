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

public struct SpanWithDelimiters: ElementParser {

    public init() {}

    public func parse(_ cursor: Cursor) throws -> ([Node], Cursor) {
        var cursor = cursor
        let start = cursor.position
        let delimiter = cursor.char

        guard cursor.atStartOfWord else {
            throw ParserError.notFound(position: start)
        }
        try! cursor.advance()
        guard !cursor.atWhitespace else {
            throw ParserError.notFound(position: start)
        }
        let key = "span:\(delimiter)"
        guard let element = cursor.scope.markup(name: key) else {
            throw ParserError.notFound(position: start)
        }

        cursor = try parseSpanBody(element: element, cursor: cursor) {
            var end = $0
            guard !end.atEndOfLine else { return nil }
            guard !end.atStartOfWord else { return nil }
            guard end.char == delimiter else { return nil }
            try! end.advance()
            return end
        }

        let node = element.createNode(start: start, end: cursor)
        return ([node], cursor)
    }
}
