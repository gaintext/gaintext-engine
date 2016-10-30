//
// GainText parser
// Copyright Martin Waitz
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//

import PackageDescription

let package = Package(
    name: "gaintext-engine",

    targets: [
        // Sources
        Target(name: "Engine"),

        Target(name: "Blocks", dependencies: ["Engine"]),
        Target(name: "Markup", dependencies: ["Engine"]),
        Target(name: "Elements", dependencies: ["Engine"]),

        Target(name: "GainText",
            dependencies: ["Engine", "Blocks", "Markup", "Elements"]),

        Target(name: "gain", dependencies: ["Engine", "GainText"]),

        // Tests
        Target(name: "EngineTests", dependencies: ["GainText"]),

        Target(name: "BlocksTests", dependencies: ["GainText"]),
        Target(name: "MarkupTests", dependencies: ["GainText"])
//        Target(name: "ElementsTests", dependencies: ["EngineTests", "GainText"]),
    ],
    dependencies: [
        .Package(url: "https://github.com/Quick/Nimble", majorVersion: 5)
    ]
)
