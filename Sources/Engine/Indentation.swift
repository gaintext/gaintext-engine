//
// GainText parser
// Copyright Martin Waitz
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//

infix operator <*>

public func <*> <R1, R2>(lhs: Parser<R1>, rhs: @escaping (R1) -> Parser<R2>) -> Parser<R2> {
    return Parser { cursor in
        let (lhsResult, lhsTail) = try lhs.parse(cursor)
        return try rhs(lhsResult).parse(lhsTail)
    }
}

public func lookup<R>(_ p: Parser<R>) -> Parser<R> {
    return Parser { cursor in
        let (result, _) = try p.parse(cursor)
        return (result, cursor)
    }
}

private func detectIndentationParser() -> Parser<String> {
    return Parser { cursor in
        var cursor = cursor
        let start = cursor.position
        while cursor.atWhitespace {
            try! cursor.advance()
        }
        guard cursor.position != start else {
            throw ParserError.notFound(position: start)
        }
        return (cursor.head(from: start), cursor)
    }
}

func indentedBlockParser(prefix: String) -> Parser<[Line]> {
    assert(!prefix.isEmpty)
    return Parser { cursor in
        var outerCursor = cursor
        var nextCursor = outerCursor
        var lines: [Line] = []
        var tentative: [Line] = []
        while !outerCursor.atEndOfBlock {
            if outerCursor.atWhitespaceOnlyLine {
                // only use this line if other indented content follows
                tentative.append(outerCursor.line)
                try! outerCursor.advanceLine()
                continue
            }
            guard outerCursor.tail.hasPrefix(prefix) else { break }
            try! outerCursor.advance(by: prefix.characters.count)
            let line = Line(start: outerCursor.position, endIndex: outerCursor.line.endIndex)
            if !tentative.isEmpty {
                lines.append(contentsOf: tentative)
                tentative = []
            }
            lines.append(line)
            try! outerCursor.advanceLine()
            nextCursor = outerCursor
        }
        return (lines, nextCursor)
    }
}

public func indentationParser(prefix: String? = nil) -> Parser<[Line]> {
    if let prefix = prefix {
        return indentedBlockParser(prefix: prefix)
    } else {
        return lookup(detectIndentationParser()) <*> indentedBlockParser
    }
}
