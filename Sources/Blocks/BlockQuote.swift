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


private let prefix = literal("> ")

private let quotedBlockLines = prefix >>- prefixedLines

/// Parser for quoted block
///
/// Matches all lines starting with "> " and puts them into
/// one "quoted-block" element.
public let quotedBlock = lookahead(prefix) *> element(
    elementCreateBlockParser(name: "blockquote") *>
    quotedBlockLines >>- subBlock(elementBody)
) <* skipEmptyLines
