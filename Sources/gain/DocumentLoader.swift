//
// GainText
// Copyright Martin Waitz
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//

import Foundation
import Engine

struct DocumentLoader: DocumentLoaderDelegate {

    func load(fromFile name: String, scope: Scope) throws -> Document {
        let text = try NSString(contentsOfFile: name, encoding: String.Encoding.utf8.rawValue)
        return Document(source: String(text), global: scope, loader: self)
    }
}
