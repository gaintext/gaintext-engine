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
import Runes

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

        let endMarker = satisfying {!$0.atStartOfWord}
                     *> literal(delimiter)
                     *> pure(())
        cursor = try parseSpanBody(element: element, cursor: cursor, until: endMarker)
        let node = element.createNode(start: start, end: cursor)
        return ([node], cursor)
    }
}
