// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation

public enum MaybeString: Codable {
    case string(String)
    case int(Int)
    case double(Double)

    public var asString: String {
        switch self {
        case .string(let s): return s
        case .int(let i): return String(i)
        case .double(let d): return String(d)
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let str = try? container.decode(String.self) {
            self = .string(str)
        } else if let int = try? container.decode(Int.self) {
        #if DEBUG
            let path = decoder.codingPath.map { $0.stringValue }.joined(separator: ".")
            print("⚠️ [MaybeString] '\(path)' got Int instead of String")
        #endif
            self = .int(int)
        } else if let double = try? container.decode(Double.self) {
        #if DEBUG
            let path = decoder.codingPath.map { $0.stringValue }.joined(separator: ".")
            print("⚠️ [MaybeString] '\(path)' got Double instead of String")
        #endif
            self = .double(double)
        } else {
            let path = decoder.codingPath.map { $0.stringValue }.joined(separator: ".")
        #if DEBUG
            print("❌ [MaybeString] decoding failed at '\(path)': unexpected type")
        #endif
            throw DecodingError.typeMismatch(
                MaybeString.self,
                .init(codingPath: decoder.codingPath, debugDescription: "Expected String, Int, or Double for MaybeString")
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let s): try container.encode(s)
        case .int(let i): try container.encode("\(i)")
        case .double(let d): try container.encode("\(d)")
        }
    }
}

public enum MaybeNumber: Codable {
    case int(Int)
    case double(Double)
    case string(String)

    public var asDouble: Double {
        switch self {
        case .int(let i): return Double(i)
        case .double(let d): return d
        case .string(let s): return Double(s) ?? 0
        }
    }
    public var asInt: Int {
        return Int(asDouble)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let path = decoder.codingPath.map { $0.stringValue }.joined(separator: ".")

        if let int = try? container.decode(Int.self) {
            self = .int(int)
        } else if let double = try? container.decode(Double.self) {
            self = .double(double)
        } else if let str = try? container.decode(String.self) {
#if DEBUG
            print("⚠️ [MaybeNumber] '\(path)' got String instead of Int/Double")
#endif
            self = .string(str)
        } else {
            throw DecodingError.typeMismatch(
                MaybeNumber.self,
                .init(
                    codingPath: decoder.codingPath,
                    debugDescription: "Expected Int, Double, or numeric String for MaybeNumber"
                )
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .int(_): try container.encode(asDouble)
        case .double(let d): try container.encode(d)
        case .string(let s): try container.encode(s)
        }
    }
}

public enum SometimeArray<T: Codable>: Codable {
    case one(T)
    case list([T])

    public var asArray: [T] {
        switch self {
        case .one(let t): return [t]
        case .list(let arr): return arr
        }
    }
    public static func make(_ value: T) -> SometimeArray<T> {
        .one(value)
    }
    
    public static func make(_ values: [T]) -> SometimeArray<T> {
        .list(values)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let arr = try? container.decode([T].self) {
            self = .list(arr)
        } else if let single = try? container.decode(T.self) {
            self = .one(single)
        } else {
            throw DecodingError.typeMismatch(SometimeArray.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected T or [T]"))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .one(let t):
            try container.encode(t)
        case .list(let arr):
            try container.encode(arr)
        }
    }
}
/// A value that insists it's never null.
/// But we know better.
public struct InsistsNonNull<T: Codable>: Codable {
    public let value: T?

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let decoded = try? container.decode(T.self) {
            self.value = decoded
        } else {
            let path = decoder.codingPath.map { $0.stringValue }.joined(separator: ".")
#if DEBUG
            print("⚠️ [InsistsNonNull] '\(path)' insisted it wouldn't be null... but it was.")
#endif
            self.value = nil
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
}

extension Data {
    func makeObj<T:Decodable>() -> T? {
        return try? JSONDecoder().decode(T.self, from: self)
    }
    func makeObj<T:Decodable>(type:T.Type) -> T? {
        return makeObj()
    }
    var dict:[String:Any]? {
        return try? JSONSerialization.jsonObject(with: self) as? [String:Any]
    }
    func string(encoding:String.Encoding = .utf8) -> String {
        return String(data: self, encoding: encoding) ?? ""
    }
}
extension String {
    var data:Data? {
        return data(using: .utf8)
    }
}
