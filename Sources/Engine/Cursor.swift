//
// GainText parser
// Copyright Martin Waitz
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//

import Foundation

/// One line in the source document.
public struct Line {
    let start: Position
    let endIndex: String.Index
}

/// One logical block in the source document.
///
/// `Block` does not contain the source block itself,
/// but just remembers where all relevant lines are located in
/// the document.
///
/// `Block`s are only required while parsing the document
/// into a tree of `Node`s. They are releases as soon as
/// all `Cursor`s leave the `Block`.
public class Block: ObjectIdentity {
    let document: Document
    var lines: [Line]

    var cache: [CacheKey: CachedResult]

    init(document: Document, lines: [Line] = []) {
        self.document = document
        self.lines = lines
        self.cache = [:]
    }
}


/// A cursor which can be moved through the document.
///
/// Each `Cursor` moves through one logical block and can test for the end
/// of this block or move to the next logical line, without having to know
/// where it is located (e.g. in some table).
///
/// Each cursor also remembers the scope it is in.
public struct Cursor {
    public var position: Position
    public var scope: Scope
    public var element: Element?
    let block: Block
    fileprivate var lineIndex: Int
    fileprivate var startOfWord: Bool
    let level: Int

    init(at block: Block, scope: Scope, element: Element?, level: Int = 0) {
        self.block = block
        self.lineIndex = block.lines.startIndex
        self.position = Position(at: block)
        self.scope = scope
        self.startOfWord = true
        self.element = element
        self.level = level
    }
}

extension Cursor {
    init(block lines: [Line], parent cursor: Cursor) {
        let block = Block(document: cursor.document, lines: lines)
        self.init(at: block, scope: cursor.scope, element: cursor.element, level: cursor.level + 1)
    }
}

extension Cursor: Equatable{}
public func ==(lhs: Cursor, rhs: Cursor) -> Bool {
    return lhs.block == rhs.block
        && lhs.position == rhs.position
        && lhs.startOfWord == rhs.startOfWord
}

extension Cursor {
    public var document: Document {
        return block.document
    }

    public var source: String {
        return document.source
    }

    public var line: Line {
        return block.lines[lineIndex]
    }

    public var char: Character {
        return source.characters[position.index]
    }

    public var tail: String {
        return source.substring(with: position.index..<line.endIndex)
    }
    public func tailLine() -> Line {
        return Line(start: position, endIndex: line.endIndex)
    }
}

extension Cursor {
    public func head(from: Position) -> String {
        return source.substring(with: from.index..<position.index)
    }
}

extension Cursor {
    public mutating func advance(by count: Int) throws {
        for _ in 0..<count {
            try advance()
        }
    }

    public mutating func advance() throws {
        guard position.index != line.endIndex else {
            throw ParserError.endOfScope(position: position)
        }
        startOfWord = atWhitespace
        position = position.next()
    }

    public mutating func advanceLine() throws {
        guard !atEndOfBlock else {
            throw ParserError.endOfScope(position: position)
        }
        let lineEndIndex = line.endIndex
        lineIndex = block.lines.index(after: lineIndex)
        guard !atEndOfBlock else {
            // not a valid position any more
            // go to the last position of the last line
            while position.index != lineEndIndex {
                position = position.next()
            }
            return
        }
        position = line.start
        startOfWord = true
    }
}

extension Cursor {
    public var atEndOfLine: Bool {
        return position.index == line.endIndex
    }
    public var atEndOfBlock: Bool {
        return lineIndex == block.lines.endIndex
    }

    public var atWhitespace: Bool {
        guard !atEndOfBlock && !atEndOfLine else { return false }
        return isWhitespace(char: char)
    }

    public var atAlphaNumeric: Bool {
        guard !atEndOfBlock && !atEndOfLine else { return false }
        return isAlphaNumeric(char: char)
    }

    public func at(oneOf characters: String) -> Bool {
        guard !atEndOfBlock && !atEndOfLine else { return false }
        return characters.contains(String(char))
    }
    public func at(oneOf characters: Set<Character>) -> Bool {
        guard !atEndOfBlock && !atEndOfLine else { return false }
        return characters.contains(char)
    }

    public var atWhitespaceOnlyLine: Bool {
        if line.start.index == line.endIndex { return true }
        for c in tail.characters {
            if !isWhitespace(char: c) {
                return false
            }
        }
        return true
    }

    public func isWhitespace(char: Character) -> Bool {
        return char == " " || char == "\t"
    }

    public func isAlphaNumeric(char: Character) -> Bool {
        switch char {
        case "a"..."z": return true
        case "A"..."Z": return true
        case "0"..."9": return true
        default: return false
        }
    }
}

extension Cursor {
    public var atStartOfWord: Bool {
        return startOfWord && !atWhitespace
    }

    public mutating func markStartOfWord() {
        startOfWord = true
    }
}

extension Cursor {
    public mutating func skipWhitespace() {
        while atWhitespace {
            try! advance()
        }
    }

    public mutating func skipEmptyLines() {
        while !atEndOfBlock && atWhitespaceOnlyLine {
            try! advanceLine()
        }
    }
}
