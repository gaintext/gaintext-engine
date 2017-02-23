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


private let blockDelimiterLine = Parser<String> { input in
    guard !input.atEndOfBlock && !input.atEndOfLine else {
        throw ParserError.notFound(position: input.position)
    }
    let key = input.char
    var tail = input
    try! tail.advance()

    var count = 1
    while !tail.atEndOfLine {
        guard tail.char == key else {
            break
        }
        try! tail.advance()
        count += 1
    }
    guard count >= 3 else {
        throw ParserError.notFound(position: input.position)
    }

    return (tail.head(from: input.position), tail)
}


private func contentLines(until delimiter: String) -> Parser<[Line]> {
    return Parser { input in
        var cursor = input
        var lines: [Line] = []
        guard !cursor.atEndOfBlock else {
            throw ParserError.endOfScope(position: cursor.position)
        }
        while cursor.tail != delimiter {
            lines.append(cursor.line)
            try! cursor.advanceLine()
            guard !cursor.atEndOfBlock else {
                throw ParserError.endOfScope(position: cursor.position)
            }
        }
        try! cursor.advanceLine()
        return (lines, cursor)
    }
}

public let lineDelimitedContent =
    lookahead(blockDelimiterLine) >>- { delimiter in
        element(
            elementCreateBlockParser(name: "block:\(delimiter.characters.first!)") *>
            literal(delimiter) *>
            optional(elementContent(attributesParser(literal(":")*>pure(())))) *>
            optional(whitespace) *> elementTitleLine *> endOfLine *>
            elementNodeAttribute(.text("delimiter", String(delimiter))) *>
            contentLines(until: delimiter) >>- elementBodyBlock
        )
    }
