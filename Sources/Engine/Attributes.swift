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
import HTMLKit


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

/// Special type for attribute nodes.
///
/// When generating HTML no new node is created but
/// the attribute is directly stored in the parent element.
class AttributeNodeType: NodeType {
    let name = "attribute"
    func generate(_ node: Node, parent element: HTMLElement) {
        assert(node.children.count == 2)
        guard case let .text(_, attr) = node.children[0].attributes[0] else {
            assert(false)
        }
        guard case var .text(_, value) = node.children[1].attributes[0] else {
            assert(false)
        }

        if attr == "class", let orig = element[attr] {
            value = orig + " " + value
        }
        element[attr] = value
    }
}

/// Special type for keys and values of attributes.
class AttributeFragmentType: NodeType {
    var name: String
    init(name: String) { self.name = name }
    func generate(_ node: Node, parent: HTMLElement) {
        // nothing to do, everything is handled by AttributeNodeType
    }
}

private let attrNodeType = AttributeNodeType()
private let attrKeyType = AttributeFragmentType(name: "attribute-key")
private let attrValueType = AttributeFragmentType(name: "attribute-value")


// TBD: endMarker can be swallowed by attribute: {a=b} tries to assign b} to a
// First determine what is part of the attribute definition
// (until endMarker, but allow quoted strings with arbitrary content)
public var attributesParser = textWithMarkupParser(
    markup: optional(whitespace) *> attribute
)


