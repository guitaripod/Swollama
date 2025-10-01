import Foundation


public struct OllamaModelName {

    public let namespace: String?

    public let name: String

    public let tag: String






    public init(namespace: String? = nil, name: String, tag: String = "latest") {
        self.namespace = namespace
        self.name = name
        self.tag = tag
    }




    public static func parse(_ string: String) -> OllamaModelName? {
        let components = string.split(separator: "/")
        switch components.count {
        case 1:
            let nameComponents = components[0].split(separator: ":")
            guard let name = nameComponents.first else { return nil }
            let tag = nameComponents.count > 1 ? String(nameComponents[1]) : "latest"
            return OllamaModelName(name: String(name), tag: tag)
        case 2:
            let nameComponents = components[1].split(separator: ":")
            guard let name = nameComponents.first else { return nil }
            let tag = nameComponents.count > 1 ? String(nameComponents[1]) : "latest"
            return OllamaModelName(namespace: String(components[0]), name: String(name), tag: tag)
        default:
            return nil
        }
    }


    public var fullName: String {
        if let namespace = namespace {
            return "\(namespace)/\(name):\(tag)"
        }
        return "\(name):\(tag)"
    }
}
