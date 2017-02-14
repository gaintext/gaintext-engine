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


private let contentLines = Parser<[Line]> { input in
    var cursor = input
    var lines: [Line] = []
    while !cursor.atEndOfBlock {
        guard !cursor.atWhitespaceOnlyLine else { break }
        lines.append(cursor.line)
        try! cursor.advanceLine()
    }
    guard lines.count > 0 else {
        throw ParserError.notFound(position: cursor.position)
    }
    return (lines, cursor)
}

/// Parse text lines into a paragraph.
/// Uses the element `p` to parse all lines up to the next empty line.
public let paragraph = not(endOfBlock) *> element(
    elementCreateBlockParser(name: "p") *>
    contentLines >>- subBlock(elementBody)
) <* skipEmptyLines
