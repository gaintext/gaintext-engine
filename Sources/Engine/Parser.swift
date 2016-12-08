//
// GainText parser
// Copyright Martin Waitz
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//


/// Parser returning a `Result`.
public struct Parser<Result> {
    /// Parse the input at the specified position.
    /// - returns: the parsed result and the next position.
    /// - throws: an `ParserError` if there was no match.
    public let parse: (Cursor) throws -> (Result, Cursor)
}

/// Protocol to parse a part of the document and turn it into nodes
public protocol NodeParser {
    /// Parse a document and parse nodes
    /// - Parameter cursor: where to start
    /// - Returns: parsed nodes and new cursor for further parsing
    func parse(_ cursor: Cursor) throws -> ([Node], Cursor)
}
