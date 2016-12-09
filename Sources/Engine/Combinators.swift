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

public struct DisjunctiveParser: NodeParser {
    public init(list: [NodeParser]) {
        self.list = list
    }

    public func parse( _ cursor: Cursor) throws -> ([Node], Cursor) {
        for parser in list {
            do {
                //print("\(cursor.position): trying \(parser)")
                return try parser.parse(cursor)
            } catch {
                //print("\(cursor.position): error \(e)")
            }
        }
        throw ParserError.notFound(position: cursor.position)
    }

    let list: [NodeParser]
}

extension DisjunctiveParser: CustomStringConvertible {
    public var description: String {
        let descriptions = list.map { String(describing: $0) }
        return "(" + descriptions.joined(separator: " | ") + ")"
    }
}

public struct SequenceParser: NodeParser {
    public init(list: [NodeParser]) {
        self.list = list
    }

    public func parse(_ cursor: Cursor) throws -> ([Node], Cursor) {
        var cursor = cursor
        var content: [Node] = []
        for parser in list {
            let (nodes, nextCursor) = try parser.parse(cursor)
            content += nodes
            cursor = nextCursor
        }
        return (content, cursor)
    }

    let list: [NodeParser]
}

extension SequenceParser: CustomStringConvertible {
    public var description: String {
        let descriptions = list.map { String(describing: $0) }
        return descriptions.joined(separator: ", ")
    }
}


public class DeferredParser: NodeParser {
    public func resolve(_ delegate: NodeParser) {
        self.delegate = delegate
    }

    public func parse(_ cursor: Cursor) throws -> ([Node], Cursor) {
        return try delegate!.parse(cursor)
    }

    var delegate: NodeParser?
}

extension DeferredParser: CustomStringConvertible {
    public var description: String {
        return "(deferred)"
    }
}

public func <^> <From, To>(lhs: @escaping (From) throws -> To, rhs: Parser<From>) -> Parser<To> {
    return rhs.map(lhs)
}

func <*> <From, To>(lhs: Parser<(From)->To>, rhs: Parser<From>) -> Parser<To> {
    return lhs >>- { $0 <^> rhs }
}

func <* <Left, Right>(_ lhs: Parser<Left>, _ rhs: Parser<Right>) -> Parser<Left> {
    return Parser { input in
        let (result, rhsInput) = try lhs.parse(input)
        let (_, tail) = try rhs.parse(rhsInput)
        return (result, tail)
    }
}
func *> <Left, Right>(_ lhs: Parser<Left>, _ rhs: Parser<Right>) -> Parser<Right> {
    return Parser { input in
        let (_, rhsInput) = try lhs.parse(input)
        let (result, tail) = try rhs.parse(rhsInput)
        return (result, tail)
    }
}

func <|> <Result>(_ lhs: Parser<Result>, _ rhs: Parser<Result>) -> Parser<Result> {
    return Parser { input in
        do {
            return try lhs.parse(input)
        } catch is ParserError {
            return try rhs.parse(input)
        }
    }
}

public func >>- <R1, R2>(lhs: Parser<R1>, rhs: @escaping (R1) -> Parser<R2>) -> Parser<R2> {
    return Parser { input in
        let (param, rhsInput) = try lhs.parse(input)
        return try rhs(param).parse(rhsInput)
    }
}

public func -<< <R1, R2>(lhs: @escaping (R1) -> Parser<R2>, rhs: Parser<R1>) -> Parser<R2> {
    return Parser { input in
        let (param, lhsInput) = try rhs.parse(input)
        return try lhs(param).parse(lhsInput)
    }
}

infix operator <+>: RunesApplicativeSequencePrecedence
func <+> <Element>(_ lhs: Parser<[Element]>, _ rhs: Parser<[Element]>) -> Parser<([Element])> {
    return Parser { input in
        let (lhsResult, rhsInput) = try lhs.parse(input)
        let (rhsResult, tail) = try rhs.parse(rhsInput)
        return (lhsResult + rhsResult, tail)
    }
}

extension Parser {
    func map<Mapped>(_ f: @escaping (Result) throws -> Mapped) -> Parser<Mapped> {
        return Parser<Mapped> { input in
            let (result, tail) = try self.parse(input)
            return (try f(result), tail)
        }
    }
}

public func lookahead<R>(_ p: Parser<R>) -> Parser<R> {
    return Parser { input in
        let (result, _) = try p.parse(input)
        return (result, input)
    }
}

public func optional<Result>(_ p: Parser<Result>, otherwise: Result) -> Parser<Result> {
    return Parser { input in
        do {
            return try p.parse(input)
        } catch is ParserError {
            return (otherwise, input)
        }
    }
}
public func optional<Result>(_ p: Parser<Result>) -> Parser<Result?> {
    return Parser { input in
        do {
            let (result, tail) = try p.parse(input)
            return (result, tail)
        } catch is ParserError {
            return (nil, input)
        }
    }
}

public func lazy<Result>(_ p: @autoclosure @escaping () -> Parser<Result>) -> Parser<Result> {
    return Parser { input in
        try p().parse(input)
    }
}
