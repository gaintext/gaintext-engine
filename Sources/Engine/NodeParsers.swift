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
                        attributes: [attr: value])
        return ([node], end)
    }
}

/// Create a node parser which wraps content into a new parent node.
public func node(_ type: NodeType, content: Parser<[Node]>) -> Parser<[Node]> {
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

private let textNodeType = NodeType(name: "text")

/// Helper to create a text node
public func textNode(start: Position, end: Cursor) -> Node {
    return Node(start: start, end: end, nodeType: textNodeType)
}

/// Parser wrapping the result of another parser in one text node.
public func textNode<Content>(spanning content: Parser<Content>, type: NodeType = textNodeType) -> Parser<[Node]> {
    return Parser { input in
        let start = input.position
        let (_, end) = try content.parse(input)
        let node = Node(start: start, end: end, nodeType: type)
        return ([node], end)
    }
}

private let lineNodeType = NodeType(name: "line")

/// Parser for one line of text.
public let textLine = node(lineNodeType, content: lineParser) <* advanceLine

/// Parser for one line of code.
public let codeLine = node(lineNodeType, content: textNode(spanning: wholeLine)) <* advanceLine
