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

/// Recognize a backslash escaped character as `raw` Element.
/// Backslash at the end of the line is regarded as an error.
public struct Escaped: NodeParser {

    public init() {}

    public func parse(_ cursor: Cursor) throws -> ([Node], Cursor) {
        let start = cursor.position
        guard cursor.at(oneOf: "\\") else {
            throw ParserError.notFound(position: start)
        }
        var cursor = cursor
        try! cursor.advance()
        guard !cursor.atEndOfLine else {
            let error = Node(start: start, end: cursor,
                                nodeType: Escaped.eolError)
            return ([error], cursor)
        }
        guard let element = cursor.scope.markup(name: "raw") else {
            throw ParserError.notFound(position: start)
        }
        let startOfText = cursor.position
        try! cursor.advance()

        let text = createTextNode(start: startOfText, end: cursor)
        element.body.append(text)

        let node = element.createNode(start: start, end: cursor)
        return ([node], cursor)
    }

    private static let eolError = ErrorNodeType("cannot escape end-of-line")
}
