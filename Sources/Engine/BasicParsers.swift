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


/// Parser for one specific character.
public func literal(_ token: Character) -> Parser<String> {
    return Parser<String> { input in
        guard !input.atEndOfBlock else {
            throw ParserError.endOfScope(position: input.position)
        }
        guard input.char == token else {
            throw ParserError.notFound(position: input.position)
        }
        var cursor = input
        try! cursor.advance()
        return (String(token), cursor)
    }
}

/// Parser for one specific literal string.
public func literal(_ token: String) -> Parser<String> {
    let count = token.characters.count

    return Parser<String> { input in
        var cursor = input
        guard !cursor.atEndOfBlock else {
            throw ParserError.endOfScope(position: cursor.position)
        }
        let text = cursor.tail
        guard text.hasPrefix(token) else {
            throw ParserError.notFound(position: cursor.position)
        }
        try! cursor.advance(by: count)
        return (token, cursor)
    }
}

/// Parser for one character from a set.
public func oneOf(_ set: String) -> Parser<String> {
    return Parser<String> { input in
        guard !input.atEndOfBlock else {
            throw ParserError.endOfScope(position: input.position)
        }
        guard input.at(oneOf: set) else {
            throw ParserError.notFound(position: input.position)
        }
        var tail = input
        try! tail.advance()
        return (String(input.char), tail)
    }
}

/// Parser for one character from a set.
public func oneOf(_ set: Set<Character>) -> Parser<String> {
    return Parser<String> { input in
        guard !input.atEndOfBlock else {
            throw ParserError.endOfScope(position: input.position)
        }
        guard input.at(oneOf: set) else {
            throw ParserError.notFound(position: input.position)
        }
        var tail = input
        try! tail.advance()
        return (String(input.char), tail)
    }
}

/// Parser which collects all consecutive characters while a specified matching condition holds.
public func collect(min: Int = 1, takeWhile: @escaping (Cursor) -> Bool) -> Parser<String> {
    return Parser<String> { input in
        var cursor = input
        var result = ""
        var count = 0
        guard !input.atEndOfBlock else {
            throw ParserError.endOfScope(position: input.position)
        }
        while !cursor.atEndOfLine && takeWhile(cursor) {
            result.append(cursor.char)
            try! cursor.advance()
            count += 1
        }
        guard count >= min else {
            throw ParserError.notFound(position: cursor.position)
        }
        return (result, cursor)
    }
}

/// Parser which collects all consecutive characters until a specified abort condition holds.
public func collect(min: Int = 1, until: @escaping (Cursor) -> Bool) -> Parser<String> {
    return Parser<String> { input in
        var cursor = input
        var result = ""
        var count = 0
        guard !input.atEndOfBlock else {
            throw ParserError.endOfScope(position: input.position)
        }
        while !cursor.atEndOfLine && !until(cursor) {
            result.append(cursor.char)
            try! cursor.advance()
            count += 1
        }
        guard count >= min else {
            throw ParserError.notFound(position: cursor.position)
        }
        return (result, cursor)

    }
}

/// Parser which collects all consecutive characters from a set.
public func collect(min: Int = 1, fromSet: String) -> Parser<String> {
    return collect(min: min, takeWhile: { cursor in cursor.at(oneOf: fromSet) })
}
/// Parser which collects all consecutive characters from a set.
public func collect(min: Int = 1, fromSet: Set<Character>) -> Parser<String> {
    return collect(min: min, takeWhile: { cursor in cursor.at(oneOf: fromSet) })
}

/// Parser which matches any character.
public let character = Parser<String> { input in
    guard !input.atEndOfBlock && !input.atEndOfLine else {
        throw ParserError.notFound(position: input.position)
    }
    let result = String(input.char)
    var cursor = input
    try cursor.advance()
    return (result, cursor)
}

/// Parser which matches all characters up to the next white-space.
public let word = collect(until: { $0.atWhitespace })

private let identifierChars = "_@0123456789"
    + "abcdefghijklmnopqrstuvwxyz"
    + "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
/// Parser which matches identifiers (all alpha-numerical characters).
public let identifier = collect(fromSet: Set(identifierChars.characters))

public let whitespace = collect(takeWhile: { $0.atWhitespace })

/// Parser which matches a quoted string.
///
/// A single quote can be embedded by escaping it with a backslash (`\"`).
public let quotedString = Parser<String> { input in
    var cursor = input
    let start = cursor.position

    guard cursor.at(oneOf: "\"") else {
        throw ParserError.notFound(position: start)
    }
    try! cursor.advance()

    var result = ""
    loop: while true {
        guard !cursor.atEndOfLine else {
            throw ParserError.notFound(position: start)
        }
        switch cursor.char {
        case "\"":
            break loop
        case "\\":
            try! cursor.advance()
            guard !cursor.atEndOfLine else {
                throw ParserError.notFound(position: start)
            }
            result.append(cursor.char)
        default:
            result.append(cursor.char)
        }
        try! cursor.advance()
    }
    try! cursor.advance()
    return (result, cursor)
}

/// Parser which matches when a specified condition holds.
///
/// Does not consume any input.
public func satisfying(_ f: @escaping (Cursor) -> Bool) -> Parser<()> {
    return Parser { input in
        guard f(input) else {
            throw ParserError.notFound(position: input.position)
        }
        return ((), input)
    }
}

/// Parser which always returns a value without consuming input.
public func pure<Result>(_ value: Result) -> Parser<Result> {
    return Parser { input in (value, input) }
}

/// Parser which consumes the whole content of a line.
public let wholeLine = Parser<()> { input in
    var cursor = input
    while !cursor.atEndOfLine {
        try! cursor.advance()
    }
    return ((), cursor)
}

/// Parser which moves to the next line (skipping the rest of this line).
public let advanceLine = Parser<()> { input in
    var cursor = input
    try cursor.advanceLine()
    return ((), cursor)
}

/// Parser which consumes the end-of-line and moves to the next line.
public let endOfLine = satisfying {$0.atEndOfLine} *> advanceLine

/// Parser which consumes one empty line.
public let emptyLine = satisfying {$0.atWhitespaceOnlyLine} *> advanceLine

/// Parser which consumes empty lines.
public let skipEmptyLines = Parser<()> { input in
    var cursor = input
    while !cursor.atEndOfBlock && cursor.atWhitespaceOnlyLine {
        try! cursor.advanceLine()
    }
    return ((), cursor)
}


/// Debugging Parser which prints the current position.
public func debug(msg: String, file: StaticString = #file, line: Int = #line) -> Parser<()> {
    return Parser { input in
        debugPrint("\(file):\(line): debug(\(input.position.right)) \(msg)")
        return ((), input)
    }
}
/// Debugging Parser which wraps any parser and prints its result.
public func debug<Result>(_ p: Parser<Result>, file: StaticString = #file, line: Int = #line) -> Parser<Result> {
    return Parser { input in
        do {
            let (result, tail) = try p.parse(input)
            debugPrint("\(file):\(line): debug(\(input.position.right)..\(tail.position.left)) parsed '\(result)'")
            return (result, tail)
        } catch let e as ParserError {
            debugPrint("\(file):\(line): debug(\(input.position.right)..) raised '\(e)'")
            throw e
        }
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
