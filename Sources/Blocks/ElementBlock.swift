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
import Runes

/*
let errorType = ErrorNodeType("expected element")

public let elementBlockParser = Parser<[Node]> { input in
    var content: [Node] = []
    var newCursor = input

    // fail if there is no element at the start of the block
    let (nodes1, cursor1) = try elementWithIndentedContent.parse(newCursor)
    content += nodes1
    newCursor = cursor1

    // collect all further elements,
    // but don't abort parsing
    while !newCursor.atEndOfBlock && !newCursor.atWhitespaceOnlyLine {
        do {
            let (nodes, cursor) = try elementWithIndentedContent.parse(newCursor)
            content += nodes
            newCursor = cursor
        } catch {
            let start = newCursor.position
            try! newCursor.advanceLine()
            let node = Node(start: start, end: newCursor, nodeType: errorType)
            content += [node]
        }

    }
    return (content, newCursor)
}*/
