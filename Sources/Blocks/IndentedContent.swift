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

public struct ElementWithIndentedContent: ElementParser {

    public func parse(_ cursor: Cursor) throws -> ([Node], Cursor) {
        let start = cursor.position

        guard let (element, newCursor) = detectBlockElementStart(cursor) else {
            throw ParserError.notFound(position: start)
        }
        var cursor = newCursor
        cursor.skipWhitespace()
        if !cursor.atEndOfLine {
             element.parseTitle(cursor: cursor)
        }
        try cursor.advanceLine()

        let indented = indentationParser()
        do {
            let (block, newCursor2) = try indented.parse(cursor)
            element.parseBody(block: block, parent: cursor)
            cursor = newCursor2
        } catch {}

        let node = element.createNode(start: start, end: cursor)

        return ([node], cursor)
    }
}
