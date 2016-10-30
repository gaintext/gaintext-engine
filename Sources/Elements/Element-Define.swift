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

class DefinitionScope: Scope {
    func addParameter(name: String) {
        print("scope.addParameter \(name)")
    }
}

/// Definition of new Elements.
class DefinitionElement: Element {

    override func childScope() -> Scope {
        let scope = super.childScope()
        return DefinitionScope(parent: scope)
    }

    override func finish(_ node: Node) {
        print("define: \(node)")
        guard title.count > 0 else {
            // TBD: throw?
            print("error: nothing to define")
            return
        }
        let name = title[0].sourceContent

        print("defining new element '\(name)'")
        let customType = CustomElementType(name: name)
        scope.register(block: customType)
    }
}

class DefinitionElementType: ElementType {
    public init() {
        super.init("define", type: ElementNodeType(name: "define"))
    }
    override func element(in scope: Scope) -> Element {
        return DefinitionElement(type: self, scope: scope)
    }
}


class ParameterNodeType: ElementNodeType {
    override func prepare(_ node: Node, _ scope: Scope) {
        // TBD: go through all scopes to find the definition
        let definition = scope as! DefinitionScope
        definition.addParameter(name: "foo")
    }
}

class CustomElementType: ElementType {
    init(name: String) {//, template: ScopeTemplate) {
        super.init(name, type: ElementNodeType(name: name))//, body: <#T##NodeParser?#>, scope: template)
    }
}
