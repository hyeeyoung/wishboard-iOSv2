//
//  LogTaskManager.swift
//  WBNetwork
//
//  Created by gomin on 8/9/25.
//

import Moya

// MARK: - Pretty request logger (Task 전용)
func logTask<T: TargetType>(_ target: T) {
    let prefix = "📤 Request Body"
    switch target.task {
    case .requestPlain:
        print("\(prefix): <empty>")
        
    case let .requestData(data):
        print("\(prefix): data \(data.count.humanBytes)")
        if let json = try? JSONSerialization.jsonObject(with: data),
           let pretty = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted),
           let str = String(data: pretty, encoding: .utf8) {
            print(str)
        } else if let str = String(data: data, encoding: .utf8) {
            print(str)
        }

    case let .requestParameters(parameters, encoding):
        print("\(prefix): parameters (\(encoding))")
        if let data = try? JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted),
           let str = String(data: data, encoding: .utf8) {
            print(str)
        } else {
            print(parameters)
        }

    case let .requestJSONEncodable(encodable):
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let data = try? encoder.encode(AnyEncodable(encodable)) {
            print("\(prefix): json \(data.count.humanBytes)")
            print(String(data: data, encoding: .utf8) ?? "")
        } else {
            print("\(prefix): <json encodable>")
        }
        
    case let .uploadMultipart(multipart):
        print("\(prefix): multipart (\(multipart.count) parts)")
        for (idx, part) in multipart.enumerated() {
            let name = part.name
            let fileName = part.fileName ?? "-"
            let mime = part.mimeType ?? "-"
            let size: String = {
                switch part.provider {
                case .data(let d): return d.count.humanBytes
                case .file(let url):
                    let bytes = (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? NSNumber)?.intValue ?? 0
                    return bytes.humanBytes
                case .stream(_, _): return "stream"
                @unknown default: return "unknown"
                }
            }()
            print("  [\(idx)] name=\(name), fileName=\(fileName), mime=\(mime), size=\(size)")
            
            // JSON 파트 내용이 보이는 게 좋다면 선택적으로 preview
            if name.lowercased() == "request",
               case .data(let d) = part.provider,
               let json = try? JSONSerialization.jsonObject(with: d),
               let pretty = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted),
               let str = String(data: pretty, encoding: .utf8) {
                print("  └─ \(name) json:\n\(str)")
            }
        }

    case let .uploadCompositeMultipart(multipart, urlParameters):
        print("\(prefix): composite multipart")
        // 멀티파트 파트들
        if let target = T.self as? T {
            logTask(target) // 사용 불가 트릭이니 아래처럼 분리해서 출력
            print("  URL parameters:")
            if let data = try? JSONSerialization.data(withJSONObject: urlParameters, options: .prettyPrinted),
               let str = String(data: data, encoding: .utf8) {
                print(str)
            } else {
                print(urlParameters)
            }
        } else {
            print(target.task)
        }

    case let .requestCompositeData(bodyData, urlParameters):
        print("\(prefix): composite data body \(bodyData.count.humanBytes)")
        if let json = try? JSONSerialization.jsonObject(with: bodyData),
           let pretty = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted),
           let str = String(data: pretty, encoding: .utf8) {
            print(str)
        }
        print("  URL parameters: \(urlParameters)")

    case let .requestCompositeParameters(bodyParameters, bodyEncoding, urlParameters):
        print("\(prefix): composite parameters (body: \(bodyEncoding))")
        if let data = try? JSONSerialization.data(withJSONObject: bodyParameters, options: .prettyPrinted),
           let str = String(data: data, encoding: .utf8) {
            print(str)
        } else {
            print(bodyParameters)
        }
        print("  URL parameters: \(urlParameters)")
        
    default:
        print(target.task)
    }
    
}

// MARK: - helpers
struct AnyEncodable: Encodable {
    private let encodeFunc: (Encoder) throws -> Void
    init(_ value: Encodable) { self.encodeFunc = value.encode }
    func encode(to encoder: Encoder) throws { try encodeFunc(encoder) }
}

extension Int {
    var humanBytes: String {
        let units = ["B","KB","MB","GB"]
        var size = Double(self)
        var idx = 0
        while size >= 1024 && idx < units.count - 1 {
            size /= 1024; idx += 1
        }
        return String(format: "%.2f %@", size, units[idx])
    }
}
