// swift-tools-version:4.0
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

    dependencies: [
        .package(url: "https://github.com/iabudiab/HTMLKit", from: Version("2.0.5")),
        .package(url: "https://github.com/thoughtbot/Runes", from: Version("4.0.0")),
        .package(url: "https://github.com/Quick/Nimble", from: Version("7.0.1")),
    ],
    targets: [
        .target(name: "Engine", dependencies: ["Runes"]),
        .target(name: "Generator", dependencies: ["Engine", "HTMLKit"]),

        .target(name: "Blocks", dependencies: ["Engine"]),
        .target(name: "Markup", dependencies: ["Engine"]),
        .target(name: "Elements", dependencies: ["Engine"]),

        .target(name: "GainText",
            dependencies: ["Engine", "Generator", "Blocks", "Markup", "Elements"]),

        .target(name: "gain", dependencies: ["Engine", "GainText", "Generator"]),

        .testTarget(name: "EngineTests", dependencies: ["GainText", "Nimble"]),
        .testTarget(name: "GeneratorTests", dependencies: ["GainText", "HTMLKit", "Nimble"]),

        .testTarget(name: "BlocksTests", dependencies: ["GainText", "Nimble"]),
        .testTarget(name: "MarkupTests", dependencies: ["GainText", "Nimble"]),
        .testTarget(name: "ElementTests", dependencies: ["GainText", "Nimble"]),
    ]
)
