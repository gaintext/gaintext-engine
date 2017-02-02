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

enum TestError: Error {
    case a
}

let digits = collect(fromSet: "0123456789")

class OperatorMapTests: XCTestCase {

    func testSuccess() throws {
        let doc = Document(source: "123")
        let f: (String) -> Int = { Int($0)! }
        let p = f <^> digits
        let (result, tail) = try parse(p, doc)
        expect(result) == 123
        expect(tail.atEndOfLine) == true
    }
    func testFuncThrows() throws {
        let doc = Document(source: "123")
        let f: (String) throws -> Int = { _ in throw TestError.a }
        let p = f <^> digits
        expect(try p.parse(doc.start())).to(throwError())
    }
}

class OperatorApplyTests: XCTestCase {

    func testSuccess() throws {
        let doc = Document(source: "123")
        let p = pure { Int($0) } <*> digits
        let (result, tail) = try parse(p, doc)
        expect(result) == 123
        expect(tail.atEndOfLine) == true
    }
}

class OperatorLeftTests: XCTestCase {

    func testLeft1() throws {
        let doc = Document(source: "abcdef")
        let p = literal("abc") <* literal("def")
        let (result, tail) = try parse(p, doc)
        expect(result) == "abc"
        expect(tail.atEndOfLine) == true
    }

    func testLeft2() throws {
        let doc = Document(source: "defabc")
        let p = literal("abc") <* literal("def")
        expect(try p.parse(doc.start())).to(throwError())
    }
}

class OperatorRightTests: XCTestCase {

    func testRight1() throws {
        let doc = Document(source: "abcdef")
        let p = literal("abc") *> literal("def")
        let (result, tail) = try parse(p, doc)
        expect(result) == "def"
        expect(tail.atEndOfLine) == true
    }

    func testRight2() throws {
        let doc = Document(source: "defabc")
        let p = literal("abc") *> literal("def")
        expect(try p.parse(doc.start())).to(throwError())
    }
}

class OperatorOrTests: XCTestCase {

    func testOr1() throws {
        let doc = Document(source: "abc")
        let p = literal("abc") <|> literal("def")
        let (result, tail) = try parse(p, doc)
        expect(result) == "abc"
        expect(tail.atEndOfLine) == true
    }

    func testOr2() throws {
        let doc = Document(source: "def")
        let p = literal("abc") <|> literal("def")
        let (result, tail) = try parse(p, doc)
        expect(result) == "def"
        expect(tail.atEndOfLine) == true
    }

    func testOr3() throws {
        let doc = Document(source: "ghi")
        let p = literal("abc") <|> literal("def")
        expect(try p.parse(doc.start())).to(throwError())
    }
}

class OperatorMapParserTests: XCTestCase {

    func testMapParser1() throws {
        let doc = Document(source: "ada")
        let p = collect(fromSet: "abc") >>- { collect(fromSet: "def") <* literal($0) }
        let (result, tail) = try parse(p, doc)
        expect(result) == "d"
        expect(tail.atEndOfLine) == true
    }
    func testMapParser2() throws {
        let doc = Document(source: "beb")
        let p = collect(fromSet: "abc") >>- { collect(fromSet: "def") <* literal($0) }
        let (result, tail) = try parse(p, doc)
        expect(result) == "e"
        expect(tail.atEndOfLine) == true
    }
    func testMapParser3() throws {
        let doc = Document(source: "adb")
        let p = collect(fromSet: "abc") >>- { oneOf("def") <* literal($0) }
        expect(try p.parse(doc.start())).to(throwError())
    }
}

class OperatorComposeFuncTests: XCTestCase {

    func testComposeFuncSuccess() throws {
        let doc = Document(source: "aa")
        let f = oneOf as (String)->Parser<String> >-> literal
        let (result, tail) = try parse(f("abc"), doc)
        expect(result) == "a"
        expect(tail.atEndOfLine) == true
    }

    func testComposeFuncLhsFailure() throws {
        let doc = Document(source: "dd")
        let f = oneOf as (String)->Parser<String> >-> literal
        expect(try f("abc").parse(doc.start())).to(throwError())
    }
    func testComposeFuncRhsFailure() throws {
        let doc = Document(source: "ab")
        let f = oneOf as (String)->Parser<String> >-> literal
        expect(try f("abc").parse(doc.start())).to(throwError())
    }
}

class OperatorAddTests: XCTestCase {

    func testAddString1() throws {
        let doc = Document(source: "ab")
        let p = literal("a") <+> literal("b")
        let (result, tail) = try parse(p, doc)
        expect(result) == "ab"
        expect(tail.atEndOfLine) == true
    }

    func testAddList1() throws {
        let doc = Document(source: "")
        let p = pure(["a"]) <+> pure(["b"])
        let (result, _) = try parse(p, doc)
        expect(result) == ["a", "b"]
    }
}

class CombinatorMapTests: XCTestCase {

    func testSuccess1() throws {
        let doc = Document(source: "123")
        let p = digits.map { Int($0) }
        let (result, tail) = try parse(p, doc)
        expect(result) == 123
        expect(tail.atEndOfLine) == true
    }

    func testSuccess2() throws {
        let doc = Document(source: "123a")
        let p = digits.map { Int($0) }
        let (result, tail) = try parse(p, doc)
        expect(result) == 123
        expect(tail.atEndOfLine) == false
    }

    func testFailure() throws {
        let doc = Document(source: "a123")
        let p = digits.map { Int($0) }
        expect(try p.parse(doc.start())).to(throwError())
    }

    func testFuncThrows() throws {
        let doc = Document(source: "123")
        let p = digits.map { (_) throws -> Int in
            throw TestError.a
        }
        expect(try p.parse(doc.start())).to(throwError())
    }
}

class CombinatorLookaheadTests: XCTestCase {

    func testSuccess() throws {
        let doc = Document(source: "123")
        let p = lookahead(digits)
        let (result, tail) = try parse(p, doc)
        expect(result) == "123"
        expect(tail.position) == doc.start().position
    }
    func testFailure() throws {
        let doc = Document(source: "a123")
        let p = lookahead(digits)
        expect(try p.parse(doc.start())).to(throwError())
    }
}

class CombinatorNotTests: XCTestCase {

    func testSuccess() throws {
        let doc = Document(source: "a123")
        let p = not(digits)
        let (_, tail) = try parse(p, doc)
        expect(tail.atEndOfLine) == false
    }
    func testFailure() throws {
        let doc = Document(source: "123")
        let p = not(digits)
        expect(try p.parse(doc.start())).to(throwError())
    }
}

class CombinatorOptionalTests: XCTestCase {

    func testSome1() throws {
        let doc = Document(source: "123")
        let p = optional(digits)
        let (result, tail) = try parse(p, doc)
        expect(result) == .some("123")
        expect(tail.atEndOfLine) == true
    }
    func testNone1() throws {
        let doc = Document(source: "a123")
        let p = optional(digits)
        let (result, tail) = try parse(p, doc)
        expect(result).to(beNil())
        expect(tail.atEndOfLine) == false
    }

    func testSome2() throws {
        let doc = Document(source: "123")
        let p = optional(digits, otherwise: "0")
        let (result, tail) = try parse(p, doc)
        expect(result) == "123"
        expect(tail.atEndOfLine) == true
    }
    func testNone2() throws {
        let doc = Document(source: "a123")
        let p = optional(digits, otherwise: "0")
        let (result, tail) = try parse(p, doc)
        expect(result) == "0"
        expect(tail.atEndOfLine) == false
    }

    func testSome3() throws {
        let doc = Document(source: "123")
        let p = optional(digits *> pure(()))
        let (_, tail) = try parse(p, doc)
        expect(tail.atEndOfLine) == true
    }
    func testNone3() throws {
        let doc = Document(source: "a123")
        let p = optional(digits *> pure(()))
        let (_, tail) = try parse(p, doc)
        expect(tail.atEndOfLine) == false
    }

}

class CombinatorLazyTests: XCTestCase {

    func testRecursive1() throws {
        let doc = Document(source: "")
        var p: Parser<String>!
        p = literal("abc") <+> optional(lazy(p), otherwise: "")
        expect(try p.parse(doc.start())).to(throwError())
    }

    func testRecursive2() throws {
        let doc = Document(source: "abcdef")
        var p: Parser<String>!
        p = literal("abc") <+> optional(lazy(p), otherwise: "")

        let (result, tail) = try parse(p, doc)
        expect(result) == "abc"
        expect(tail.position.left) == "1:3"
    }

    func testRecursive3() throws {
        let doc = Document(source: "abcabcdef")
        var p: Parser<String>!
        p = literal("abc") <+> optional(lazy(p), otherwise: "")

        let (result, tail) = try parse(p, doc)
        expect(result) == "abcabc"
        expect(tail.position.left) == "1:6"
    }

    static var allTests : [(String, (CombinatorLazyTests) -> () throws -> Void)] {
        return [
            ("testRecursive1", testRecursive1),
            ("testRecursive2", testRecursive2),
            ("testRecursive3", testRecursive3),
        ]
    }
}

class CombinatorListTests: XCTestCase {

    func testEmpty() throws {
        let doc = Document(source: "")
        let p1 = literal("1").map {[$0]}
        let p2 = oneOf("23").map {[$0]}
        let p = list(first: p1, following: p2)
        expect(try p.parse(doc.start())).to(throwError())
    }

    func testWrongStart() throws {
        let doc = Document(source: "-")
        let p1 = literal("1").map {[$0]}
        let p2 = oneOf("23").map {[$0]}
        let p = list(first: p1, following: p2)
        expect(try p.parse(doc.start())).to(throwError())
    }

    func testOnlyOne() throws {
        let doc = Document(source: "1")
        let p1 = literal("1").map {[$0]}
        let p2 = oneOf("23").map {[$0]}
        let p = list(first: p1, following: p2)
        let (result, tail) = try parse(p, doc)
        expect(result) == ["1"]
        expect(tail.atEndOfLine) == true
    }

    func testTwo1() throws {
        let doc = Document(source: "12")
        let p1 = literal("1").map {[$0]}
        let p2 = oneOf("23").map {[$0]}
        let p = list(first: p1, following: p2)
        let (result, tail) = try parse(p, doc)
        expect(result) == ["1", "2"]
        expect(tail.atEndOfLine) == true
    }

    func testTwo2() throws {
        let doc = Document(source: "12-")
        let p1 = literal("1").map {[$0]}
        let p2 = oneOf("23").map {[$0]}
        let p = list(first: p1, following: p2)
        let (result, tail) = try parse(p, doc)
        expect(result) == ["1", "2"]
        expect(tail.atEndOfLine) == false
    }

    func testThree1() throws {
        let doc = Document(source: "123")
        let p1 = literal("1").map {[$0]}
        let p2 = oneOf("23").map {[$0]}
        let p = list(first: p1, following: p2)
        let (result, tail) = try parse(p, doc)
        expect(result) == ["1", "2", "3"]
        expect(tail.atEndOfLine) == true
    }

    func testThree2() throws {
        let doc = Document(source: "123-")
        let p1 = literal("1").map {[$0]}
        let p2 = oneOf("23").map {[$0]}
        let p = list(first: p1, following: p2)
        let (result, tail) = try parse(p, doc)
        expect(result) == ["1", "2", "3"]
        expect(tail.atEndOfLine) == false
    }

    func testSeparator0() throws {
        let doc = Document(source: ",")
        let p = list(oneOf("123").map {[$0]}, separator: literal(","))
        expect(try p.parse(doc.start())).to(throwError())
    }

    func testSeparator1() throws {
        let doc = Document(source: "1")
        let p = list(oneOf("123").map {[$0]}, separator: literal(","))
        let (result, tail) = try parse(p, doc)
        expect(result) == ["1"]
        expect(tail.atEndOfLine) == true
    }

    func testSeparator2() throws {
        let doc = Document(source: "1,2")
        let p = list(oneOf("123").map {[$0]}, separator: literal(","))
        let (result, tail) = try parse(p, doc)
        expect(result) == ["1", "2"]
        expect(tail.atEndOfLine) == true
    }

    func testSeparator3() throws {
        let doc = Document(source: "1,2,3")
        let p = list(oneOf("123").map {[$0]}, separator: literal(","))
        let (result, tail) = try parse(p, doc)
        expect(result) == ["1", "2", "3"]
        expect(tail.atEndOfLine) == true
    }

    func testSeparator4() throws {
        let doc = Document(source: "1,2,3,")
        let p = list(oneOf("123").map {[$0]}, separator: literal(","))
        let (result, tail) = try parse(p, doc)
        expect(result) == ["1", "2", "3"]
        expect(tail.atEndOfLine) == false
    }

    static var allTests : [(String, (CombinatorListTests) -> () throws -> Void)] {
        return [
            ("testEmpty", testEmpty),
            ("testWrongStart", testWrongStart),
            ("testOnlyOne", testOnlyOne),
            ("testTwo1", testTwo1),
            ("testTwo2", testTwo2),
            ("testThree1", testThree1),
            ("testThree2", testThree2),
            ("testSeparator0", testSeparator0),
            ("testSeparator1", testSeparator1),
            ("testSeparator2", testSeparator2),
            ("testSeparator3", testSeparator3),
            ("testSeparator4", testSeparator4),
        ]
    }
}

class LookaheadParserTests: XCTestCase {

    func test1() throws {
        let doc = Document(source: "abc")
        let input = doc.start()
        let p = lookahead(literal("a"))

        let (res, tail) = try p.parse(input)
        expect(res) == "a"
        expect(tail.position.left) == "1:0"
    }

    func test2() throws {
        let doc = Document(source: "abc")
        let input = doc.start()
        let p = lookahead(literal("b"))

        expect {try p.parse(input)}.to(throwError())
    }

    static var allTests : [(String, (LookaheadParserTests) -> () throws -> Void)] {
        return [
            ("test1", test1),
            ("test2", test2),
        ]
    }
}

