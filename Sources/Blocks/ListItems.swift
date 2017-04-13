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


private let prefix = oneOf("-*•◦") <+> whitespace

private let contentLines = prefix *> prefixedLines(prefix: "  ")

/// Parser for one single list item.
///
/// Consumes one line with a list item prefix (-,*,•,◦)
/// and all following indented lines.
public let listItem = lookahead(prefix) *> element(
    elementCreateBlockParser(name: "li") *>
        contentLines >>- subBlock(elementBody)
)

private func possiblyIndented<T>(_ p: Parser<T>) -> Parser<T> {
    return (whitespace >>- prefixedLines >>- subBlock(p)) <|> p
}

private let listTrigger = lookahead(optional(whitespace) *> prefix)

/// Parser for a list
public let listParser = listTrigger *> element(
    elementCreateBlockParser(name: "ul") *>
    possiblyIndented(elementBody)
) <* skipEmptyLines

public let elementUL = ElementType("ul", body: list(listItem, separator: skipEmptyLines))
public let elementLI = ElementType("li")
