//
//  HomeToolBar.swift
//  WishboardV2
//
//  Created by gomin on 8/17/24.
//

import Foundation
import UIKit
import SnapKit
import Then
import Core

public enum GridColumnType: Int {
    case one = 1
    case two = 2
    case three = 3

    var next: GridColumnType {
        switch self {
        case .one: return .two
        case .two: return .three
        case .three: return .one
        }
    }

    var iconName: String {
        switch self {
        case .one: return "list.bullet"
        case .two: return "square.grid.2x2"
        case .three: return "square.grid.3x3"
        }
    }
}

public protocol HomeToolBarDelegate: AnyObject {
    func alarmNaviItemTap()
    func itemSelectNaviItemTap()
}

final public class HomeToolBar: UIView {

    /// 뱃지 글자와 배경 사이의 여백
    private static let badgeVerticalPadding: CGFloat = 1
    private static let badgeHorizontalPadding: CGFloat = 2
    /// 종 아이콘의 모서리 바깥으로 걸치는 정도
    private static let badgeOffset: CGFloat = 5
    /// 뱃지에 그대로 표시하는 최대 개수. 이보다 많으면 `99+`로 줄입니다.
    private static let maxBadgeCount: Int = 99

    weak public var delegate: HomeToolBarDelegate?
    
    // MARK: - Views
    private let logo = UIImageView().then {
        $0.image = Image.homeLogo
    }
    
    private let alarmButton = UIButton().then {
        $0.tintColor = .gray_700
        $0.setImage(Image.notice, for: .normal)
    }
    
    /// 읽지 않은 알림 개수 뱃지. 개수가 없으면 노출하지 않습니다.
    private let alarmBadgeView = UIView().then {
        $0.backgroundColor = .pink_700
        $0.clipsToBounds = true
        $0.isUserInteractionEnabled = false
        $0.isHidden = true
    }

    private let alarmBadgeLabel = UILabel().then {
        $0.textColor = .white_10
        $0.textAlignment = .center
        $0.font = TypoStyle.SuitB3.font
    }

    /// 아이템 다중 선택 진입 버튼
    private let itemSelectButton = UIButton().then {
        $0.setImage(Image.tabBarCheck, for: .normal)
    }
    
    // MARK: - Initializer
    public init() {
        super.init(frame: .zero)
        self.backgroundColor = .white
        
        setupViews()
        setupConstraints()
        setupActions()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupViews() {
        addSubview(logo)
        addSubview(alarmButton)
        addSubview(itemSelectButton)
        addSubview(alarmBadgeView)
        alarmBadgeView.addSubview(alarmBadgeLabel)
    }
    
    private func setupConstraints() {
        logo.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.equalTo(110.44)
            make.height.equalTo(19.17)
        }
        
        alarmButton.snp.makeConstraints { make in
            make.width.height.equalTo(24)
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }
        
        itemSelectButton.snp.makeConstraints { make in
            make.width.height.equalTo(24)
            make.trailing.equalTo(alarmButton.snp.leading).offset(-18)
            make.centerY.equalToSuperview()
        }

        // 종 아이콘의 위/오른쪽 모서리에서 5만큼 바깥으로 걸칩니다.
        // 크기는 글자 + 여백으로 정해지되, 한 자리 수에서 세로로 길쭉해 보이지 않도록
        // 너비는 높이 이상을 유지합니다. (너비 제약은 그보다 우선순위를 낮게 둡니다)
        alarmBadgeView.snp.makeConstraints { make in
            make.top.trailing.equalTo(alarmButton).inset(-HomeToolBar.badgeOffset)
            make.height.equalTo(alarmBadgeLabel.snp.height).offset(HomeToolBar.badgeVerticalPadding * 2)
            make.width.greaterThanOrEqualTo(alarmBadgeView.snp.height)
            make.width.equalTo(alarmBadgeLabel.snp.width)
                .offset(HomeToolBar.badgeHorizontalPadding * 2)
                .priority(.high)
        }

        alarmBadgeLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        // 글자 크기에 따라 높이가 달라져도 둥근 형태를 유지합니다.
        alarmBadgeView.layer.cornerRadius = alarmBadgeView.bounds.height / 2
    }

    // MARK: - Setup Actions
    private func setupActions() {
        alarmButton.addTarget(self, action: #selector(alarmButtonTapped), for: .touchUpInside)
        itemSelectButton.addTarget(self, action: #selector(itemSelectButtonTapped), for: .touchUpInside)
    }

    // MARK: - Button Actions
    @objc private func alarmButtonTapped() {
        delegate?.alarmNaviItemTap()
    }
    
    @objc private func itemSelectButtonTapped() {
        delegate?.itemSelectNaviItemTap()
    }
    
    public func configure() {
        self.snp.makeConstraints { make in
            make.height.equalTo(52)
            make.top.leading.trailing.equalToSuperview()
        }
    }

    /// 읽지 않은 알림 개수를 뱃지에 반영합니다.
    ///
    /// 개수가 없으면 뱃지를 감춥니다. 개수를 가져오는 쪽(실시간 수신)은 아직 연결되어 있지 않습니다.
    public func updateAlarmBadge(count: Int) {
        guard count > 0 else {
            alarmBadgeView.isHidden = true
            alarmBadgeLabel.text = nil
            return
        }

        alarmBadgeView.isHidden = false
        alarmBadgeLabel.text = count > HomeToolBar.maxBadgeCount
            ? "\(HomeToolBar.maxBadgeCount)+"
            : "\(count)"
    }
}

// MARK: - HomeToolBarHeaderView

final class HomeToolBarHeaderView: UICollectionReusableView {
    static let reuseIdentifier = "HomeToolBarHeaderView"

    let toolBar = HomeToolBar()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(toolBar)
        toolBar.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(banner: HomeEventBannerView?, bannerHeight: CGFloat) {
        if let banner = banner {
            if banner.superview != self {
                addSubview(banner)
            }
            banner.snp.remakeConstraints { make in
                make.top.leading.trailing.equalToSuperview()
                make.height.equalTo(bannerHeight)
            }
            toolBar.snp.remakeConstraints { make in
                make.top.equalTo(banner.snp.bottom)
                make.leading.trailing.bottom.equalToSuperview()
            }
        } else {
            subviews.filter { $0 is HomeEventBannerView }.forEach { $0.removeFromSuperview() }
            toolBar.snp.remakeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
    }
}
