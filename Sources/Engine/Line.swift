//
// GainText parser
// Copyright Martin Waitz
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//


public protocol SpanParser {
    typealias EndMarker = (Cursor) -> Cursor?
    func parse(cursor: Cursor, until: EndMarker) throws -> ([Node], Cursor)
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

    public init(markup: NodeParser) {
        self.markup = markup
    }

    public func parse(cursor: Cursor, until endMarker: (Cursor) -> Cursor?) throws -> ([Node], Cursor) {
        var cursor = cursor
        var startOfText = cursor.position
        cursor.markStartOfWord()

        if let endCursor = endMarker(cursor) {
            return ([], endCursor)
        }

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
            if let endCursor = endMarker(cursor) {
                addTextNode()

                return (nodes, endCursor)
            }
        }
        throw ParserError.notFound(position: cursor.position)
    }

    private let markup: NodeParser
}

public struct RawTextParser: SpanParser {

    public init() {}

    public func parse(cursor: Cursor, until endMarker: (Cursor) -> Cursor?) throws -> ([Node], Cursor) {
        var cursor = cursor
        let startOfText = cursor.position
        while !cursor.atEndOfLine {
            if let endCursor = endMarker(cursor) {
                guard cursor.position != startOfText else {
                    return ([], endCursor)
                }
                let text = createTextNode(start: startOfText, end: cursor)
                return ([text], endCursor)
            }
            try! cursor.advance()
        }

        throw ParserError.notFound(position: cursor.position)
    }
}


/// Parse one complete line using the current span parser
public class LineParser: NodeParser {
    public init() {}

    private func endOfLineMarker(_ cursor: Cursor) -> Cursor? {
        var cursor = cursor
        guard cursor.atEndOfLine else { return nil }
        try! cursor.advanceLine()
        return cursor
    }

    public func parse(_ cursor: Cursor) throws -> ([Node], Cursor) {
        return try cursor.scope.spanParser.parse(cursor: cursor, until: endOfLineMarker)
    }
}
