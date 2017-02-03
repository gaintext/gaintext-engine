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


func detectSectionStart(underlineChars: String = "=-~_+'\"") -> Parser<Character> {
    return Parser { input in
        var cursor = input
        guard !cursor.atEndOfBlock else { throw ParserError.notFound(position: input.position) }
        guard !cursor.atWhitespaceOnlyLine else { throw ParserError.notFound(position: input.position) }
        try! cursor.advanceLine()
        guard !cursor.atEndOfBlock else { throw ParserError.notFound(position: input.position) }

        // check that second line only contains the underline
        let c = cursor.char
        guard underlineChars.characters.contains(c) else {
            throw ParserError.notFound(position: input.position)
        }
        var count = 1
        try! cursor.advance()
        while !cursor.atEndOfLine {
            if cursor.atWhitespace { continue }
            guard cursor.char == c else {
                throw ParserError.notFound(position: input.position)
            }
            count += 1
            try! cursor.advance()
        }
        guard count >= 3 else {
            throw ParserError.notFound(position: input.position)
        }

        try! cursor.advanceLine()
        if !cursor.atEndOfBlock {
            guard cursor.atWhitespaceOnlyLine else {
                throw ParserError.notFound(position: input.position)
            }
            try! cursor.advanceLine()
        }

        return (c, cursor)
    }
}

/// Parser which creates the element instance.
///
/// If available, it consumes the element specification (up to the colon)
/// and creates a corresponding element.
/// Otherwise, it creates a default 'section' element.
private let namedElementOrSection =
    (elementStartNameParser <|> pure("section")) >>- elementCreateBlockParser

/// Parser which produces a list of lines which belong to the content.
private func contentLines(level: Character) -> Parser<[Line]> {
    let nextSection = detectSectionStart(underlineChars: String(level))
    return Parser { input in
        var cursor = input
        var lines: [Line] = []
        while !cursor.atEndOfBlock {
            do {
                _ = try nextSection.parse(cursor)
                break
            } catch is ParserError {}
            lines.append(cursor.line)
            try! cursor.advanceLine()
        }
        return (lines, cursor)
    }
}

/// Parses all lines up to the start of the next section as one block.
private func content(underline: Character) -> Parser<()> {
    return satisfying {$0.atEndOfBlock} <|> (
        emptyLine *>
        contentLines(level: underline) >>- subBlock(elementBody)
    )
}

/// Parser for a section of titled content.
///
/// Matches the title line which has to be followed by underline characters.
/// All following lines up to another such title line are parsed as content.
public let titledContent = lookahead(detectSectionStart()) >>- { underline in
    element(
        namedElementOrSection *> elementTitleLine *> endOfLine *>
        advanceLine *> // line with underline characters
        elementAttribute(.text("underline", String(underline))) *>
        content(underline: underline)
    )
}
