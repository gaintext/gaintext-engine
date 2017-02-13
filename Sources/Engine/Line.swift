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


public protocol SpanParser {
    func parse(cursor: Cursor, until: Parser<()>) throws -> ([Node], Cursor)
}
// TBD: help transition from NodeParser to Parser<[Node]>
extension SpanParser {
    var parser: (Parser<()>) -> Parser<[Node]> {
        return { endMarker in
            return Parser { input in
                return try self.parse(cursor: input, until: endMarker)
            }
        }
    }
}

private class TextNodeType: NodeType {
    let name = "text"
    func constructAST(_ node: Node) -> ASTNode {
        return .text(node.sourceContent)
    }
}
private let textNodeType = TextNodeType()


public func createTextNode(start: Position, end: Cursor) -> Node {
    return Node(start: start, end: end,
                       nodeType: textNodeType)
}

public struct TextWithMarkupParser: SpanParser {

    public init(markup: Parser<[Node]>) {
        self.markup = markup
    }

    public func parse(cursor: Cursor, until endMarker: Parser<()>) throws -> ([Node], Cursor) {
        var cursor = cursor
        var startOfText = cursor.position
        cursor.markStartOfWord()

        do {
            return try (endMarker *> pure([])).parse(cursor)
        } catch is ParserError {}

        var nodes: [Node] = []
        func addTextNode() {
            if cursor.position != startOfText {
                let text = createTextNode(start: startOfText, end: cursor)
                nodes.append(text)
            }
        }

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

    private let markup: Parser<[Node]>
}

public struct RawTextParser: SpanParser {

    public init() {}

    public func parse(cursor: Cursor, until endMarker: Parser<()>) throws -> ([Node], Cursor) {
        var cursor = cursor
        let startOfText = cursor.position
        while !cursor.atEndOfLine {
            do {
                let (_, tail) = try endMarker.parse(cursor)
                guard cursor.position != startOfText else {
                    return ([], tail)
                }
                let text = createTextNode(start: startOfText, end: cursor)
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
    return try input.scope.spanParser.parse(cursor: input, until: endOfLine)
}
