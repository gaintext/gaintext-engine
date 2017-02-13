//
// GainText parser
// Copyright Martin Waitz
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//

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
    public let name = "error"

    public init(_ message: String) {
        self.message = message
    }

    func prepare(_ node: Node) {
        print("error: \(message): \(node)")
    }
    // TBD
    public func constructAST(_ node: Node) -> ASTNode {
        return .comment("error: \(message)")
    }

    let message: String
}

/// Create a new node representing an error message.
///
/// The new node will conain the whole rest of the current block.
private func createLineErrorNode(at start: Cursor, _ error: ErrorNodeType) -> (Node, Cursor) {
    var end = start
    while !end.atEndOfLine { try! end.advance() }
    let node = Node(start: start.position, end: end, nodeType: error)
    return (node, end)
}

/// Create a new node representing an error message.
///
/// The new node will conain the whole rest of the current block.
private func createBlockErrorNode(at start: Cursor, _ error: ErrorNodeType) -> Node {
    var end = start
    while !end.atEndOfBlock { try! end.advanceLine() }
    return Node(start: start.position, end: end, nodeType: error)
}


extension SpanParser {
    /// Use the `SpanParser` to parse a complete line.
    /// Returns an error node instead of throwing.
    func parseLine(_ cursor: Cursor, error nodeType: ErrorNodeType) -> ([Node], Cursor) {
        do {
            return try parse(cursor: cursor, until: satisfying {$0.atEndOfLine})
        } catch {
            let (errorNode, errorCursor) = createLineErrorNode(at: cursor, nodeType)
            return ([errorNode], errorCursor)
        }
    }
}
