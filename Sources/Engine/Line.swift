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


public func textWithMarkupParser(markup: Parser<[Node]>) -> SpanParser {
    return { endMarker in
        Parser { input in
            var startOfText = input.position
            var cursor = input

            do { // immediately return when endMarker matches
                return try (endMarker *> pure([])).parse(cursor)
            } catch is ParserError {}

            var nodes: [Node] = []
            func addTextNode() {
                if cursor.position != startOfText {
                    let text = textNode(start: startOfText, end: cursor)
                    nodes.append(text)
                }
            }

            cursor.markStartOfWord()
            while !cursor.atEndOfLine {
                do {
                    let (markupNodes, nextCursor) = try markup.parse(cursor)
                    addTextNode()
                    nodes += markupNodes
                    cursor = nextCursor
                    startOfText = cursor.position
                } catch {
                    try! cursor.advance()
                }
                do {
                    let (_, tail) = try endMarker.parse(cursor)
                    addTextNode()

                    return (nodes, tail)
                } catch is ParserError {}
            }
            throw ParserError.notFound(position: cursor.position)
        }
    }
}

public func rawTextParser(endMarker: Parser<()>) -> Parser<[Node]> {
    return Parser { input in
        let startOfText = input.position
        var cursor = input
        while !cursor.atEndOfLine {
            do {
                let (_, tail) = try endMarker.parse(cursor)
                guard cursor.position != startOfText else {
                    return ([], tail)
                }
                let text = textNode(start: startOfText, end: cursor)
                return ([text], tail)
            } catch is ParserError {
                try! cursor.advance()
            }
        }

        throw ParserError.notFound(position: cursor.position)
    }
}


/// Parse one complete line using the current span parser
public let lineParser = Parser<[Node]> { input in
    guard !input.atEndOfBlock else {
        throw ParserError.notFound(position: input.position)
    }
    return try input.scope.spanParser(endOfLine).parse(input)
}
