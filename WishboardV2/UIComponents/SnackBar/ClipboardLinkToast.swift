//
//  ClipboardLinkToast.swift
//  WishboardV2
//
//  Created by gomin on 9/26/26.
//

import Foundation
import UIKit
import SnapKit
import Then
import Core

/// 클립보드에 복사해 둔 쇼핑몰 링크로 아이템 정보를 불러올지 묻는 토스트.
///
/// 올라오고 내려가는 애니메이션은 기존 `SnackBar`와 같지만
/// 높이 / 노출 시간 / 탭 동작이 달라 별도로 둡니다.
final class ClipboardLinkToast {

    /// 토스트 높이
    private static let height: CGFloat = 34
    /// 바텀 safe area로부터의 간격
    private static let bottomInset: CGFloat = 16
    /// 좌우 안쪽 여백
    private static let horizontalPadding: CGFloat = 16
    /// 두 문구 사이 간격
    private static let textSpacing: CGFloat = 10
    /// 노출 시간
    private static let visibleDuration: TimeInterval = 5
    private static let animationDuration: TimeInterval = 0.5

    // MARK: - Views

    private let backgroundView = UIView().then {
        $0.backgroundColor = .gray_600
        $0.clipsToBounds = true
        $0.layer.cornerRadius = ClipboardLinkToast.height / 2
        $0.alpha = 0.0
    }

    private let messageLabel = UILabel().then {
        $0.text = Message.clipboardShoppingLink
        $0.textColor = .gray_50
        $0.setTypoStyleWithSingleLine(typoStyle: .SuitB5)
    }

    private let actionLabel = UILabel().then {
        $0.text = Button.load
        $0.textColor = .green_500
        $0.setTypoStyleWithSingleLine(typoStyle: .SuitB5)
        $0.isUserInteractionEnabled = true
    }

    /// '불러오기' 탭 시 실행됩니다.
    private var onAction: (() -> Void)?
    /// 노출 시간이 끝나면 내리기 위한 작업. 탭하면 먼저 취소합니다.
    private var dismissWorkItem: DispatchWorkItem?

    // MARK: - Init

    init() {
        setupViews()
    }

    private func setupViews() {
        backgroundView.addSubview(messageLabel)
        backgroundView.addSubview(actionLabel)

        messageLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(ClipboardLinkToast.horizontalPadding)
            make.centerY.equalToSuperview()
        }
        actionLabel.snp.makeConstraints { make in
            make.leading.equalTo(messageLabel.snp.trailing).offset(ClipboardLinkToast.textSpacing)
            make.trailing.equalToSuperview().offset(-ClipboardLinkToast.horizontalPadding)
            make.centerY.equalToSuperview()
        }

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(actionTapped))
        actionLabel.addGestureRecognizer(tapGesture)
    }

    // MARK: - 노출 / 미노출

    /// 토스트를 올려 노출하고, 일정 시간 뒤 자동으로 내립니다.
    /// - Parameter onAction: '불러오기'를 탭했을 때 실행할 동작
    func show(in view: UIView, onAction: @escaping () -> Void) {
        // 이미 떠 있다면 중복해서 올리지 않습니다.
        guard backgroundView.alpha == 0.0 else { return }

        self.onAction = onAction

        view.addSubview(backgroundView)
        backgroundView.snp.remakeConstraints { make in
            make.height.equalTo(ClipboardLinkToast.height)
            make.centerX.equalToSuperview()
            make.leading.greaterThanOrEqualToSuperview().offset(16)
            make.trailing.lessThanOrEqualToSuperview().offset(-16)
            // 화면 밖 아래에서 시작해 위로 올라옵니다.
            make.top.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
        view.layoutIfNeeded()

        let translationY = -(ClipboardLinkToast.height + ClipboardLinkToast.bottomInset)

        UIView.animate(withDuration: ClipboardLinkToast.animationDuration,
                       delay: 0,
                       options: .curveEaseIn) {
            self.backgroundView.transform = CGAffineTransform(translationX: 0, y: translationY)
            self.backgroundView.alpha = 1.0
        }

        let workItem = DispatchWorkItem { [weak self] in
            self?.dismiss()
        }
        dismissWorkItem = workItem
        DispatchQueue.main.asyncAfter(
            deadline: .now() + ClipboardLinkToast.animationDuration + ClipboardLinkToast.visibleDuration,
            execute: workItem
        )
    }

    /// 토스트를 내립니다.
    func dismiss() {
        dismissWorkItem?.cancel()
        dismissWorkItem = nil

        guard backgroundView.alpha != 0.0 else { return }

        UIView.animate(withDuration: ClipboardLinkToast.animationDuration,
                       delay: 0,
                       options: .curveEaseOut) {
            self.backgroundView.transform = .identity
            self.backgroundView.alpha = 0.0
        } completion: { _ in
            self.backgroundView.removeFromSuperview()
        }
    }

    // MARK: - Action

    @objc private func actionTapped() {
        UIDevice.vibrate()

        let action = onAction
        onAction = nil
        dismiss()
        action?()
    }
}
