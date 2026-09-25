//
//  LoadingView.swift
//  WishboardV2
//
//  Created by gomin on 9/25/26.
//

import Foundation
import UIKit
import SnapKit
import Then
import Lottie
import Core

/// 조회 API 호출 동안 노출되는 공통 로딩뷰.
///
/// 로띠(가로 40 * 세로 15)와 'LOADING' 텍스트를 세로로 쌓은 컨테이너를
/// 노출 대상 영역의 정중앙에 배치합니다.
/// 보통은 화면 전체를 덮지만, 캘린더처럼 일부 영역만 가려야 하는 화면에서는
/// 해당 영역의 뷰를 `show(in:)`에 넘겨 그 안에서만 노출할 수 있습니다.
final class LoadingView: UIView {

    /// 로띠뷰 고정 크기
    private static let animationSize = CGSize(width: 40, height: 15)
    /// 로띠뷰와 'LOADING' 텍스트 사이 간격
    private static let spacing: CGFloat = 16

    private let animationView = LottieAnimationView(name: "lottie_three_dots_loading").then {
        $0.loopMode = .loop
        $0.contentMode = .scaleAspectFit
        $0.isUserInteractionEnabled = false
    }

    private let loadingLabel = UILabel().then {
        $0.text = "LOADING"
        $0.textColor = .gray_700
        $0.textAlignment = .center
        $0.setTypoStyleWithSingleLine(typoStyle: .SuitD2)
    }

    private lazy var contentStackView = UIStackView(arrangedSubviews: [animationView, loadingLabel]).then {
        $0.axis = .vertical
        $0.alignment = .center
        $0.spacing = LoadingView.spacing
        $0.isUserInteractionEnabled = false
    }

    /// 같은 영역에서 조회가 여러 개 동시에 돌 수 있어, 모두 끝났을 때만 내리도록 노출 요청 수를 셉니다.
    private var showCount: Int = 0

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        // 뒷배경은 흰색으로 덮고, 로딩 중에는 뒤쪽 터치가 먹히지 않도록 막습니다.
        backgroundColor = .white
        isUserInteractionEnabled = true

        addSubview(contentStackView)

        animationView.snp.makeConstraints { make in
            make.width.equalTo(LoadingView.animationSize.width)
            make.height.equalTo(LoadingView.animationSize.height)
        }

        contentStackView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }

    // MARK: - Animation

    private func startAnimating() {
        animationView.play()
    }

    private func stopAnimating() {
        animationView.stop()
    }

    /// 남은 노출 요청과 무관하게 즉시 내립니다.
    fileprivate func dismiss() {
        showCount = 0
        stopAnimating()
        removeFromSuperview()
    }
}

// MARK: - 노출 / 미노출

extension LoadingView {

    /// 지정한 뷰를 덮어 로딩뷰를 노출합니다.
    /// - Parameter container: 로딩뷰가 덮을 영역. 화면 전체라면 `viewController.view`를 넘깁니다.
    static func show(in container: UIView?) {
        guard let container = container else { return }

        // 이미 노출 중이라면 새로 만들지 않고 노출 요청 수만 올립니다.
        if let loadingView = container.currentLoadingView {
            loadingView.showCount += 1
            container.bringSubviewToFront(loadingView)
            return
        }

        let loadingView = LoadingView()
        loadingView.showCount = 1

        container.addSubview(loadingView)
        loadingView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        loadingView.startAnimating()
    }

    /// `show(in:)`으로 노출한 로딩뷰를 내립니다. 아직 끝나지 않은 조회가 있다면 그대로 둡니다.
    static func hide(in container: UIView?) {
        guard let container = container, let loadingView = container.currentLoadingView else { return }

        loadingView.showCount -= 1
        guard loadingView.showCount <= 0 else { return }

        loadingView.dismiss()
    }

    /// 로딩 상태를 그대로 반영합니다. `@Published` 로딩 상태를 바인딩할 때 사용합니다.
    static func setVisible(_ isVisible: Bool, in container: UIView?) {
        guard let container = container else { return }

        if isVisible {
            // 바인딩으로 같은 값이 여러 번 들어올 수 있어, 이미 노출 중이면 그대로 둡니다.
            guard container.currentLoadingView == nil else { return }
            show(in: container)
        } else {
            container.currentLoadingView?.dismiss()
        }
    }
}

private extension UIView {
    /// 이 뷰가 직접 들고 있는 로딩뷰
    var currentLoadingView: LoadingView? {
        subviews.last { $0 is LoadingView } as? LoadingView
    }
}
