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
/// 로띠와 'LOADING' 텍스트를 세로로 쌓은 컨테이너를
/// 노출 대상 영역의 정중앙에 배치합니다.
/// 로띠는 원본 크기 그대로 그리고, 텍스트와의 간격만 맞춥니다.
/// 앱 전체에서 이 타입 하나만 사용하고, 각 화면은 '어디를 덮을지'만 정합니다.
/// (`LoadingPresentable` 참고)
final class LoadingView: UIView {

    /// 로딩뷰 뒷배경
    enum Background {
        /// 흰 배경으로 완전히 덮습니다.
        case opaque
        /// 뒤 화면이 비치도록 흰색 70%로 덮습니다.
        case dimmed

        var color: UIColor {
            switch self {
            case .opaque: return .white_10
            case .dimmed: return .white_7
            }
        }
    }

    /// 로띠뷰와 'LOADING' 텍스트 사이 간격
    private static let spacing: CGFloat = 16

    private let animationView = LottieAnimationView(name: "lottie_three_dots_loading").then {
        // 로딩뷰가 떠 있는 동안에는 끊기지 않고 계속 반복 재생되어야 합니다.
        $0.loopMode = .loop
        // 앱이 백그라운드에 다녀와도 멈춘 채로 남지 않도록 복원합니다.
        $0.backgroundBehavior = .pauseAndRestore
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
        // 뒷배경은 노출 시점에 정하고, 로딩 중에는 뒤쪽 터치가 먹히지 않도록 막습니다.
        backgroundColor = Background.opaque.color
        isUserInteractionEnabled = true

        addSubview(contentStackView)

        // 로띠는 별도 크기 제약 없이 원본 크기(intrinsicContentSize)대로 그립니다.
        contentStackView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        // 화면에 다시 붙었는데 멈춰 있다면, 노출되어 있는 한 계속 돌도록 이어서 재생합니다.
        guard window != nil, !animationView.isAnimationPlaying else { return }
        animationView.play()
    }

    // MARK: - Animation

    /// 항상 첫 프레임부터 새로 재생합니다.
    /// (직전 노출에서 돌던 상태가 그대로 보이는 일이 없도록)
    private func startAnimating() {
        animationView.stop()
        animationView.currentProgress = 0
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

    /// 지정한 뷰를 덮어 로딩뷰를 노출합니다. 노출될 때마다 로띠는 첫 프레임부터 새로 재생됩니다.
    static func show(in container: UIView?, background: Background = .opaque) {
        guard let container = container else { return }

        // 이미 노출 중이라면 새로 만들지 않고 노출 요청 수만 올립니다.
        if let loadingView = container.currentLoadingView {
            loadingView.showCount += 1
            container.bringSubviewToFront(loadingView)
            return
        }

        let loadingView = LoadingView()
        loadingView.showCount = 1
        loadingView.backgroundColor = background.color

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
    static func setVisible(_ isVisible: Bool, in container: UIView?, background: Background = .opaque) {
        guard let container = container else { return }

        if isVisible {
            // 바인딩으로 같은 값이 여러 번 들어올 수 있어, 이미 노출 중이면 그대로 둡니다.
            guard container.currentLoadingView == nil else { return }
            show(in: container, background: background)
        } else {
            container.currentLoadingView?.dismiss()
        }
    }
}

// MARK: - 화면별 노출 영역

/// 로딩뷰를 노출할 영역을 가진 화면 뷰.
///
/// 로딩뷰는 `LoadingView` 하나만 쓰고, 각 화면은 '어디를 덮을지'만 정합니다.
/// 상단바는 가리지 않아야 하므로, 보통 상단바 아래쪽을 컨테이너로 잡습니다.
protocol LoadingPresentable: UIView {
    /// 로딩뷰가 덮을 영역.
    /// 로딩 중이 아닐 때 아래쪽 터치를 가로채지 않도록 `isUserInteractionEnabled = false`로 만들어 둡니다.
    var loadingContainerView: UIView { get }
    /// 로딩뷰 뒷배경. 기본은 흰 배경이고, 필요한 화면만 딤드로 덮습니다.
    var loadingBackground: LoadingView.Background { get }
}

extension LoadingPresentable {

    var loadingBackground: LoadingView.Background { .opaque }

    /// 조회 시작 시 호출합니다.
    func showLoading() {
        loadingContainerView.isUserInteractionEnabled = true
        LoadingView.show(in: loadingContainerView, background: loadingBackground)
    }

    /// 조회 종료 시 호출합니다. 아직 끝나지 않은 조회가 있다면 그대로 둡니다.
    func hideLoading() {
        LoadingView.hide(in: loadingContainerView)
        loadingContainerView.isUserInteractionEnabled = !loadingContainerView.subviews.isEmpty
    }

    /// 로딩 상태를 그대로 반영합니다. `@Published` 로딩 상태를 바인딩할 때 사용합니다.
    func setLoading(_ isLoading: Bool) {
        loadingContainerView.isUserInteractionEnabled = isLoading
        LoadingView.setVisible(isLoading, in: loadingContainerView, background: loadingBackground)
    }
}

private extension UIView {
    /// 이 뷰가 직접 들고 있는 로딩뷰
    var currentLoadingView: LoadingView? {
        subviews.last { $0 is LoadingView } as? LoadingView
    }
}
