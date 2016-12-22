//
// GainText parser
// Copyright Martin Waitz
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//


public protocol ElementParser: NodeParser {}

extension ElementParser {

    public func parseSpanBody(element: Element, cursor: Cursor, until endMarker: Parser<()>) throws -> Cursor {
        var cursor = cursor
        let oldScope = cursor.scope
        cursor.scope = element.childScope()

        var next = try element.parseSpan(cursor: cursor, until: endMarker)

        next.scope = oldScope
        return next
    }
}

extension ElementParser {

    func detectElementStartName(_ cursor: Cursor) -> (String, Cursor)? {
        var cursor = cursor
        let start = cursor.position

        while cursor.atAlphaNumeric {
            try! cursor.advance()
        }
        guard cursor.position.index != start.index else {
            return nil
        }
        let name = cursor.head(from: start)

        guard cursor.at(oneOf: ":") else {
            return nil
        }
        try! cursor.advance()
        cursor.skipWhitespace()
        return (name, cursor)
    }


    public func detectBlockElementStart(_ cursor: Cursor) -> (Element, Cursor)? {
        guard let (name, cursor) = detectElementStartName(cursor) else {
            return nil
        }
        guard let element = cursor.scope.block(name: name) else {
            return nil
        }

        return (element, cursor)
    }
    public func detectMarkupElementStart(_ cursor: Cursor) -> (Element, Cursor)? {
        guard let (name, cursor) = detectElementStartName(cursor) else {
            return nil
        }
        guard let element = cursor.scope.markup(name: name) else {
            return nil
        }

        return (element, cursor)
    }
}

