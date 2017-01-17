//
// GainText parser
// Copyright Martin Waitz
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//

@testable import Engine
import Nimble

/// reports any exceptions which are thrown
func report<T>(_ f: @autoclosure () throws -> T, file: FileString = #file, line: UInt = #line) rethrows -> T {
    do {
        return try f()
    } catch(let e) {
        fail("unexpected error: \(e)", file: file, line: line)
        throw e
    }
}

func parse(_ r: NodeParser, _ cursor: Cursor, file: FileString = #file, line: UInt = #line) throws -> ([Node], Cursor) {
    return try report(try r.parse(cursor), file: file, line: line)
}
func parse(_ r: NodeParser, _ doc: Document, file: FileString = #file, line: UInt = #line) throws -> ([Node], Cursor) {
    return try report(try r.parse(doc.start()), file: file, line: line)
}

func parse<Result>(_ p: Parser<Result>, _ input: Cursor, file: FileString = #file, line: UInt = #line) throws -> (Result, Cursor) {
    return try report(try p.parse(input), file: file, line: line)
}
func parse<Result>(_ p: Parser<Result>, _ doc: Document, file: FileString = #file, line: UInt = #line) throws -> (Result, Cursor) {
    return try report(try p.parse(doc.start()), file: file, line: line)
}


