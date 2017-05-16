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
    case "code-block":
        let code = HTMLElement(tagName: "code")
        let pre = HTMLElement(tagName: "pre")
        element.append(pre)
        pre.append(code)
        generateHTML(for: node.children, to: code)
    case "define":
        break
    case "import":
        break
    case "section":
        let section = HTMLElement(tagName: "section")
        element.append(section)
        for child in node.children {
            if child.nodeType.name == "gaintext-title" {
                let title = HTMLElement(tagName: "h1")
                section.append(title)
                generateHTML(for: child.children, to: title)

            } else {
                generateHTML(for: child, to: section)
            }
        }
    case "line", "gaintext-title":
        generateHTML(for: node.children, to: element)
        element.append(HTMLText(data: "\n"))
    case "text":
        element.append(HTMLText(data: node.sourceContent))
    case "html":
        let parser = HTMLParser(string: node.sourceContent)
        element.append(parser.parseFragment(withContextElement: element))
    default:
        let new = HTMLElement(tagName: node.nodeType.name)
        element.append(new)
        generateHTML(for: node.children, to: new)
    }
}

func generateHTML(for nodes: [Node], to element: HTMLElement) {
    for child in nodes {
        generateHTML(for: child, to: element)
    }
}
