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


class ImportNodeType: ElementNodeType {
    override func prepare(_ node: Node, _ scope: Scope) {
        print("import: \(node)")
    }
}

public class ImportElementType: ElementType {
    public init() {
        super.init("import", type: ImportNodeType(name: "import"))
    }
}
