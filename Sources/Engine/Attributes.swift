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


private var attributeKV: Parser<[Node]> {
    let key = identifier
    let value = quotedString <|> identifier

    return node(type: attrKeyType, attr: "name", key)
        <* literal("=")
        <+> node(type: attrValueType, attr: "value", value)
}
private var attributeID: Parser<[Node]> {
    return node(type: attrKeyType, attr: "name", literal("#") *> pure("id"))
       <+> node(type: attrValueType, attr: "value", identifier)
}
private var attributeClass: Parser<[Node]> {
    return node(type: attrKeyType, attr: "name", literal(".") *> pure("class"))
        <+> node(type: attrValueType, attr: "value", identifier)
}
private var attribute: Parser<[Node]> {
    let p = attributeID <|> attributeClass <|> attributeKV
    return node(type: attrNodeType, p)
}

private var attributes: Parser<[Node]> {
    return list(attribute, separator: whitespace)
}

private let attrNodeType = ElementNodeType(name: "attribute")
private let attrKeyType = ElementNodeType(name: "attribute-key")
private let attrValueType = ElementNodeType(name: "attribute-value")


// TBD: endMarker can be swallowed by attribute: {a=b} tries to assign b} to a
// First determine what is part of the attribute definition
// (until endMarker, but allow quoted strings with arbitrary content)
public var attributesParser = textWithMarkupParser(
    markup: optional(whitespace) *> attribute
)


