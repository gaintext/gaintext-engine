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
import HTMLKit


extension Document {
    public func parseHTML() -> HTMLDocument {

        let nodes = parse()

        let html = HTMLDocument(string: "<!DOCTYPE html><meta charset=\"utf-8\">")
        for node in nodes {
            generateHTML(for: node, to: html.body!)
        }

        return html
    }
}

func getAttribute(for node: Node) -> (String, String) {
    assert(node.children.count == 2)
    assert(node.children[0].nodeType.name == "attribute-key")
    assert(node.children[1].nodeType.name == "attribute-value")
    guard let key = node.children[0].attributes["name"] else {
        assert(false)
    }
    guard let value = node.children[1].attributes["value"] else {
        assert(false)
    }
    return (key, value)
}

/// Create the HTML equivalent for the specified node.
func generateHTML(for node: Node, to element: HTMLElement) {
    if let errorType = node.nodeType as? ErrorNodeType {
        let error = HTMLElement(tagName: "parse-error")
        error.append(HTMLText(data: errorType.describe(node)))
        element.append(error)
    }
    switch node.nodeType.name {
    case "attribute":
        var (attr, value) = getAttribute(for: node)
        if attr == "class", let orig = element[attr] {
            value = orig + " " + value
        }
        element[attr] = value
    case "attribute-key", "attribute-value":
        break
    case "text":
        element.append(HTMLText(data: node.sourceContent))
    case "line":
        for child in node.children {
            generateHTML(for: child, to: element)
        }
        let newline = HTMLText(data: "\n")
        element.append(newline)
    default:
        let new = HTMLElement(tagName: node.nodeType.name)
        element.append(new)

        for child in node.children {
            generateHTML(for: child, to: new)
        }
    }
}
