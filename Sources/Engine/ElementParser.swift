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


public func elementCreateBlockParser(name: String) -> Parser<()> {
    return Parser { input in
        let scope = input.scope
        assert(scope.element == nil)

        guard let element = scope.block(name: name) else {
            throw ParserError.notFound(position: input.position)
        }
        scope.element = element

        return ((), input)
    }
}

public func elementCreateMarkupParser(name: String) -> Parser<()> {
    return Parser { input in
        let scope = input.scope
        assert(scope.element == nil)

        guard let element = scope.markup(name: name) else {
            throw ParserError.notFound(position: input.position)
        }
        scope.element = element

        return ((), input)
    }
}

private let attributesFollowedByColon = elementContent(attributesParser(literal(":")*>pure(())))

/// Parser for the start of a markup element definition
///
/// Consumes the element name, optional attributes and the colon (`:`).
/// Creates a corresponding element in the current scope.
public let elementStartBlockParser = (identifier >>- elementCreateBlockParser) *>
    attributesFollowedByColon <* optional(whitespace)

/// Parser for the start of a markup element definition
///
/// Consumes the element name, optional attributes and the colon (`:`).
/// Creates a corresponding element in the current scope.
public let elementStartMarkupParser = (identifier >>- elementCreateMarkupParser) *>
    attributesFollowedByColon <* optional(whitespace)

/// Parser adding the specified attribute to the currently parsed element.
public func elementAttribute(_ attr: NodeAttribute) -> Parser<()> {
    return Parser { input in
        let element = input.scope.element!
        element.attributes.append(attr)
        return ((), input)
    }
}

/// Makes a parser store its result as the current element's title.
public func elementTitle(_ p: Parser<[Node]>) -> Parser<()> {
    return Parser { input in
        let element = input.scope.element!
        let (content, tail) = try p.parse(input)
        element.title += content
        return ((), tail)
    }
}
private let atEndOfLine = satisfying {$0.atEndOfLine}
private let titleNodeType = ElementNodeType(name: "title")
private let titleNode = node(type: titleNodeType) <^> (elementTitleParser <*> pure(atEndOfLine))
public let elementTitleLine = titleNode >>- elementTitle

/// Makes a parser store its result in the current element's body.
public func elementContent(_ p: Parser<[Node]>) -> Parser<()> {
    return Parser { input in
        let element = input.scope.element!
        let (content, tail) = try p.parse(input)
        element.body += content
        return ((), tail)
    }
}

public let elementBody = elementBodyParser >>- elementContent

public func elementSpanBody(until endMarker: Parser<()>) -> Parser<()> {
    return elementTitleParser <*> pure(endMarker) >>- elementTitle
}
public func elementSpanBody(until endMarker: Parser<String>) -> Parser<()> {
    return elementSpanBody(until: endMarker *> pure(()))
}

/// Apply a parser to some sub-block.
public func subBlock<Result>(_ p: Parser<Result>) -> ([Line]) -> Parser<Result> {
    return { lines in
        Parser<Result> { outside in
            let element = outside.scope.element!
            let inside = element.childCursor(block: lines, parent: outside)
            let (result, tail) = try p.parse(inside)
            // content parser has to consume the complete block
            assert(tail.atEndOfBlock)
            return (result, outside)
        }
    }
}

/// Create a node from the current element.
func elementNodeParser(_ p: Parser<()>) -> Parser<[Node]> {
    return Parser { input in
        let start = input.position
        let scope = input.scope
        assert(scope.element == nil)

        let (_, tail) = try p.parse(input)

        assert(scope.element != nil) // TBD: assert or guard?
        guard let element = scope.element else {
            throw ParserError.notFound(position: input.position)
        }
        let node = element.createNode(start: start, end: tail)

        return ([node], tail)
    }
}

/// Executes a parser in a separate child scope
func newScopeParser<Result>(_ p: Parser<Result>) -> Parser<Result> {
    return Parser { input in
        let scope = input.scope
        var cursor = input
        cursor.scope = Scope(parent: scope)
        cursor.scope.element = nil
        var (result, tail) = try p.parse(cursor)
        tail.scope = scope
        return (result, tail)
    }
}

public func element(_ p: Parser<()>) -> Parser<[Node]> {
    return newScopeParser(elementNodeParser(p))
}
