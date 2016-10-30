//
// GainText parser
// Copyright Martin Waitz
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//


public struct LiteralParser: NodeParser {
    public init(token: String) {
        self.token = token
        self.count = token.characters.count
    }

    public func parse(_ cursor: Cursor) throws -> ([Node], Cursor) {
        var cursor = cursor
        guard !cursor.atEndOfBlock else {
            throw ParserError.endOfScope(position: cursor.position)
        }
        let text = cursor.tail
        guard text.hasPrefix(token) else {
            throw ParserError.notFound(position: cursor.position)
        }
        let start = cursor.position
        try! cursor.advance(by: count)
        let node = Node(start: start, end: cursor, nodeType: LiteralParser.nodeType)
        return ([node], cursor)
    }

    static let nodeType = ElementNodeType(name: "token")

    let token: String
    let count: Int
}

extension LiteralParser: CustomStringConvertible {
    public var description: String {
        return "token '\(token)'"
    }
}

public struct NewlineParser: NodeParser {

    public func parse(_ cursor: Cursor) throws -> ([Node], Cursor) {
        guard !cursor.atEndOfBlock else {
            throw ParserError.endOfScope(position: cursor.position)
        }
        guard cursor.atEndOfLine else {
            throw ParserError.notFound(position: cursor.position)
        }
        var cursor = cursor
        let start = cursor.position
        try cursor.advanceLine()
        let node = Node(start: start, end: cursor, nodeType: NewlineParser.nodeType)
        return ([node], cursor)
    }

    static let nodeType = ElementNodeType(name: "newline")
}

extension NewlineParser: CustomStringConvertible {
    public var description: String {
        return "(newline)"
    }
}

public struct EmptyLines: NodeParser {
    public init() {}
    public func parse(_ cursor: Cursor) throws -> ([Node], Cursor) {
        var cursor = cursor
        cursor.skipEmptyLines()
        return ([], cursor)
    }
}

public class ListParser: NodeParser {
    public init(_ delegate: NodeParser, min: Int = 0, max: Int = 0, skip: NodeParser? = nil) {
        self.delegate = delegate
        self.minCount = min
        self.maxCount = max
        self.skip = skip
    }

    public func parse(_ cursor: Cursor) throws -> ([Node], Cursor) {
        var content: [Node] = []
        var newCursor = cursor

        if let skip = skip {
            let (_, skipped) = try skip.parse(cursor)
            newCursor = skipped
        }

        while !newCursor.atEndOfBlock {
            guard maxCount==0 || content.count < maxCount else { break }
            do {
                let (nodes, cursor) = try delegate.parse(newCursor)
                content += nodes
                newCursor = cursor
            } catch {
                break
            }

            if let skip = skip {
                let (_, skipped) = try skip.parse(newCursor)
                newCursor = skipped
            }
        }
        guard content.count >= minCount else {
            throw ParserError.notFound(position: cursor.position)
        }
        return (content, newCursor)
    }

    let delegate: NodeParser
    let skip: NodeParser?
    let minCount: Int
    let maxCount: Int
}

public struct TextLineParser: NodeParser {
    public init() {}

    public func parse(_ cursor: Cursor) throws -> ([Node], Cursor) {
        var cursor = cursor
        let start = cursor.position
        guard !cursor.atEndOfBlock else {
            throw ParserError.endOfScope(position: cursor.position)
        }

        var whitespaceOnly = true
        while !cursor.atEndOfLine {
            if whitespaceOnly && !cursor.atWhitespace { whitespaceOnly = false }
            try! cursor.advance()
        }
        guard !whitespaceOnly else {
            throw ParserError.endOfScope(position: cursor.position)
        }
        let node = Node(start: start, end: cursor, nodeType: TextLineParser.nodeType)
        try! cursor.advanceLine()
        return ([node], cursor)
    }

    class TextNodeType: NodeType {
        let name = "text"
        func constructAST(_ node: Node) -> ASTNode {
            return .text(node.sourceContent)
        }
    }

    static let nodeType = TextNodeType()
}

public struct CodeLineParser: NodeParser {
    public init() {}

    public func parse(_ cursor: Cursor) throws -> ([Node], Cursor) {
        var cursor = cursor
        let start = cursor.position
        guard !cursor.atEndOfBlock else {
            throw ParserError.endOfScope(position: cursor.position)
        }

        while !cursor.atEndOfLine {
            try! cursor.advance()
        }
        let node = Node(start: start, end: cursor, nodeType: CodeLineParser.nodeType)
        try! cursor.advanceLine()
        return ([node], cursor)
    }

    // TBD
    class CodeNodeType: NodeType {
        let name = "code-text"
        func constructAST(_ node: Node) -> ASTNode {
            return .text(node.sourceContent)
        }
    }

    static let nodeType = CodeNodeType()
}
