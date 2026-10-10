//
//  EventStreamManager.swift
//  WBNetwork
//
//  Created by gomin on 10/10/26.
//

import Foundation
import Combine
import Core

/// 이벤트 스트림(SSE) 연결의 수명과 재연결을 맡습니다.
///
/// 포그라운드에서 로그인 상태일 때만 연결합니다. 백그라운드 알림은 기존 푸시가 맡습니다.
public final class EventStreamManager {

    public static let shared = EventStreamManager()

    /// 안읽은 알림 개수. 연결 직후 한 번, 이후 바뀔 때마다 갱신됩니다.
    @Published public private(set) var unreadCount: Int = 0
    /// 안읽은 알림이 있는지 여부
    @Published public private(set) var hasUnread: Bool = false

    /// 재연결 지연의 하한·상한
    private static let minRetryDelay: TimeInterval = 1
    private static let maxRetryDelay: TimeInterval = 5
    /// 연속 실패가 이어질 때의 최대 대기
    private static let maxBackoffDelay: TimeInterval = 60

    private var client: EventStreamClient?
    /// 다음 재연결까지의 대기 시간. 첫 이벤트를 받으면 초기화합니다.
    private var backoffDelay: TimeInterval = 0
    private var retryWorkItem: DispatchWorkItem?
    /// 연결을 유지해야 하는 상태인지. `stop()` 이후의 콜백으로 되살아나지 않게 합니다.
    private var isActive = false

    /// 상태를 한 줄로 다루기 위한 큐
    private let queue = DispatchQueue(label: "com.wishboard.eventstream")

    private init() { }

    // MARK: - 수명

    /// 포그라운드 진입·로그인 직후에 호출합니다. 이미 연결 중이면 아무 일도 하지 않습니다.
    public func start() {
        queue.async { [weak self] in
            guard let self = self else { return }
            guard UserManager.accessToken != nil else { return }
            guard !self.isActive else { return }

            self.isActive = true
            self.backoffDelay = 0
            self.connect()
        }
    }

    /// 백그라운드 진입·로그아웃에서 호출합니다.
    public func stop() {
        queue.async { [weak self] in
            guard let self = self else { return }
            self.isActive = false
            self.cancelPendingRetry()
            self.closeCurrentConnection()
        }
    }

    // MARK: - 연결

    private func connect() {
        // 옛 연결을 먼저 닫습니다. 남겨 두면 그쪽의 REPLACED 를 보고 다시 붙는 루프가 생깁니다.
        closeCurrentConnection()

        let client = EventStreamClient()
        client.onEvent = { [weak self] event in
            self?.queue.async { self?.handle(event: event) }
        }
        client.onClose = { [weak self] error in
            self?.queue.async { self?.handleClose(error: error) }
        }

        self.client = client
        client.connect()
    }

    private func closeCurrentConnection() {
        client?.cancel()
        client = nil
    }

    private func cancelPendingRetry() {
        retryWorkItem?.cancel()
        retryWorkItem = nil
    }

    // MARK: - 이벤트

    private func handle(event: SSEParser.Event) {
        // 연결이 살아 있다는 뜻이므로 백오프를 되돌립니다.
        backoffDelay = 0

        guard let name = EventStreamName(rawValue: event.name) else { return } // 모르는 이벤트는 무시
        guard let data = event.data.data(using: .utf8) else { return }

        switch name {
        case .unreadStatus:
            // TODO: 이 개수는 v3 알림 탭 기준이라 시스템 알림(공지)이 포함됩니다.
            // 알림 탭이 아직 v2라 개수와 목록이 어긋날 수 있습니다. (NotiAPI 의 TODO 참고)
            guard let status = try? JSONDecoder().decode(UnreadStatusEvent.self, from: data) else { return }
            let count = status.unreadCount ?? 0
            let hasUnread = status.hasUnread ?? (count > 0)

            DispatchQueue.main.async { [weak self] in
                self?.unreadCount = count
                self?.hasUnread = hasUnread
            }

        case .banners:
            // 배너는 아직 연동하지 않습니다. (기획·디자인 합의 전)
            break

        case .reconnect:
            let event = try? JSONDecoder().decode(ReconnectEvent.self, from: data)
            handleReconnect(reason: ReconnectReason(rawValue: event?.reason))
        }
    }

    /// 서버가 연결을 닫겠다고 알려 온 경우
    private func handleReconnect(reason: ReconnectReason) {
        // 이어서 올 종료 콜백으로 또 재연결하지 않도록 지금 연결을 끊어 둡니다.
        closeCurrentConnection()

        guard isActive, reason.shouldReconnect else {
            isActive = false
            return
        }

        switch reason {
        case .tokenExpiring:
            // 같은 토큰으로 다시 붙으면 곧바로 또 만료 안내가 오므로, 갱신 후에 붙습니다.
            refreshTokenAndReconnect()
        default:
            scheduleReconnect()
        }
    }

    /// 연결이 끊어진 경우
    private func handleClose(error: Error?) {
        closeCurrentConnection()
        guard isActive else { return }

        if let failure = error as? EventStreamFailure {
            handleFailure(failure)
            return
        }

        // 네트워크 단절 등. 잠시 뒤 다시 붙습니다.
        scheduleReconnect()
    }

    /// 스트림이 열리기 전에 실패한 경우
    private func handleFailure(_ failure: EventStreamFailure) {
        guard failure.statusCode == 401 else {
            // 400·403·404 는 다시 시도해도 같아 연결을 포기하고,
            // 503 등 일시적인 실패는 간격을 늘려 가며 다시 붙습니다.
            if failure.statusCode == 503 {
                scheduleReconnect()
            } else {
                isActive = false
            }
            return
        }

        switch failure.code {
        case "TOKEN_EXPIRED":
            refreshTokenAndReconnect()
        case "INVALID_TOKEN", "NOT_FOUND_USER":
            signOut(with: .invalidUser)
        case "LOGOUT_BY_DEVICE_OVERFLOW":
            signOut(with: .logoutByDeviceOverflow)
        case "INVALID_FCM_TOKEN":
            signOut(with: .invalidFcmToken)
        default:
            signOut(with: .refreshTokenFailed)
        }
    }

    // MARK: - 재연결

    /// 1~5초 사이로 흩뜨려 붙되, 연속 실패하면 간격을 늘립니다. (최대 60초)
    private func scheduleReconnect() {
        cancelPendingRetry()

        let delay: TimeInterval
        if backoffDelay == 0 {
            delay = TimeInterval.random(in: EventStreamManager.minRetryDelay...EventStreamManager.maxRetryDelay)
        } else {
            delay = min(backoffDelay * 2, EventStreamManager.maxBackoffDelay)
        }
        backoffDelay = delay

        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self, self.isActive else { return }
            self.connect()
        }
        retryWorkItem = workItem
        queue.asyncAfter(deadline: .now() + delay, execute: workItem)
    }

    private func refreshTokenAndReconnect() {
        _Concurrency.Task { [weak self] in
            guard let self = self else { return }

            guard let accessToken = UserManager.accessToken,
                  let refreshToken = UserManager.refreshToken else {
                self.queue.async { self.signOut(with: .refreshTokenFailed) }
                return
            }

            do {
                let usecase = RefreshTokenUseCase(repository: AuthRepository())
                let data = try await usecase.execute(accessToken: accessToken, refreshToken: refreshToken)

                guard let newAccessToken = data.accessToken,
                      let newRefreshToken = data.refreshToken else {
                    self.queue.async { self.signOut(with: .refreshTokenFailed) }
                    return
                }

                UserManager.accessToken = newAccessToken
                UserManager.refreshToken = newRefreshToken

                self.queue.async {
                    guard self.isActive else { return }
                    self.connect()
                }
            } catch {
                self.queue.async { self.signOut(with: .refreshTokenFailed) }
            }
        }
    }

    /// 더 이상 붙을 수 없는 상태입니다. 로그인 화면으로 보냅니다.
    private func signOut(with snackBarType: SnackBarType) {
        isActive = false
        cancelPendingRetry()
        closeCurrentConnection()

        UserManager.removeUserData()
        NotificationCenter.default.post(name: .SignOutAndShowToast,
                                        object: nil,
                                        userInfo: ["SnackBarType": snackBarType])
    }
}
