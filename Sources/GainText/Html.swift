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
            node.generate(parent: html.body!)
        }

        return html
    }
}
