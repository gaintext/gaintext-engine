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

precedencegroup AdditiveParserPrecedence {
    associativity: left
    higherThan: RunesAlternativePrecedence
    lowerThan: RunesApplicativePrecedence
}


public func <^> <From, To>(lhs: @escaping (From) throws -> To, rhs: Parser<From>) -> Parser<To> {
    return rhs.map(lhs)
}

public func <*> <From, To>(lhs: Parser<(From)->To>, rhs: Parser<From>) -> Parser<To> {
    return lhs >>- { $0 <^> rhs }
}

public func <* <Left, Right>(_ lhs: Parser<Left>, _ rhs: Parser<Right>) -> Parser<Left> {
    return Parser { input in
        let (result, rhsInput) = try lhs.parse(input)
        let (_, tail) = try rhs.parse(rhsInput)
        return (result, tail)
    }
}
public func *> <Left, Right>(_ lhs: Parser<Left>, _ rhs: Parser<Right>) -> Parser<Right> {
    return Parser { input in
        let (_, rhsInput) = try lhs.parse(input)
        let (result, tail) = try rhs.parse(rhsInput)
        return (result, tail)
    }
}

public func <|> <Result>(_ lhs: Parser<Result>, _ rhs: Parser<Result>) -> Parser<Result> {
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

public func >-> <A, B, C>(lhs: @escaping (A)->Parser<B>, rhs: @escaping (B)->Parser<C>) -> (A) -> Parser<C> {
    return { a in
        lhs(a) >>- rhs
    }
}

infix operator <+>: AdditiveParserPrecedence
public func <+>(_ lhs: Parser<String>, _ rhs: Parser<String>) -> Parser<String> {
    return Parser { input in
        let (lhsResult, rhsInput) = try lhs.parse(input)
        let (rhsResult, tail) = try rhs.parse(rhsInput)
        return (lhsResult + rhsResult, tail)
    }
}
public func <+> <Element>(_ lhs: Parser<[Element]>, _ rhs: Parser<[Element]>) -> Parser<[Element]> {
    return Parser { input in
        let (lhsResult, rhsInput) = try lhs.parse(input)
        let (rhsResult, tail) = try rhs.parse(rhsInput)
        return (lhsResult + rhsResult, tail)
    }
}

extension Parser {
    public func map<Mapped>(_ f: @escaping (Result) throws -> Mapped?) -> Parser<Mapped> {
        return Parser<Mapped> { input in
            let (result, tail) = try self.parse(input)
            guard let mapped = try f(result) else { throw ParserError.notFound(position: input.position) }
            return (mapped, tail)
        }
    }
}

public func lookahead<R>(_ p: Parser<R>) -> Parser<R> {
    return Parser { input in
        let (result, _) = try p.parse(input)
        return (result, input)
    }
}

public func not<R>(_ p: Parser<R>) -> Parser<()> {
    return Parser { input in
        do {
            let _ = try p.parse(input)
        } catch is ParserError {
            return ((), input)
        }
        throw ParserError.notFound(position: input.position)
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
public func optional<Result>(_ p: Parser<Result>, otherwise: Result) -> Parser<Result> {
    return p <|> pure(otherwise)
}
public func optional(_ p: Parser<()>) -> Parser<()> {
    return p <|> pure(())
}

public func lazy<Result>(_ p: @escaping @autoclosure () -> Parser<Result>) -> Parser<Result> {
    return Parser { input in
        try p().parse(input)
    }
}

public func list<Result>(first: Parser<[Result]>, following: Parser<[Result]>) -> Parser<[Result]> {
    return Parser { input in
        guard !input.atEndOfBlock else {
            throw ParserError.endOfScope(position: input.position)
        }
        var (result, tail) = try first.parse(input)
        while true {
            do {
                guard !tail.atEndOfBlock else {
                    throw ParserError.endOfScope(position: tail.position)
                }
                let (item, next) = try following.parse(tail)
                tail = next
                result += item
            } catch is ParserError {
                return (result, tail)
            }
        }
    }
}

public func list<Result, Sep>(_ parser: Parser<[Result]>, separator: Parser<Sep>) -> Parser<[Result]> {
    return list(first: parser, following: separator *> parser)
}
public func list<Result>(_ parser: Parser<[Result]>) -> Parser<[Result]> {
    return list(first: parser, following: parser)
}
