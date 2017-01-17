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


func indentedBlockParser(prefix: String) -> Parser<[Line]> {
    assert(!prefix.isEmpty)
    return Parser { input in
        var cursor = input
        var nextCursor = cursor
        var lines: [Line] = []
        var tentative: [Line] = []
        while !cursor.atEndOfBlock {
            if cursor.atWhitespaceOnlyLine {
                // only use this line if other indented content follows
                tentative.append(cursor.line)
                try! cursor.advanceLine()
                continue
            }
            guard cursor.tail.hasPrefix(prefix) else { break }
            try! cursor.advance(by: prefix.characters.count)
            let line = Line(start: cursor.position, endIndex: cursor.line.endIndex)
            if !tentative.isEmpty {
                lines.append(contentsOf: tentative)
                tentative = []
            }
            lines.append(line)
            try! cursor.advanceLine()
            nextCursor = cursor
        }
        return (lines, nextCursor)
    }
}

public let indentationParser =
    lookahead(whitespace) >>- indentedBlockParser
