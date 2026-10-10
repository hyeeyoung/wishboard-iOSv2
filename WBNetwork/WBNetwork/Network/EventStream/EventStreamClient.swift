//
//  EventStreamClient.swift
//  WBNetwork
//
//  Created by gomin on 10/10/26.
//

import Foundation
import Core

/// 이벤트 스트림(SSE) 연결 하나를 맡습니다.
///
/// 브라우저의 `EventSource` 는 `Authorization` 헤더를 넣을 수 없어 `URLSession` 스트리밍을 씁니다.
/// 재연결 판단은 `EventStreamManager` 가 하고, 이 타입은 한 번의 연결만 다룹니다.
final class EventStreamClient: NSObject {

    /// 이벤트가 없으면 30초마다 heartbeat 만 오므로, 읽기 타임아웃을 넉넉히 둡니다.
    private static let timeout: TimeInterval = 120

    var onEvent: ((SSEParser.Event) -> Void)?
    /// 연결이 끝났을 때. 스트림이 열리기 전 실패면 `EventStreamFailure` 가 담깁니다.
    var onClose: ((Error?) -> Void)?

    private var session: URLSession?
    private var task: URLSessionDataTask?
    private var parser = SSEParser()

    /// 스트림이 열리기 전의 에러 응답을 모아 두었다가, 끝날 때 코드까지 읽어 전달합니다.
    private var failureStatusCode: Int?
    private var failureBody = Data()

    /// 이미 끊긴 연결에서 뒤늦게 오는 콜백을 흘려보내기 위한 표시
    private var isCancelled = false

    // MARK: - 연결

    func connect() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = EventStreamClient.timeout
        // 스트림은 계속 열려 있어야 하므로 전체 타임아웃을 두지 않습니다.
        configuration.timeoutIntervalForResource = .infinity
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData

        let session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        self.session = session

        let task = session.dataTask(with: makeRequest())
        self.task = task
        task.resume()
    }

    /// 연결을 닫습니다. 이후 콜백은 전달하지 않습니다.
    func cancel() {
        isCancelled = true
        onEvent = nil
        onClose = nil
        task?.cancel()
        session?.invalidateAndCancel()
        task = nil
        session = nil
    }

    private func makeRequest() -> URLRequest {
        let url = URL(string: "\(NetworkMacro.BaseURL)/events/subscribe")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")

        if let accessToken = UserManager.accessToken {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }
        if let deviceInfo = UserManager.deviceInfo {
            request.setValue(deviceInfo, forHTTPHeaderField: "Device-Info")
        }
        // 다른 v2 API 와 같은 형식입니다.
        if let userAgent = NetworkMacro.DeviceInfoHeader["User-Agent"] {
            request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        }
        // 배너의 최소 버전 판단에 쓰입니다. 없으면 최소 버전이 지정된 배너가 오지 않습니다.
        if let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            request.setValue(appVersion, forHTTPHeaderField: "App-Version")
        }

        return request
    }
}

// MARK: - URLSessionDataDelegate

extension EventStreamClient: URLSessionDataDelegate {

    func urlSession(_ session: URLSession,
                    dataTask: URLSessionDataTask,
                    didReceive response: URLResponse,
                    completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        guard let httpResponse = response as? HTTPURLResponse else {
            completionHandler(.allow)
            return
        }

        // 200이 아니면 스트림이 아니라 에러 응답입니다. 본문을 받아 코드까지 읽습니다.
        if httpResponse.statusCode != 200 {
            failureStatusCode = httpResponse.statusCode
        }

        completionHandler(.allow)
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        guard !isCancelled else { return }

        guard failureStatusCode == nil else {
            failureBody.append(data)
            return
        }

        parser.append(data).forEach { onEvent?($0) }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard !isCancelled else { return }

        if let statusCode = failureStatusCode {
            let code = (try? JSONDecoder().decode(APIError.self, from: failureBody))?.code
            onClose?(EventStreamFailure(statusCode: statusCode, code: code))
            return
        }

        onClose?(error)
    }
}
