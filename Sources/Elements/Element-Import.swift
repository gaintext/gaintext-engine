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


/// Importing definitions of other files into the current scope.
class ImportElement: Element {

    override func finish(_ node: Node) {
        guard title.count > 0 else {
            // TBD: throw?
            fatalError("error: nothing to import")
        }
        let name = title[0].sourceContent
        let loader = node.document.loader
        do {
            let external = try loader.load(fromFile: name, scope: scope)
            let _ = external.parse()
        } catch {
            // TBD
            fatalError()
        }
    }
}

public class ImportElementType: ElementType {
    public init() {
        super.init("import", type: ElementNodeType(name: "import"))
    }
    public override func element(in scope: Scope) -> Element {
        return ImportElement(type: self, scope: scope)
    }
}
