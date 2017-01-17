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


/// Create a node parser from a String parser
/// The new node will span the source range which was parsed by the input parser.
/// The result of the input parser will be attached as an attribute to the node.
func node(type: NodeType, attr: String, _ content: Parser<String>) -> Parser<[Node]> {
    return Parser { input in
        let start = input.position
        let (value, end) = try content.parse(input)
        let node = Node(start: start, end: end, nodeType: type,
                        attributes: [.text(attr, value)])
        return ([node], end)
    }
}

/// Create a node parser which wraps content into a new parent node.
public func node(type: NodeType, _ content: Parser<[Node]>) -> Parser<[Node]> {
    return Parser { input in
        let start = input.position
        let (children, end) = try content.parse(input)
        let node = Node(start: start, end: end, nodeType: type,
                        children: children)
        return ([node], end)
    }
}
/// Wrap some nodes in new parent node.
///
/// Returns a function which transforms a parser into a new parser
/// which adds the new parent node.
///
/// Example: `node(type: ...) <^> childNodeParser`
public func node(type: NodeType, keepEmpty: Bool = false) -> (Parser<[Node]>) -> Parser<[Node]> {
    return { content in
        Parser { input in
            let start = input.position
            let (children, tail) = try content.parse(input)
            guard !children.isEmpty || keepEmpty else {
                return ([], tail)
            }
            let node = Node(start: start, end: tail, nodeType: type,
                            children: children)
            return ([node], tail)
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

public func textNode<Content>(_ content: Parser<Content>) -> Parser<[Node]> {
    return Parser { input in
        let start = input.position
        let (_, end) = try content.parse(input)
        let node = Node(start: start, end: end, nodeType: textNodeType)
        return ([node], end)
    }
}

public func errorMarker(_ msg: String) -> Parser<[Node]> {
    let nodeType = ErrorNodeType(msg)
    return Parser { input in
        let node = Node(start: input.position, end: input, nodeType: nodeType)
        return ([node], input)
    }
}

public func errorBlock(errorType: ErrorNodeType) -> Parser<[Node]> {
    return Parser { input in
        var cursor = input
        while !cursor.atEndOfBlock { try! cursor.advanceLine() }
        let node = Node(start: input.position, end: cursor, nodeType: errorType)
        return ([node], cursor)
    }
}

public func errorLine(errorType: ErrorNodeType) -> Parser<[Node]> {
    return Parser { input in
        var cursor = input
        while !cursor.atEndOfLine { try! cursor.advance() }
        let node = Node(start: input.position, end: cursor, nodeType: errorType)
        try cursor.advanceLine()
        return ([node], cursor)
    }
}

/// Create a new parser which returns an error node when the input parser fails.
public func wholeBlock(errorType: ErrorNodeType, _ content: Parser<[Node]>) -> Parser<[Node]> {
    return (content <* satisfying { $0.atEndOfBlock }) <|> errorBlock(errorType: errorType)
}

/// Create a new parser which returns an error node when the input parser fails.
public func wholeLine(errorType: ErrorNodeType, _ content: Parser<[Node]>) -> Parser<[Node]> {
    return (content <* satisfying { $0.atEndOfLine }) <|> errorLine(errorType: errorType)
}


