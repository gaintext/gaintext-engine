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

public struct SpanWithBrackets: ElementParser {

    public init() {}

    static func endMarker(_ cursor: Cursor) -> Cursor? {
        var cursor = cursor
        guard cursor.at(oneOf: "]") else { return nil }
        try! cursor.advance()
        return cursor
    }
    public func parse(_ cursor: Cursor) throws -> ([Node], Cursor) {
        var cursor = cursor
        let start = cursor.position
        guard cursor.at(oneOf: "[") else {
            throw ParserError.notFound(position: start)
        }
        try! cursor.advance()
        guard let (element, bodyCursor) = detectMarkupElementStart(cursor) else {
            throw ParserError.notFound(position: start)
        }
        cursor = try parseSpanBody(element: element, cursor: bodyCursor,
                                       until: SpanWithBrackets.endMarker)

        let node = element.createNode(start: start, end: cursor)
        return ([node], cursor)
    }
}
