//
// GainText parser
// Copyright Martin Waitz
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//


/// NodeType for Elements
open class ElementNodeType: NodeType {
    public init(name: String) {
        self.name = name
    }

    public var name: String

    /// Prepare a newly created `Node`.
    open func prepare(_ node: Node, _ scope: Scope) {
        // allow to override it
    }
}

extension ElementNodeType {
    public func constructAST(_ node: Node) -> ASTNode {
        assert(ObjectIdentifier(node.nodeType) == ObjectIdentifier(self))
        let children = node.children.map { node in
            node.nodeType.constructAST(node)
        }
        return ASTNode.tag(name: name, attributes: node.attributes,
                           children: children)!
    }
}

extension ElementNodeType: CustomStringConvertible {
    public var description: String { return "element \(name)" }
}

/// Control the parsing of a new element.
///
/// A `Element` instance is created when we parse the `ElementType`
/// for the new element.
/// It stores all states which is needed for parsing of the element's
/// children and for the creation of the final `Node`.
open class Element {
    let type: ElementType
    public let scope: Scope
    public var title: [Node] = []
    public var body: [Node] = []
    var attributes: [NodeAttribute] = []
    var titleAttributes: [NodeAttribute] = []

    required public init(type: ElementType, scope: Scope) {
        self.type = type
        self.scope = scope
    }

    /// Create a new `Scope` instance for parsing of the element's children.
    open func childScope() -> Scope {
        return Scope(parent: scope, template: type.template)
    }

    /// Create the `Cursor` for this element's children.
    func childCursor(block lines: [Line], parent cursor: Cursor) -> Cursor {
        var cursor = Cursor(block: lines, parent: cursor)
        cursor.scope = childScope()
        return cursor
    }

    private var titleParser: SpanParser {
        if let p = type.titleParser {
            return p
        }
        return scope.spanParser
    }
    private var blockParser: NodeParser {
        if let p = type.bodyParser {
            return p
        }
        return scope.blockParser
    }

    public func addAttribute(_ attribute: NodeAttribute) {
        attributes.append(attribute)
    }

    public func addTitleAttribute(_ attribute: NodeAttribute) {
        titleAttributes.append(attribute)
    }

    /// Parse the title of a block element or the body of a span element.
    ///
    /// All parsed title nodes are stored in the element and used to
    /// construct the element's node.
    ///
    /// Either uses the element-type specific parser or a default parser
    /// from the current scope.
    public func parseSpan(cursor: Cursor, until endMarker: Parser<()>) throws -> Cursor {
        let (nodes, next) = try titleParser.parse(cursor: cursor, until: endMarker)
        title += nodes
        return next
    }

    /// Parse the title of a block element or the body of a span element.
    ///
    /// All parsed title nodes are wrapped in one 'title' node which is
    /// stored in the element and used to construct the element's node.
    ///
    /// Either uses the element-type specific parser or a default parser
    /// from the current scope.
    ///
    /// Always parses up to the end of the line.
    /// In case of any error, an error node is produced instead of
    /// throwing or returning early.
    public func parseTitle(cursor: Cursor) {
        let start = cursor.position
        let (nodes, end) = titleParser.parseLine(cursor, error: Element.titleError)
        title += nodes
        guard !title.isEmpty else { return }
        let node = Node(start: start, end: end, nodeType: Element.titleNodeType,
                           attributes: titleAttributes, children: title)
        title = [node]
    }
    private static let titleError = ErrorNodeType("invalid title")

    private func parseBody(cursor: Cursor, body parser: NodeParser) throws -> Cursor {
        let (nodes, endCursor) = try parser.parse(cursor)
        body += nodes

        return endCursor
    }

    public func parseBody(block lines: [Line], parent cursor: Cursor) {
        let innerCursor = childCursor(block: lines, parent: cursor)
        body += blockParser.parseBlock(innerCursor, error: Element.wrongBlockError)
    }
    private static let wrongBlockError = ErrorNodeType("wrong block")

    /// Create the `Node` for this element.
    public func createNode(start: Position, end: Cursor) -> Node {
        let node = Node(start: start, end: end, nodeType: type.nodeType,
                           attributes: attributes, children: title + body)
        finish(node)
        return node
    }
    private static let titleNodeType = ElementNodeType(name: "title")

    // TBD: replace NodeType.prepare?
    open func finish(_ node: Node) {
    }
}

/// Describes one type of elements and how to parse it.
///
/// The `ElementType` is registered with a `Scope` and is responsible
/// to create an `Element` instance.
open class ElementType {
    let name: String
    let nodeType: NodeType
    let bodyParser: NodeParser?
    let titleParser: SpanParser?
    let template: ScopeTemplate

    // TBD: maybe use some special "nothing here" parser as default?
    public init(_ name: String, type: NodeType,
         body: NodeParser? = nil,
         title: SpanParser? = nil,
         scope template: ScopeTemplate = ScopeTemplate()) {
        self.name = name
        self.nodeType = type
        self.bodyParser = body
        self.titleParser = title
        self.template = template
    }

    /// Factory method to create a new `Element` instance
    open func element(in scope: Scope) -> Element {
        return Element(type: self, scope: scope)
    }
}

extension ElementType {
    public convenience init(_ name: String, body: NodeParser? = nil, title: SpanParser? = nil) {
        self.init(name, type: ElementNodeType(name: name), body: body, title: title)
    }
}

/// Registers and stores all `ElementType`s.
public class ElementRegistry {
    public init(parent: ElementRegistry? = nil,
                template elements: [String: ElementType] = [:]) {
        self.parent = parent
        self.elements = elements
    }

    var elements: [String: ElementType]
    let parent: ElementRegistry?
}

extension ElementRegistry {
    public func register(_ element: ElementType) {
        elements[element.name] = element
    }

    public func addAlias(for element: ElementType, _ alias: String) {
        elements[alias] = element
    }
    public func addAlias(for name: String, _ alias: String) {
        guard let element = elements[name] else { return } // TBD
        addAlias(for: element, alias)
    }
}

extension ElementRegistry {
    public func getType(for name: String) -> ElementType? {
        if let element = elements[name] {
            return element
        }
        if let parent = parent {
            return parent.getType(for: name)
        }
        return nil
    }

    public func element(name: String, in scope: Scope) -> Element? {
        return getType(for: name)?.element(in: scope)
    }
}

public struct ScopeTemplate {
    var block: [String: ElementType] = [:]
    var markup: [String: ElementType] = [:]
}

extension ScopeTemplate {
    init(from scope: Scope) {
        self.block = scope.blockRegistry.elements
        self.markup = scope.markupRegistry.elements
    }
}

/// represent the complete scope: block elements, ...
open class Scope {
    public init(blockRegistry: ElementRegistry, markupRegistry: ElementRegistry,
         blockParser: NodeParser, spanParser: SpanParser) {
        self.blockRegistry = blockRegistry
        self.markupRegistry = markupRegistry
        self.blockParser = blockParser
        self.spanParser = spanParser

    }

    /// Create a `Element` instance which can be used to
    /// parse an element.
    ///
    /// - Parameter name: Name of the requested element.
    /// - Returns: one `Element`, or `nil` if no matching
    ///   element name was registered.
    public func block(name: String) -> Element? {
        return blockRegistry.element(name: name, in: self)
    }

    public func register(block: ElementType) {
        blockRegistry.register(block)
    }
    public func register(block: String, alias: String) {
        blockRegistry.addAlias(for: block, alias)
    }

    public func markup(name: String) -> Element? {
        return markupRegistry.element(name: name, in: self)
    }

    public func register(markup: ElementType) {
        markupRegistry.register(markup)
    }
    public func register(markup: String, alias: String) {
        markupRegistry.addAlias(for: markup, alias)
    }

    /// available block-level sub-Elements within this scope
    let blockRegistry: ElementRegistry
    /// available span-level sub-Elements within this scope
    let markupRegistry: ElementRegistry

    let blockParser: NodeParser
    let spanParser: SpanParser
}

extension Scope {
    public convenience init(parent scope: Scope, template: ScopeTemplate = ScopeTemplate()) {
        self.init(
            blockRegistry: ElementRegistry(parent: scope.blockRegistry, template: template.block),
            markupRegistry: ElementRegistry(parent: scope.markupRegistry, template: template.markup),
            blockParser: scope.blockParser,
            spanParser: scope.spanParser
        )
    }
}

