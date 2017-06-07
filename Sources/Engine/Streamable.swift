//
// GainText parser
// Copyright Martin Waitz
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//


public protocol StructuredStreamable: TextOutputStreamable {
    func write<Target: TextOutputStream>(to target: inout Target, indent level: Int)
}

extension StructuredStreamable {
    // indent defaults to zero
    public func write<Target: TextOutputStream>(to target: inout Target) {
        write(to: &target, indent: 0)
    }
}

public protocol HTMLStreamable: StructuredStreamable {
    var html: String { get }
}

public struct StringOutputStream: TextOutputStream {
    var content: String = ""
    public mutating func write(_ string: String) {
        content += string
    }
}

extension HTMLStreamable {
    public var html: String {
        var target = StringOutputStream()
        write(to: &target)
        return target.content
    }
}


// helper for indentation
private func _write<Target: TextOutputStream>(indentation level: Int, to s: inout Target) {
    s.write(String(repeating: " ", count: level))
}

private func _write<Target: TextOutputStream>(escaped string: Substring, to s: inout Target) {
    for c in string {
        switch c {
        case "<": s.write("&lt;")
        case ">": s.write("&gt;")
        case "&": s.write("&amp;")
        default:  s.write(String(c))
        }
    }
}


extension Node: HTMLStreamable {
    public func write<Target: TextOutputStream>(to target: inout Target, indent level: Int) {
        _write(indentation: level, to: &target)
        target.write("<\(nodeType.name) start=\"\(range.start.right)\" end=\"\(range.end.left)\"")
        for (key, value) in attributes {
            target.write(" \(key)='\(value)'")
        }
        target.write(">\n")
        if children.isEmpty {
            _write(indentation: level + 1, to: &target)
            target.write("<src>")
            _write(escaped: sourceContent, to: &target)
            target.write("</src>\n")
        } else {
            for child in children {
                child.write(to: &target, indent: level + 1)
            }
        }
        _write(indentation: level, to: &target)
        target.write("</\(nodeType.name)>\n")
    }
}
