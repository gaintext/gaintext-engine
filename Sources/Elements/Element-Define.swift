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


private let parameterType = ElementType("param")

/// Definition of new Elements.
class DefinitionElement: Element {

    override func finish(_ node: Node) {
        guard title.count > 0 else {
            // TBD: throw?
            fatalError("error: nothing to define")
        }
        let name = String(title[0].sourceContent)

        let customType = CustomElementType(name, template: body)
        scope.register(block: customType)
    }
}

/// Type definition for the elment 'define'.
///
/// Uses our own `DefinitionElement` class for parsing,
/// which is responsible to register a `CustomElementType`
/// for each newly defined element.
public class DefinitionElementType: ElementType {
    public init() {
        var template = ScopeTemplate()
        template.block["param"] = parameterType
        super.init(
            "define",
            type: ElementNodeType(name: "define"),
            scope: template
        )
    }
    public override func element(in scope: Scope) -> Element {
        return DefinitionElement(type: self, scope: scope)
    }
}

private func getNodeTitle(_ node: Node) -> Substring? {
    for child in node.children {
        if child.nodeType.name == "gaintext-title" {
            return child.sourceContent
        }
    }
    return nil
}

private func addParameter(_ node: Node, to template: inout ScopeTemplate) {
    for child in node.children {
        if child.nodeType.name == "gaintext-title" {
            let name = String(child.sourceContent)
            template.block[name] = ElementType(name)
            return
        }
    }
    fatalError("parameter without name?")
}

/// The type for custom elements.
///
/// Custom element types are defined dynamically when encountering
/// a `DefinitionElement`.
class CustomElementType: ElementType {
    init(_ name: String, template: [Node]) {
        var scopeTemplate = ScopeTemplate()
        // prepare list of available parameters
        for node in template {
            if node.nodeType === parameterType.nodeType {
                addParameter(node, to: &scopeTemplate)
            }
        }
        self.template = template
        super.init(
            name,
            type: ElementNodeType(name: name),
            scope: scopeTemplate
        )
    }

    /// The template for new elements of this type.
    /// Contains all nodes from the body of the element definition.
    let template: [Node]
}
