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

func main() throws {
    let name = CommandLine.arguments[1]
    let text = try NSString(contentsOfFile: name, encoding: String.Encoding.utf8.rawValue)

    let doc = Document(source: String(text))

    let nodes = doc.parse()

    print("<!DOCTYPE html>")
    print("<html>")
    print("<meta charset=\"utf-8\">")
    print()
    for node in nodes {
        print(node.html)
    }
    print("</html>")
}

do {
    try main()
} catch let e {
    print("error:", e)
}
