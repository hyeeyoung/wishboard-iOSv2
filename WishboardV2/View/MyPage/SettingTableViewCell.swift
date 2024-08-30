//
//  SettingTableViewCell.swift
//  WishboardV2
//
//  Created by gomin on 8/24/24.
//

import Foundation
import UIKit
import SnapKit
import Then
import Core

class SettingTableViewCell: UITableViewCell {
    
    static let identifier = "SettingTableViewCell"
    
    // MARK: - Views
    
    private let titleLabel = UILabel().then {
        $0.setTypoStyleWithSingleLine(typoStyle: .SuitD1)
        $0.textColor = .gray_600
    }
    
    private let subTitleLabel = UILabel().then {
        var appVersionStr: String = Bundle.appVersion ?? ""
        // 디버그 모드일 때에만 빌드버전 노출
        #if DEBUG
        appVersionStr += "(\(Bundle.appBuildVersion ?? ""))"
        #endif
        $0.text = appVersionStr
        $0.setTypoStyleWithSingleLine(typoStyle: .MontserratB1)
        $0.textColor = .gray_300
    }
    private let switchControl = UISwitch().then {
        $0.onTintColor = .green_500
        $0.transform = CGAffineTransform(scaleX: 0.8, y: 0.75)
        $0.backgroundColor = UIColor.gray_300
        $0.layer.cornerRadius = 16.5
    }
    private let dividerView = UIView().then {
        $0.backgroundColor = .gray_50
    }
    
    // MARK: - Properties
    var switchChangedAction: ((Bool) -> Void)?
    
    // MARK: - Life Cycles
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    // MARK: - Methods
    
    private func setupView() {
        // 기본 셀 설정
        contentView.addSubview(titleLabel)
        contentView.addSubview(switchControl)
        contentView.addSubview(subTitleLabel)
        contentView.addSubview(dividerView)
        
        // titleLabel 설정
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
        }
        
        // switchControl 설정
        switchControl.isHidden = true
        switchControl.addTarget(self, action: #selector(switchValueChanged(_:)), for: .valueChanged)
        switchControl.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }
        
        // subTitle 설정
        subTitleLabel.isHidden = true
        subTitleLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }
        
        // divider 설정
        dividerView.isHidden = true
        dividerView.snp.makeConstraints { make in
            make.height.equalTo(6)
            make.top.equalTo(titleLabel.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview()
        }
    }
    
    func configure(with setting: Setting) {
        titleLabel.text = setting.title
        
        switch setting.type {
        case .normal(let showDivider):
            switchControl.isHidden = true
            subTitleLabel.isHidden = true
            dividerView.isHidden = !showDivider
        case .switch(let isOn, let showDivider):
            switchControl.isHidden = false
            subTitleLabel.isHidden = true
            switchControl.isOn = isOn
            dividerView.isHidden = !showDivider
        case .subTitle(let value, let showDivider):
            switchControl.isHidden = true
            subTitleLabel.isHidden = false
            dividerView.isHidden = !showDivider
        }
    }
    
    @objc private func switchValueChanged(_ sender: UISwitch) {
        // 스위치 값이 변경되었을 때 처리
        self.switchChangedAction?(sender.isOn)
    }
}
