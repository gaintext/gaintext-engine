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

// Attributes are always encoded with three nodes:
// * one "attribute" Node acting as parent for the following
// * one "attribute-key" Node with a "name" NodeAttribute
// * one "attribute-value" Node with a "value" NodeAttribute
private let attrNodeType = NodeType(name: "attribute")
private let attrKeyType = NodeType(name: "attribute-key")
private let attrValueType = NodeType(name: "attribute-value")


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
    return node(attrNodeType, content: p)
}

public var attributes: Parser<[Node]> {
    return list(attribute, separator: whitespace)
}


// TBD: endMarker can be swallowed by attribute: {a=b} tries to assign b} to a
// First determine what is part of the attribute definition
// (until endMarker, but allow quoted strings with arbitrary content)
public var attributesParser = textWithMarkupParser(
    markup: optional(whitespace) *> attribute
)


