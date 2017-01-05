//
// GainText parser
// Copyright Martin Waitz
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//

import Runes


private let elementStartNameParser = identifier <* literal(":") <* optional(whitespace)

public func elementCreateBlockParser(name: String) -> Parser<()> {
    return Parser { input in
        let scope = input.scope
        assert(scope.element == nil)

        guard let element = scope.block(name: name) else {
            throw ParserError.notFound(position: input.position)
        }
        scope.element = element

        return ((), input)
    }
}
public let elementStartBlockParser = elementStartNameParser >>- elementCreateBlockParser

public func elementCreateMarkupParser(name: String) -> Parser<()> {
    return Parser { input in
        let scope = input.scope
        assert(scope.element == nil)

        guard let element = scope.markup(name: name) else {
            throw ParserError.notFound(position: input.position)
        }
        scope.element = element

        return ((), input)
    }
}
public let elementStartMarkupParser = elementStartNameParser >>- elementCreateMarkupParser

/// Makes a parser store its result as the current element's title.
public func elementTitle(_ p: Parser<[Node]>) -> Parser<()> {
    return Parser { input in
        let element = input.scope.element!
        let (content, tail) = try p.parse(input)
        element.title += content
        return ((), tail)
    }
}

/// Makes a parser store its result in the current element's body.
public func elementContent(_ p: Parser<[Node]>) -> Parser<()> {
    return Parser { input in
        let element = input.scope.element!
        let (content, tail) = try p.parse(input)
        element.body += content
        return ((), tail)
    }
}

public let elementBody = elementBodyParser >>- elementContent

public func elementSpanBody(until endMarker: Parser<()>) -> Parser<()> {
    return elementTitleParser <*> pure(endMarker) >>- elementTitle
}
public func elementSpanBody(until endMarker: Parser<String>) -> Parser<()> {
    return elementSpanBody(until: endMarker *> pure(()))
}

/// Create a node from the current element.
func elementNodeParser(_ p: Parser<()>) -> Parser<[Node]> {
    return Parser { input in
        let start = input.position
        let scope = input.scope
        assert(scope.element == nil)

        let (_, tail) = try p.parse(input)

        assert(scope.element != nil) // TBD: assert or guard?
        guard let element = scope.element else {
            throw ParserError.notFound(position: input.position)
        }
        let node = element.createNode(start: start, end: tail)

        return ([node], tail)
    }
}

/// Executes a parser in a separate child scope
func newScopeParser<Result>(_ p: Parser<Result>) -> Parser<Result> {
    return Parser { input in
        var cursor = input
        let scope = cursor.scope
        cursor.scope = Scope(parent: scope)
        var (result, tail) = try p.parse(cursor)
        tail.scope = scope
        return (result, tail)
    }
}

public func element(_ p: Parser<()>) -> Parser<[Node]> {
    return newScopeParser(elementNodeParser(p))
}


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

