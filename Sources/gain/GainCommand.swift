//
// GainText
// Copyright Martin Waitz
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//

import Engine
import GainText
import HTMLKit

struct GainCommand {

    let args: [String]

    func usage() {
        print("gain - convert a GainText document to HTML.")
    }

    func processFile(name: String) throws {
        let loader = DocumentLoader()
        let doc = try loader.loadRoot(fromFile: name)

        print(doc.parseHTML().innerHTML)
    }

    func run() throws {
        guard args.count > 1 else {
            usage()
            return
        }

        var sources: [String] = []

        for arg in args.dropFirst() {
            if arg == "-h" || arg == "--help" {
                usage()
                return
            }
            sources.append(arg)
        }

        for source in sources {
            try processFile(name: source)
        }
    }
}
