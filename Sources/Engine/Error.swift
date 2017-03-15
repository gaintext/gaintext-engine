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


// we have two types of errors:
// * parser does not match at all -> throw an Error
// * parser matches, but finds error in input -> create an error node


/// Error thrown when a parser does not match.
public enum ParserError: Error {
    case endOfScope(position: Position)
    case notFound(position: Position)
}


/// Block created when a parser matches but finds an error in the input.
public class ErrorNodeType: NodeType {
    public init(_ message: String) {
        self.message = message
        super.init(name: "error")
    }

    public func describe(_ node: Node) -> String {
        return "error \(node.sourceRange): \(message)"
    }

    override open func prepare(_ node: Node, _ scope: Scope) {
        print(describe(node))
    }

    let message: String
}

/// Parser returning an error marker at the current position.
public func errorMarker(_ msg: String) -> Parser<[Node]> {
    let nodeType = ErrorNodeType(msg)
    return Parser { input in
        let node = Node(start: input.position, end: input, nodeType: nodeType)
        return ([node], input)
    }
}

/// Parser returning an error marker covering the rest of the block.
public func errorBlock(errorType: ErrorNodeType) -> Parser<[Node]> {
    return Parser { input in
        var cursor = input
        while !cursor.atEndOfBlock { try! cursor.advanceLine() }
        let node = Node(start: input.position, end: cursor, nodeType: errorType)
        return ([node], cursor)
    }
}

/// Parser returning an error marker covering the rest of the line.
public func errorLine(errorType: ErrorNodeType) -> Parser<[Node]> {
    return Parser { input in
        var cursor = input
        while !cursor.atEndOfLine { try! cursor.advance() }
        let node = Node(start: input.position, end: cursor, nodeType: errorType)
        try cursor.advanceLine()
        return ([node], cursor)
    }
}

/// Parser producing an error block for any unconsumed input of this block.
public let expectEndOfBlock =
    (satisfying {$0.atEndOfBlock} *> pure([])) <|> errorBlock(errorType: unexpectedInputError)
private let unexpectedInputError = ErrorNodeType("unexpected input")
