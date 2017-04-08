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

private func atEndOfParagraph(_ input: Cursor) -> Bool {
    if input.atEndOfBlock || input.atEndOfLine { return true }
    if input.atWhitespace { return true }
    // TBD: don't hardcode the start of lists here?!
    if literal("- ").matches(input) { return true }
    if literal("* ").matches(input) { return true }
    return false
}

private let contentLines = Parser<[Line]> { input in
    var cursor = input
    var lines: [Line] = []
    guard !cursor.atEndOfBlock && !cursor.atEndOfLine else {
        return ([], input)
    }
    // first line
    lines.append(cursor.line)
    try! cursor.advanceLine()
    // append all further lines
    while !atEndOfParagraph(cursor) {
        if atEndOfParagraph(cursor) { break }
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
