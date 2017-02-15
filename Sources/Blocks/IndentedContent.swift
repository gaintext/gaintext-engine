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


/// Parser for one element with indented content.
///
/// Consumes the title line and any following indented lines.
/// The indented part will be parsed as a new block containing the
/// content of the new element.
public let elementWithIndentedContent = element(
    elementStartBlockParser *> elementTitleLine *>
    endOfLine *>
    optional(indentationParser >>- subBlock(elementBody))
)

/// Parser producing an error node spanning the whole line.
private let errorNoElement = errorLine(errorType: ErrorNodeType("no element"))

/// Parser for a block of adjacent elements.
/// An error is generated for any lines with unrecognized elements.
public let elementBlockParser =
    list(first: elementWithIndentedContent,
         following: satisfying {!$0.atEndOfBlock && !$0.atWhitespaceOnlyLine} *>
            (elementWithIndentedContent <|> errorNoElement))
    <*
    skipEmptyLines
