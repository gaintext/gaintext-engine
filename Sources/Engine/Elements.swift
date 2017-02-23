//
// GainText parser
// Copyright Martin Waitz
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//

import HTMLKit


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
    public func generate(_ node: Node, parent: HTMLElement) {
        let element = HTMLElement(tagName: name)
        parent.append(element)

        for child in node.children {
            child.nodeType.generate(child, parent: element)
        }
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
    public var attributes: [Node] = []
    public var body: [Node] = []
    private var nodeAttributes: [NodeAttribute] = []

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

    fileprivate var blockParser: Parser<[Node]> {
        if let p = type.bodyParser {
            return p
        }
        return scope.blockParser
    }
    fileprivate var titleParser: SpanParser {
        if let p = type.titleParser {
            return p
        }
        return scope.spanParser
    }
    fileprivate var spanParser: SpanParser {
        if let p = type.titleParser {
            return p
        }
        return scope.spanParser
    }

    public func addNodeAttribute(_ attribute: NodeAttribute) {
        nodeAttributes.append(attribute)
    }

    /// Create the `Node` for this element.
    public func createNode(start: Position, end: Cursor) -> Node {
        let node = Node(start: start, end: end, nodeType: type.nodeType,
                           attributes: nodeAttributes,
                           children: title + attributes + body)
        finish(node)
        return node
    }
    private static let titleNodeType = ElementNodeType(name: "title")

    // TBD: replace NodeType.prepare?
    open func finish(_ node: Node) {
    }
}

let elementBodyParser = Parser<Parser<[Node]>> { input in
    let element = input.scope.element!
    return (element.blockParser, input)
}

let elementTitleParser = Parser<(Parser<()>) -> Parser<[Node]>> { input in
    let element = input.scope.element!
    return (element.titleParser, input)
}

let elementSpanParser = Parser<(Parser<()>) -> Parser<[Node]>> { input in
    let element = input.scope.element!
    return (element.spanParser, input)
}


/// Describes one type of elements and how to parse it.
///
/// The `ElementType` is registered with a `Scope` and is responsible
/// to create an `Element` instance.
open class ElementType {
    let name: String
    let nodeType: NodeType
    let bodyParser: Parser<[Node]>?
    let titleParser: SpanParser?
    let template: ScopeTemplate

    // TBD: maybe use some special "nothing here" parser as default?
    public init(_ name: String, type: NodeType,
         body: Parser<[Node]>? = nil,
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
    public convenience init(_ name: String,
                            body: Parser<[Node]>? = nil,
                            title: SpanParser? = nil) {
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
    public init(blockRegistry: ElementRegistry,
                markupRegistry: ElementRegistry,
                blockParser: Parser<[Node]>,
                spanParser: @escaping SpanParser,
                element: Element? = nil) {
        self.blockRegistry = blockRegistry
        self.markupRegistry = markupRegistry
        self.blockParser = blockParser
        self.spanParser = spanParser
        self.element = element
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

    let blockParser: Parser<[Node]>
    let spanParser: SpanParser

    /// the element which is currently being parsed
    var element: Element? = nil
}

extension Scope {
    public convenience init(parent scope: Scope, template: ScopeTemplate = ScopeTemplate()) {
        self.init(
            blockRegistry: ElementRegistry(parent: scope.blockRegistry, template: template.block),
            markupRegistry: ElementRegistry(parent: scope.markupRegistry, template: template.markup),
            blockParser: scope.blockParser,
            spanParser: scope.spanParser,
            element: scope.element
        )
    }
}

