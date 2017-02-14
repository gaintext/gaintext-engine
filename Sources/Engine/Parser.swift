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
    public init(parse: @escaping (Cursor) throws -> (Result, Cursor)) {
        self.parse = parse
    }
}

/// A parser for an embedded span, parameterized by an endMarker parser.
public typealias SpanParser = (Parser<()>) -> Parser<[Node]>
