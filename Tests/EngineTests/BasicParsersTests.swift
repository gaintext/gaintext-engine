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

class LiteralCharacterParserTests: XCTestCase {

    func testMatch1() throws {
        let doc = Document(source: "abcdef")
        let input = doc.start()
        let p = literal(Character("a"))

        let (res, tail) = try p.parse(input)
        expect(res) == "a"
        expect(tail.position.left) == "1:1"
    }

    func testNoMatch1() throws {
        let doc = Document(source: "abcdef")
        let input = doc.start()
        let p = literal(Character("b"))

        expect {try p.parse(input)}.to(throwError())
    }

    static var allTests : [(String, (LiteralCharacterParserTests) -> () throws -> Void)] {
        return [
            ("testMatch1", testMatch1),
            ("testNoMatch1", testNoMatch1),
        ]
    }
}

class LiteralStringParserTests: XCTestCase {

    func testMatch1() throws {
        let doc = Document(source: "abcdef")
        let p = literal("a")

        let (res, tail) = try p.parse(doc.start())
        expect(res) == "a"
        expect(tail.position.left) == "1:1"
    }
    func testMatch2() throws {
        let doc = Document(source: "abcdef")
        let p = literal("abc")

        let (res, tail) = try p.parse(doc.start())
        expect(res) == "abc"
        expect(tail.position.left) == "1:3"
    }
    func testMatch3() throws {
        let doc = Document(source: "abcdef")
        let p = literal("abcdef")

        let (res, tail) = try p.parse(doc.start())
        expect(res) == "abcdef"
        expect(tail.position.left) == "1:6"
    }

    func testNoMatch1() throws {
        let doc = Document(source: "abcdef")
        let input = doc.start()
        let p = literal("bc")

        expect {try p.parse(input)}.to(throwError())
    }
    func testNoMatch2() throws {
        let doc = Document(source: "abcdef")
        let input = doc.start()
        let p = literal("abcdefg")

        expect {try p.parse(input)}.to(throwError())
    }

    static var allTests : [(String, (LiteralStringParserTests) -> () throws -> Void)] {
        return [
            ("testMatch1", testMatch1),
            ("testMatch2", testMatch2),
            ("testMatch2", testMatch3),
            ("testNoMatch1", testNoMatch1),
            ("testNoMatch2", testNoMatch2),
        ]
    }
}

class CollectWhileParserTests: XCTestCase {

    func testEmpty1() throws {
        let doc = Document(source: "bcd")
        let input = doc.start()
        let p = collect(takeWhile: {$0.char == Character("a")})

        expect {try p.parse(input)}.to(throwError())
    }
    func testEmpty2() throws {
        let doc = Document(source: "bcd")
        let input = doc.start()
        let p = collect(min: 0, takeWhile: {$0.char == Character("a")})

        let (res, tail) = try p.parse(input)
        expect(res) == ""
        expect(tail.position.left) == "1:0"
    }

    func test1() throws {
        let doc = Document(source: "abc")
        let input = doc.start()
        let p = collect(takeWhile: {$0.char == Character("a")})

        let (res, tail) = try p.parse(input)
        expect(res) == "a"
        expect(tail.position.left) == "1:1"
    }
    func test2() throws {
        let doc = Document(source: "aabb")
        let input = doc.start()
        let p = collect(takeWhile: {$0.char == Character("a")})

        let (res, tail) = try p.parse(input)
        expect(res) == "aa"
        expect(tail.position.left) == "1:2"
    }

    func test3() throws {
        let doc = Document(source: "abc")
        let input = doc.start()
        let p = collect(min: 2, takeWhile: {$0.char == Character("a")})

        expect {try p.parse(input)}.to(throwError())
    }
    func test4() throws {
        let doc = Document(source: "aabb")
        let input = doc.start()
        let p = collect(min: 2, takeWhile: {$0.char == Character("a")})

        let (res, tail) = try p.parse(input)
        expect(res) == "aa"
        expect(tail.position.left) == "1:2"
    }

    static var allTests : [(String, (CollectWhileParserTests) -> () throws -> Void)] {
        return [
            ("testEmpty1", testEmpty1),
            ("testEmpty2", testEmpty2),
            ("test1", test1),
            ("test2", test2),
            ("test3", test3),
            ("test4", test4),
        ]
    }
}

class CollectUntilParserTests: XCTestCase {

    func testEmpty1() throws {
        let doc = Document(source: "abc")
        let input = doc.start()
        let p = collect(until: {$0.char == Character("a")})

        expect {try p.parse(input)}.to(throwError())
    }
    func testEmpty2() throws {
        let doc = Document(source: "abc")
        let input = doc.start()
        let p = collect(min: 0, until: {$0.char == Character("a")})

        let (res, tail) = try p.parse(input)
        expect(res) == ""
        expect(tail.position.left) == "1:0"
    }

    func test1() throws {
        let doc = Document(source: "baba")
        let input = doc.start()
        let p = collect(until: {$0.char == Character("a")})

        let (res, tail) = try p.parse(input)
        expect(res) == "b"
        expect(tail.position.left) == "1:1"
    }
    func test2() throws {
        let doc = Document(source: "cba")
        let input = doc.start()
        let p = collect(until: {$0.char == Character("a")})

        let (res, tail) = try p.parse(input)
        expect(res) == "cb"
        expect(tail.position.left) == "1:2"
    }

    func test3() throws {
        let doc = Document(source: "baba")
        let input = doc.start()
        let p = collect(min: 2, until: {$0.char == Character("a")})

        expect {try p.parse(input)}.to(throwError())
    }
    func test4() throws {
        let doc = Document(source: "cba")
        let input = doc.start()
        let p = collect(min: 2, until: {$0.char == Character("a")})

        let (res, tail) = try p.parse(input)
        expect(res) == "cb"
        expect(tail.position.left) == "1:2"
    }

    static var allTests : [(String, (CollectUntilParserTests) -> () throws -> Void)] {
        return [
            ("testEmpty1", testEmpty1),
            ("testEmpty2", testEmpty2),
            ("test1", test1),
            ("test2", test2),
            ("test3", test3),
            ("test4", test4),
        ]
    }
}

class CharacterParserTests: XCTestCase {

    func test1() throws {
        let doc = Document(source: "a")
        let input = doc.start()
        let p = character

        let (res, tail) = try p.parse(input)
        expect(res) == "a"
        expect(tail.position.left) == "1:1"
    }

    func test2() throws {
        let doc = Document(source: "abc")
        let input = doc.start()
        let p = character

        let (res, tail) = try p.parse(input)
        expect(res) == "a"
        expect(tail.position.left) == "1:1"
    }

    func test3() throws {
        let doc = Document(source: "")
        let input = doc.start()
        let p = character

        expect {try p.parse(input)}.to(throwError())
    }

    func test4() throws {
        let doc = Document(source: "\n")
        let input = doc.start()
        let p = character

        expect {try p.parse(input)}.to(throwError())
    }

    static var allTests : [(String, (CharacterParserTests) -> () throws -> Void)] {
        return [
            ("test1", test1),
            ("test2", test2),
            ("test3", test3),
            ("test4", test4),
        ]
    }
}
