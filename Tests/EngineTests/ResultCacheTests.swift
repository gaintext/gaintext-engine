//
// GainText parser
// Copyright Martin Waitz
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//

@testable import Engine
import GainText
import Runes

import XCTest
import Nimble


class CachedParserTests: XCTestCase {

    var calls = 0
    func count<R>(_ p: Parser<R>) -> Parser<R> {
        return Parser { input in
            self.calls += 1
            return try p.parse(input)
        }
    }

    func testCachedParser() throws {
        let doc = Document(source: "abc")
        let p = cached(count(textNode(spanning: literal("abc"))))

        let (result1, tail1) = try parse(p, doc)
        expect(result1[0].sourceContent) == "abc"
        expect(tail1.atEndOfLine) == true
        expect(self.calls) == 1

        let (result2, tail2) = try parse(p, doc)
        expect(result2[0].sourceContent) == "abc"
        expect(tail2.atEndOfLine) == true
        expect(self.calls) == 1
    }

    func testRecursive1() throws {
        let doc = Document(source: "")
        var p: Parser<[Node]>!
        let c = cached(count(textNode(spanning: literal("abc"))))
        p = c <+> lazy(p) <|> c
        expect(try p.parse(doc.start())).to(throwError())
        expect(self.calls) == 1
    }

    func testRecursive2() throws {
        let doc = Document(source: "abcdef")
        var p: Parser<[Node]>!
        let c = cached(count(textNode(spanning: literal("abc"))))
        p = c <+> lazy(p) <|> c

        let (result, tail) = try parse(p, doc)
        expect(result).to(haveCount(1))
        expect(tail.position.left) == "1:3"
        expect(self.calls) == 2
    }

    func testRecursive3() throws {
        let doc = Document(source: "abcabcdef")
        var p: Parser<[Node]>!
        let c = cached(count(textNode(spanning: literal("abc"))))
        p = c <+> lazy(p) <|> c

        let (result, tail) = try parse(p, doc)
        expect(result).to(haveCount(2))
        expect(tail.position.left) == "1:6"
        expect(self.calls) == 3
    }

    static var allTests : [(String, (CachedParserTests) -> () throws -> Void)] {
        return [
            ("testCachedParser", testCachedParser),
            ("testRecursive1", testRecursive1),
            ("testRecursive2", testRecursive2),
            ("testRecursive3", testRecursive3),
        ]
    }
}
