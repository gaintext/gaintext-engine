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


private let blockDelimiter = Parser<Element> { input in
    var cursor = input
    guard !cursor.atEndOfBlock && !cursor.atEndOfLine else {
        throw ParserError.notFound(position: input.position)
    }
    let key = cursor.char

    guard let element = cursor.scope.block(name: "block:\(key)") else {
        throw ParserError.notFound(position: input.position)
    }
    try! cursor.advance()

    var count = 1
    while !cursor.atEndOfLine {
        guard cursor.char == key else {
            break
        }
        try! cursor.advance()
        count += 1
    }
    guard count >= 3 else {
        throw ParserError.notFound(position: input.position)
    }

    return (element, cursor)
}


public let lineDelimitedContent = Parser<[Node]> { input in
    let start = input.position
    var (element, cursor) = try blockDelimiter.parse(input)
    let delimiter = cursor.head(from: start)
    cursor.skipWhitespace()
    element.parseTitle(cursor: cursor)
    try cursor.advanceLine()

    guard !cursor.atEndOfBlock else {
        throw ParserError.endOfScope(position: cursor.position)
    }

    var lines: [Line] = []
    while cursor.tail != delimiter {
        lines.append(cursor.line)
        try! cursor.advanceLine()
        guard !cursor.atEndOfBlock else {
            throw ParserError.endOfScope(position: cursor.position)
        }
    }
    try! cursor.advanceLine()

    element.parseBody(block: lines, parent: cursor)
    element.addAttribute(.text("delimiter", delimiter))

    let node = element.createNode(start: start, end: cursor)

    cursor.skipEmptyLines()

    return ([node], cursor)
}
