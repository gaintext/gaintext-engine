//
// GainText parser
// Copyright Martin Waitz
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//

import Engine

public struct ElementBlockParser: NodeParser {

    public init() {}

    public func parse(_ cursor: Cursor) throws -> ([Node], Cursor) {
        var content: [Node] = []
        var newCursor = cursor

        // fail if there is no element at the start of the block
        let (nodes1, cursor1) = try delegate.parse(newCursor)
        content += nodes1
        newCursor = cursor1

        // collect all further elements,
        // but don't abort parsing
        while !newCursor.atEndOfBlock && !newCursor.atWhitespaceOnlyLine {
            do {
                let (nodes, cursor) = try delegate.parse(newCursor)
                content += nodes
                newCursor = cursor
            } catch {
                let start = newCursor.position
                try! newCursor.advanceLine()
                content += [Node(start: start, end: newCursor,
                                    nodeType: ElementBlockParser.errorType)]
            }

        }
        return (content, newCursor)
    }

    let delegate = ElementWithIndentedContent()
    static let errorType = ErrorNodeType("expected element")
}
