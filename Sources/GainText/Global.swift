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
import Markup
import Generator
import Runes

private let blockParser = list(
    listParser <|> titledContent <|> elementBlockParser <|> lineDelimitedContent <|>
    quotedBlock <|> paragraph,
    separator: skipEmptyLines
)


private let spanParser = textWithMarkupParser(markup: cached(
    escaped <|> htmlEntity <|> spanWithBrackets <|> spanWithDelimiters
))


private func registerElements(global scope: Scope) {
    let blockElements = [
//        ImportElementType(),
//        DefinitionElementType(),
        ElementType("p", body: list(textLine)),
        ElementType("section"),
        ElementType("example"),
        ElementType("math-block"),
        ElementType("blockquote"),
        elementLI,
        elementUL,
        ElementType("table"),
        ElementType("TBD"),
        ElementType("code-block", body: list(codeLine))
    ]
    for element in blockElements {
        scope.register(block: element)
    }
    scope.register(block: "code-block", alias: "block:`")
    scope.register(block: "math-block", alias: "block:$")

    let markupElements = [
        ElementType("TBD"),
        ElementType("em"),
        ElementType("math"),
        ElementType("code", title: rawTextParser),
        ElementType("raw", title: rawTextParser)
    ]
    for element in markupElements {
        scope.register(markup: element)
    }
    scope.register(markup: "em", alias: "span:*")
    scope.register(markup: "em", alias: "span:_")
    scope.register(markup: "code", alias: "span:`")
    scope.register(markup: "math", alias: "span:$")
    scope.register(markup: "raw", alias: "span:~")
}

extension Document {

    /// Create a Document from some source.
    ///
    /// The global scope will already be initialized for GainText parsing.
    public convenience init(source: String) {
        let scope = Scope(blockRegistry: ElementRegistry(),
                          markupRegistry: ElementRegistry(),
                          blockParser: blockParser,
                          spanParser: spanParser)
        registerElements(global: scope)

        self.init(source: source, global: scope)
    }
}
