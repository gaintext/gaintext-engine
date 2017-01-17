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


/// Parse text lines into a paragraph.
/// Uses the element `p` to parse all lines up to the next empty line.
public let paragraph = Parser<[Node]> { input in
    let start = input.position
    var cursor = input

    guard !cursor.atEndOfBlock else {
        throw ParserError.endOfScope(position: cursor.position)
    }
    var lines: [Line] = []
    while !cursor.atEndOfBlock {
        guard !cursor.atWhitespaceOnlyLine else { break }
        lines.append(cursor.line)
        try! cursor.advanceLine()
    }
    guard lines.count > 0 else {
        throw ParserError.notFound(position: cursor.position)
    }

    guard let element = cursor.scope.block(name: "p") else {
        throw ParserError.notFound(position: start)
    }
    element.parseBody(block: lines, parent: cursor)

    let node = element.createNode(start: start, end: cursor)

    cursor.skipEmptyLines()

    return ([node], cursor)
}
