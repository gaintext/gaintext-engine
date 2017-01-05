//
// GainText parser
// Copyright Martin Waitz
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//

/// Key to identify parser results.
struct CacheKey {
    let cache: ObjectIdentifier
    let position: Position
    let startOfWord: Bool
}
extension CacheKey: Hashable {
    var hashValue: Int {
        return cache.hashValue ^ position.hashValue
    }
    static func ==(lhs: CacheKey, rhs: CacheKey) -> Bool {
        return lhs.position == rhs.position
            && lhs.cache == rhs.cache
            && lhs.startOfWord == rhs.startOfWord
    }
}

/// Stored parser result.
enum CachedResult {
    case cached(nodes: [Node], cursor: Cursor)
    case error(error: ParserError)
}

private class Wrapper {
    let parser: Parser<[Node]>
    init(_ parser: Parser<[Node]>) { self.parser = parser }
    var id: ObjectIdentifier { return ObjectIdentifier(self) }
}

/// Cache the result of a delegate parser.
/// Any further `parse` calls will return the exact same result.
public func cached(_ parser: Parser<[Node]>) -> Parser<[Node]> {
    let wrapper = Wrapper(parser)
    return Parser { input in
        let key = CacheKey(cache: wrapper.id,
                           position: input.position,
                           startOfWord: input.atStartOfWord)
        let scope = input.block

        if let found = scope.cache[key] {
            switch found {
            case .cached(let nodes, let cursor):
                return (nodes, cursor)
            case .error(let error):
                throw error
            }
        }
        do {
            let (nodes, cursor) = try wrapper.parser.parse(input)
            scope.cache[key] = .cached(nodes: nodes, cursor: cursor)
            return (nodes, cursor)
        } catch let error as ParserError {
            scope.cache[key] = .error(error: error)
            throw error
        }
    }
}
public class CachedParser: NodeParser {
    public init(_ delegate: NodeParser) {
        self.delegate = delegate
    }

    public func parse(_ cursor: Cursor) throws -> ([Node], Cursor) {
        let key = CacheKey(cache: ObjectIdentifier(self),
                              position: cursor.position,
                              startOfWord: cursor.atStartOfWord)
        let scope = cursor.block

        if let found = scope.cache[key] {
            switch found {
            case .cached(let nodes, let cursor):
                return (nodes, cursor)
            case .error(let error):
                throw error
            }
        }
        do {
            let (nodes, cursor) = try delegate.parse(cursor)
            scope.cache[key] = .cached(nodes: nodes, cursor: cursor)
            return (nodes, cursor)
        } catch let error as ParserError {
            scope.cache[key] = .error(error: error)
            throw error
        }
    }

    let delegate: NodeParser
}

extension CachedParser: CustomStringConvertible {
    public var description: String {
        return String(describing: delegate)
    }
}
