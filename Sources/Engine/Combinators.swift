//
// GainText parser
// Copyright Martin Waitz
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//


public struct DisjunctiveParser: NodeParser {
    public init(list: [NodeParser]) {
        self.list = list
    }

    public func parse( _ cursor: Cursor) throws -> ([Node], Cursor) {
        for parser in list {
            do {
                //print("\(cursor.position): trying \(parser)")
                return try parser.parse(cursor)
            } catch {
                //print("\(cursor.position): error \(e)")
            }
        }
        throw ParserError.notFound(position: cursor.position)
    }

    let list: [NodeParser]
}

extension DisjunctiveParser: CustomStringConvertible {
    public var description: String {
        let descriptions = list.map { String(describing: $0) }
        return "(" + descriptions.joined(separator: " | ") + ")"
    }
}

public struct SequenceParser: NodeParser {
    public init(list: [NodeParser]) {
        self.list = list
    }

    public func parse(_ cursor: Cursor) throws -> ([Node], Cursor) {
        var cursor = cursor
        var content: [Node] = []
        for parser in list {
            let (nodes, nextCursor) = try parser.parse(cursor)
            content += nodes
            cursor = nextCursor
        }
        return (content, cursor)
    }

    let list: [NodeParser]
}

extension SequenceParser: CustomStringConvertible {
    public var description: String {
        let descriptions = list.map { String(describing: $0) }
        return descriptions.joined(separator: ", ")
    }
}


public class DeferredParser: NodeParser {
    public func resolve(_ delegate: NodeParser) {
        self.delegate = delegate
    }

    public func parse(_ cursor: Cursor) throws -> ([Node], Cursor) {
        return try delegate!.parse(cursor)
    }

    var delegate: NodeParser?
}

extension DeferredParser: CustomStringConvertible {
    public var description: String {
        return "(deferred)"
    }
}
