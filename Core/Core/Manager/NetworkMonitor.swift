//
//  NetworkMonitor.swift
//  Core
//
//  Created by gomin on 4/5/25.
//

import Foundation
import Network

public final class NetworkMonitor {
    public static let shared = NetworkMonitor()

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")

    public var isConnected: Bool = true {
        didSet {
            if oldValue != isConnected {
                // 연결 상태가 바뀌면 Notification 발송
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .NetworkStatusChanged, object: self.isConnected)
                }
            }
        }
    }

    public func startMonitoring() {
        monitor.pathUpdateHandler = { path in
            self.isConnected = (path.status == .satisfied)
        }
        monitor.start(queue: queue)
    }

    public func stopMonitoring() {
        monitor.cancel()
    }
}
