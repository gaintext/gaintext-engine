//
// GainText parser
// Copyright Martin Waitz
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//

import Foundation
import Engine
import GainText
import HTMLKit

func main() throws {
    let name = CommandLine.arguments[1]
    let text = try NSString(contentsOfFile: name, encoding: String.Encoding.utf8.rawValue)

    let doc = Document(source: String(text))

    print(doc.parseHTML().innerHTML)
}

do {
    try main()
} catch let e {
    print("error:", e)
}
