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
import Blocks
import Elements


let blockCode = ElementType("code-block", body:
    list(codeLine)
)

let blockExample = ElementType("example")

let blockLI = ElementType("li")

let blockMath = ElementType("math-block")

let blockP = ElementType("p", body:
    list(textLine)
)

let blockQuote = ElementType("blockquote")

let blockSection = ElementType("section")

let blockTable = ElementType("table")

let blockTBD = ElementType("TBD")

let blockUL = ElementType("ul", body:
    list(listItem, separator: skipEmptyLines)
)


/// All standard block elements
let blockElements = [
    blockCode,
    blockExample,
    blockLI,
    blockMath,
    blockP,
    blockQuote,
    blockSection,
    blockTable,
    blockTBD,
    blockUL,

    DefinitionElementType(),
]
