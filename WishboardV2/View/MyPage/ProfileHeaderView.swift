//
//  ProfileHeaderView.swift
//  WishboardV2
//
//  Created by gomin on 8/24/24.
//

import Foundation
import UIKit
import SnapKit
import Then
import Core

class ProfileHeaderView: UIView {
    
    // MARK: - View
    let profileImage = UIImageView().then{
        $0.image = Image.defaultProfile
        $0.clipsToBounds = true
        $0.layer.cornerRadius = 30
        $0.contentMode = .scaleAspectFill
    }
    let userNameLabel = UILabel().then{
        $0.setTypoStyleWithSingleLine(typoStyle: .SuitH2)
    }
    let emailLabel = UILabel().then{
        $0.setTypoStyleWithSingleLine(typoStyle: .SuitB3)
        $0.textColor = .gray_200
    }
    let modifyButton = UIButton().then{
        $0.setTitle("편집", for: .normal)
        $0.setTitleColor(UIColor.gray_600, for: .normal)
        $0.titleLabel?.setTypoStyleWithSingleLine(typoStyle: .SuitB3)
        $0.backgroundColor = UIColor.gray_100
        $0.titleEdgeInsets = UIEdgeInsets(top: 4, left: 10, bottom: 4, right: 10)
        
        $0.clipsToBounds = true
        $0.layer.cornerRadius = 12
    }
    let dividerView = UIView().then {
        $0.backgroundColor = .gray_50
    }
    
    // MARK: - Life Cycle
    
    public var moveModifyProfile: (() -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .white
        setupView()
        
        modifyButton.addTarget(self, action: #selector(modifyProfileTapped), for: .touchUpInside)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    // MARK: - Methods
    private func setupView() {
        addSubview(profileImage)
        addSubview(userNameLabel)
        addSubview(emailLabel)
        addSubview(modifyButton)
        addSubview(dividerView)
        
        // 프로필 뷰 설정 및 제약조건
        profileImage.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(34)
            make.width.height.equalTo(60)
            make.leading.equalToSuperview().offset(16)
        }
        userNameLabel.snp.makeConstraints { make in
            make.leading.equalTo(profileImage.snp.trailing).offset(16)
            make.top.equalToSuperview().offset(45)
        }
        emailLabel.snp.makeConstraints { make in
            make.top.equalTo(userNameLabel.snp.bottom).offset(8)
            make.leading.equalTo(userNameLabel)
        }
        modifyButton.snp.makeConstraints { make in
            make.width.equalTo(45)
            make.height.equalTo(24)
            make.top.equalToSuperview().offset(52)
            make.trailing.equalToSuperview().offset(-16)
        }
        dividerView.snp.makeConstraints { make in
            make.top.equalTo(profileImage.snp.bottom).offset(48)
            make.height.equalTo(6)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }
    
    func configure(with user: User) {
        profileImage.loadImage(from: user.profileImageUrl ?? "", placeholder: Image.defaultProfile)
        if let tempNickName = UserManager.tempNickname {
            userNameLabel.text = tempNickName
        } else {
            userNameLabel.text = user.nickname
        }
        emailLabel.text = user.email
    }
    
    @objc private func modifyProfileTapped() {
        self.moveModifyProfile?()
    }
}
