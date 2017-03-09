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

private let eolError = errorMarker("cannot escape end-of-line")

/// Recognize a backslash escaped character as `raw` Element.
/// Backslash at the end of the line is regarded as an error.
public var escaped: Parser<[Node]> = element(
    literal("\\") *>
    elementCreateMarkupParser(name: "raw") *>
    elementContent(textNode(spanning: character) <|> eolError)
)
