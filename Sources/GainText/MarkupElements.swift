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
import Markup


let markupElements = [
    ElementType("TBD"),
    ElementType("em"),
    ElementType("math"),
    ElementType("code", title: rawTextParser),
    ElementType("raw", title: rawTextParser)
]
