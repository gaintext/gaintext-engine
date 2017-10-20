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
    for element in blockElements {
        scope.register(block: element)
    }
    scope.register(block: "code-block", alias: "block:`")
    scope.register(block: "math-block", alias: "block:$")

    for element in markupElements {
        scope.register(markup: element)
    }
    scope.register(markup: "em", alias: "span:*")
    scope.register(markup: "em", alias: "span:_")
    scope.register(markup: "code", alias: "span:`")
    scope.register(markup: "math", alias: "span:$")
    scope.register(markup: "raw", alias: "span:~")
}

func globalScope() -> Scope {
    let scope = Scope(blockRegistry: ElementRegistry(),
                      markupRegistry: ElementRegistry(),
                      blockParser: blockParser,
                      spanParser: spanParser)
    registerElements(global: scope)

    return scope
}

extension DocumentLoaderDelegate {

    public func loadRoot(fromFile name: String) throws -> Document {
        return try load(fromFile: name, scope: globalScope())
    }
}

// for testing only
struct SimpleDocumentLoader: DocumentLoaderDelegate {
    enum LoaderError: Error {
        case notFound
    }
    public func load(fromFile name: String, scope: Scope) throws -> Document {
        if let source = documents[name] {
            return Document(source: source, global: scope, loader: self)
        }
        throw LoaderError.notFound
    }
    let documents: [String: String]
}
/// Create a simple GainText document.
///
/// This is mainly for testing.
/// The document source and any external sources have to be
/// specified as Strings.
public func simpleDocument(_ source: String, external documents: [String: String] = [:]) -> Document {
    let loader = SimpleDocumentLoader(documents: documents)
    return Document(source: source, global: globalScope(), loader: loader)
}
