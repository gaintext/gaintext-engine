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

public protocol ObjectIdentity: class, Equatable, Hashable {}
extension ObjectIdentity {
    public static func ==(lhs: Self, rhs: Self) -> Bool {
        return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }
    public var hashValue: Int {
        return ObjectIdentifier(self).hashValue
    }
}


public class Document: ObjectIdentity {
    public init(source: String, global: Scope) {
        self.source = source
        self.global = global
    }

    let source: String
    public let global: Scope

    func start() -> Cursor {
        return Cursor(at: block, scope: global)
    }

    var root: Node?
    private lazy var block: Block = self.createRootBlock()
}

extension Document {

    /// Parse the entire document
    public func parse() -> [Node] {
        return global.blockParser.parseBlock(start(), error: Document.unexpectedInputError)
    }
    private static let unexpectedInputError = ErrorNodeType("unexpected input")
}

extension Document {

    private func primordialBlock() -> Block {
        let start = Position(startOf: self)
        let primordial = Line(start: start, endIndex: source.endIndex)
        return Block(document: self, lines: [primordial])
    }

    fileprivate func createRootBlock() -> Block {
        var primordial = Cursor(at: primordialBlock(), scope: global)
        var lines: [Line] = []
        var lineStart = primordial.position
        var lineEnd = lineStart
        // go through the document (one 'line' in the primordial block)
        while !primordial.atEndOfLine {
            switch source[primordial.position.index] {
            case "\n":
                let line = Line(start: lineStart, endIndex: lineEnd.index)
                lines.append(line)
                try! primordial.advance()
                lineStart = primordial.position
                lineEnd = lineStart
            case "\r":
                // ignore it, don't advance lineEnd
                try! primordial.advance()
            default:
                try! primordial.advance()
                lineEnd = primordial.position
            }
        }
        if lineStart != lineEnd {
            let line = Line(start: lineStart, endIndex: lineEnd.index)
            lines.append(line)
        }

        return Block(document: self, lines: lines)
    }
}


public enum NodeAttribute {
    case bool(String)
    case number(String, Int)
    case text(String, String)
}

extension NodeAttribute: Equatable {
    static public func ==(lhs: NodeAttribute, rhs: NodeAttribute) -> Bool {
        switch (lhs, rhs) {
        case (.bool(let name1), .bool(let name2)):
            return name1 == name2
        case (.number(let name1, let value1), .number(let name2, let value2)):
            return name1 == name2 && value1 == value2
        case (.text(let name1, let value1), .text(let name2, let value2)):
            return name1 == name2 && value1 == value2
        default:
            return false
        }
    }
}

// Nodes are used for the first parst phase
// They describe the hierarchical structure of the
// input document
public struct Node {
    public let range: SourceRange
    public let document: Document
    public let nodeType: NodeType
    public let attributes: [NodeAttribute]
    public let children: [Node]
}

extension Node {
    public init(start: Position, end: Cursor, nodeType: NodeType,
                attributes: [NodeAttribute] = [], children: [Node] = []) {
        self.range = SourceRange(start: start, end: end.position)
        self.document = end.document
        self.nodeType = nodeType
        self.attributes = attributes
        self.children = children

        self.nodeType.prepare(self, end.scope)
    }
}

extension Node: Equatable {
    public static func ==(lhs: Node, rhs: Node) -> Bool {
        return lhs.document == rhs.document
            && lhs.range == rhs.range
            && ObjectIdentifier(lhs.nodeType) == ObjectIdentifier(rhs.nodeType)
    }
}

extension Node {
    public var sourceRange: String {
        return String(describing: range)
    }
    public var sourceContent: String {
        return range.content
    }
}

public protocol NodeType: class, CustomStringConvertible {
    var name: String { get }
    func prepare(_ node: Node, _ scope: Scope)
    func constructAST(_ node: Node) -> ASTNode
}

extension NodeType {
    public func prepare(_ node: Node, _ scope: Scope) {}
    public var description: String { return name }
}


/// A position within the source document.
/// It points between characters, so there always is one character
/// to the left and one to the right of each position
/// (but not for document start and end, obviously).
public struct Position {
    var index: String.Index
    fileprivate let document: Document
    fileprivate var line: Int
    fileprivate var column: Int

    fileprivate init(startOf document: Document) {
        self.index = document.source.startIndex
        self.document = document
        self.line = 1
        self.column = 0
    }

    init(at block: Block) {
        let lineIndex = block.lines.startIndex
        if lineIndex != block.lines.endIndex {
            self = block.lines[lineIndex].start
        } else {
            // no position available
            index = block.document.source.endIndex
            document = block.document
            line = 0
            column = 0
        }
    }
}

extension Position {
    /// Get the human readable position of the character to the left.
    var left: String {
        return "\(line):\(column)"
    }
    /// Get the human readable position of the character to the right.
    var right: String {
        return "\(line):\(column+1)"
    }
}

extension Position {
    /// Return a new Position pointing to the next character.
    func next() -> Position {
        let source = document.source
        var pos = self
        if source[index] == "\n" {
            pos.line += 1
            pos.column = 0
        } else {
            pos.column += 1
        }
        pos.index = source.index(after: index)
        return pos
    }
}

extension Position: Equatable {
    public static func ==(lhs: Position, rhs: Position) -> Bool {
        return lhs.index == rhs.index
            && lhs.document == rhs.document
    }
}
extension Position: Hashable {
    public var hashValue: Int {
        return index._utf16Index
    }
}

public struct SourceRange {
    var start: Position
    var end: Position
}

extension SourceRange: CustomStringConvertible {
    public var description: String {
        return "\(start.right)..\(end.left)"
    }
}

extension SourceRange {
    public var content: String {
        assert(start.document == end.document)
        let source = start.document.source
        return source.substring(with: start.index..<end.index)
    }
}

extension SourceRange: Equatable {
    public static func ==(lhs: SourceRange, rhs: SourceRange) -> Bool {
        return lhs.start == rhs.start && lhs.end == rhs.end
    }
}


// ASTNodes are created from Nodes and store the final AST
// They can store any content and are not restricted to reference
// the input document
public enum ASTNode {
    case element(Tag, attributes: [NodeAttribute], children: [ASTNode])
    case text(String)
    case comment(String)
    case pi(String)
}

public class Tag: ObjectIdentity {
    let name: String
    let isBlock: Bool

    public init(_ name: String, isBlock: Bool) {
        self.name = name
        self.isBlock = isBlock
    }
}

extension ASTNode {
    static var tags: [String: Tag] = [:]
    static func tag(name: String, attributes: [NodeAttribute] = [], children: [ASTNode] = []) -> ASTNode? {
        guard let tag = ASTNode.tags[name] else { return nil }
        return .element(tag, attributes: attributes, children: children)
    }
}

extension ASTNode: Equatable {
    public static func ==(lhs: ASTNode, rhs: ASTNode) -> Bool {
        switch (lhs, rhs) {
        case (.element(let tag1, let attr1, let children1), .element(let tag2, let attr2, let children2)):
            return tag1 == tag2 && attr1 == attr2 && children1 == children2
        case (.text(let text1), .text(let text2)):
            return text1 == text2
        case (.comment(let c1), .comment(let c2)):
            return c1 == c2
        case (.pi(let s1), .pi(let s2)):
            return s1 == s2
        default:
            return false
        }
    }
}
