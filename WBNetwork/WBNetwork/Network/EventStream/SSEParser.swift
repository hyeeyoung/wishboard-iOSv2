//
//  SSEParser.swift
//  WBNetwork
//
//  Created by gomin on 10/10/26.
//

import Foundation

/// 서버가 흘려보내는 바이트를 SSE 이벤트 단위로 끊어 줍니다.
///
/// 이벤트 하나는 `event:` 줄과 `data:` 줄로 이루어지고 빈 줄로 끝납니다.
/// `:` 로 시작하는 줄은 주석(heartbeat)이라 버립니다.
struct SSEParser {

    struct Event {
        let name: String
        let data: String
    }

    /// 아직 줄 끝을 만나지 못한 조각
    private var buffer = Data()
    private var currentName: String?
    private var currentDataLines: [String] = []

    /// 받은 조각을 넣고, 완성된 이벤트들을 돌려줍니다.
    mutating func append(_ data: Data) -> [Event] {
        buffer.append(data)

        var events: [Event] = []

        while let newlineIndex = buffer.firstIndex(of: 0x0A) { // \n
            let lineData = buffer[buffer.startIndex..<newlineIndex]
            buffer.removeSubrange(buffer.startIndex...newlineIndex)

            // CRLF 로 와도 줄 끝의 \r 은 떼어 냅니다.
            var line = String(decoding: lineData, as: UTF8.self)
            if line.hasSuffix("\r") { line.removeLast() }

            if let event = handle(line: line) {
                events.append(event)
            }
        }

        return events
    }

    /// 한 줄을 처리하고, 이벤트가 끝났다면 그 이벤트를 돌려줍니다.
    private mutating func handle(line: String) -> Event? {
        // 빈 줄이면 지금까지 모은 것이 이벤트 하나입니다.
        guard !line.isEmpty else {
            defer {
                currentName = nil
                currentDataLines = []
            }

            guard let name = currentName, !currentDataLines.isEmpty else { return nil }
            return Event(name: name, data: currentDataLines.joined(separator: "\n"))
        }

        // 주석(:heartbeat)은 버립니다.
        guard !line.hasPrefix(":") else { return nil }

        guard let colonIndex = line.firstIndex(of: ":") else { return nil }
        let field = String(line[line.startIndex..<colonIndex])
        var value = String(line[line.index(after: colonIndex)...])
        // 콜론 뒤 공백 하나는 구분자라 떼어 냅니다.
        if value.hasPrefix(" ") { value.removeFirst() }

        switch field {
        case "event": currentName = value
        case "data":  currentDataLines.append(value)
        default:      break // id·retry 등 쓰지 않는 필드
        }

        return nil
    }
}
