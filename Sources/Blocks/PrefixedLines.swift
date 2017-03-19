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


/// Parser for prefixed lines
///
/// Returns the rest of the current line plus all following
/// lines which are prefixed by the given string.
func prefixedLines(prefix: String) -> Parser<[Line]> {
    assert(!prefix.isEmpty)
    let count = prefix.characters.count
    return Parser { input in
        var cursor = input
        var lines: [Line] = []
        var tentative: [Line] = []
        if !cursor.atWhitespaceOnlyLine {
            lines.append(cursor.tailLine())
        }
        try! cursor.advanceLine()
        var nextCursor = cursor
        while !cursor.atEndOfBlock {
            if cursor.atWhitespaceOnlyLine {
                // only use this line if other indented content follows
                tentative.append(cursor.line)
                try! cursor.advanceLine()
                continue
            }
            guard cursor.tail.hasPrefix(prefix) else { break }
            try! cursor.advance(by: count)
            let line = cursor.tailLine()
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
