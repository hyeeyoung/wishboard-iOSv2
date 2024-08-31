//
//  AlertViewController.swift
//  WishboardV2
//
//  Created by gomin on 8/25/24.
//

import Foundation
import UIKit
import SnapKit
import Then
import Core

final class AlertViewController: UIViewController {

    private let backgroundView = UIView().then {
        $0.backgroundColor = .black_4
        $0.alpha = 0.0
    }
    private let alertView = UIView().then {
        $0.backgroundColor = .white
        $0.layer.cornerRadius = 16
        $0.clipsToBounds = true
    }
    private let titleLabel = UILabel().then {
        $0.textColor = .gray_600
        $0.textAlignment = .center
        $0.font = TypoStyle.SuitH3.font
    }
    private let messageLabel = UILabel().then {
        $0.text = "message"
        $0.setTypoStyleWithMultiLine(typoStyle: .SuitD2)
        $0.textAlignment = .center
        $0.textColor = .gray_300
        $0.numberOfLines = 0
    }
    private let separatorLine = UIView().then {
        $0.backgroundColor = .gray_100
    }
    public let emailTextField = UITextField().then {
        $0.layer.cornerRadius = 6
        $0.backgroundColor = .gray_50
        $0.placeholder = "이메일을 입력하세요"
        $0.isHidden = true // 기본적으로 숨김, 필요 시 표시
        $0.setLeftPaddingPoints(12)
        $0.autocapitalizationType = .none
        $0.autocorrectionType = .no
        $0.clipsToBounds = true
        $0.clearButtonMode = .whileEditing
    }
    public let errorMessageLabel = UILabel().then {
        $0.text = "이메일을 다시 확인해 주세요."
        $0.setTypoStyleWithSingleLine(typoStyle: .SuitD3)
        $0.textAlignment = .left
        $0.textColor = .pink_700
        $0.isHidden = true
    }
    private let verticalSeparatorLine = UIView().then {
        $0.backgroundColor = .gray_100
    }
    private var buttons: [UIButton] = []

    var alertType: AlertType
    var customTitle: String?
    var customMessage: String?
    var customButtonTitles: [String] = []
    var customButtonColors: [UIColor] = []
    var buttonHandlers: [(UIButton) -> Void] = []
    
    init(alertType: AlertType) {
        self.alertType = alertType
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.modalTransitionStyle = .crossDissolve
        self.modalPresentationStyle = .overFullScreen
        
        setupViews()
        setupConstraints()
        animateAlertPresentation()
    }

    private func setupViews() {
        view.addSubview(backgroundView)
        view.addSubview(alertView)

        alertView.addSubview(titleLabel)
        alertView.addSubview(messageLabel)
        alertView.addSubview(separatorLine)
        
        titleLabel.text = customTitle ?? alertType.title
        messageLabel.text = customMessage ?? alertType.message
        
        // Email TextField는 회원탈퇴일 경우에만 표시
        if alertType == .accountDeletion {
            emailTextField.isHidden = false
            alertView.addSubview(emailTextField)
            alertView.addSubview(errorMessageLabel)
        }

        let titles = customButtonTitles.isEmpty ? alertType.buttonTitles : customButtonTitles
        let colors = customButtonColors.isEmpty ? alertType.buttonColors : customButtonColors

        for (index, title) in titles.enumerated() {
            let button = UIButton(type: .system).then {
                $0.setTitle(title, for: .normal)
                $0.setTitleColor(colors[index], for: .normal)
                $0.tag = index
                if alertType == .accountDeletion {
                    $0.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
                } else {
                    $0.addTarget(self, action: #selector(buttonTappedWithDismiss(_:)), for: .touchUpInside)
                }
            }
            buttons.append(button)
            alertView.addSubview(button)
        }

        if buttons.count == 2 {
            alertView.addSubview(verticalSeparatorLine)
        }
    }

    private func setupConstraints() {
        backgroundView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        alertView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(30)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(alertView).offset(24)
            make.leading.trailing.equalToSuperview().inset(16)
        }

        messageLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(16)
        }

        if alertType == .accountDeletion {
            emailTextField.snp.makeConstraints { make in
                make.top.equalTo(messageLabel.snp.bottom).offset(20)
                make.leading.trailing.equalToSuperview().inset(16)
                make.height.equalTo(42)
            }
            
            errorMessageLabel.snp.makeConstraints { make in
                make.top.equalTo(emailTextField.snp.bottom).offset(6)
                make.leading.equalTo(emailTextField)
            }

            separatorLine.snp.makeConstraints { make in
                make.top.equalTo(emailTextField.snp.bottom).offset(32)
                make.leading.trailing.equalTo(alertView)
                make.height.equalTo(0.5)
            }
        } else {
            separatorLine.snp.makeConstraints { make in
                make.top.equalTo(messageLabel.snp.bottom).offset(32)
                make.leading.trailing.equalTo(alertView)
                make.height.equalTo(0.5)
            }
        }

        if buttons.count == 1 {
            let button = buttons[0]
            button.snp.makeConstraints { make in
                make.height.equalTo(48)
                make.top.equalTo(separatorLine.snp.bottom)
                make.leading.trailing.bottom.equalToSuperview()
            }
        }

        if buttons.count == 2 {
            verticalSeparatorLine.snp.makeConstraints { make in
                make.top.equalTo(separatorLine.snp.bottom)
                make.bottom.centerX.equalTo(alertView)
                make.width.equalTo(0.5)
            }
            
            let leftButton = buttons[0]
            let righttButton = buttons[1]
            
            leftButton.snp.makeConstraints { make in
                make.height.equalTo(48)
                make.top.equalTo(separatorLine.snp.bottom)
                make.leading.bottom.equalToSuperview()
                make.trailing.equalTo(verticalSeparatorLine.snp.leading)
            }
            righttButton.snp.makeConstraints { make in
                make.height.equalTo(48)
                make.top.equalTo(separatorLine.snp.bottom)
                make.trailing.bottom.equalToSuperview()
                make.leading.equalTo(verticalSeparatorLine.snp.trailing)
            }
        }
    }

    @objc private func buttonTappedWithDismiss(_ sender: UIButton) {
        self.dismissAlert {
            self.buttonHandlers[sender.tag](sender)
        }
    }
    
    @objc private func buttonTapped(_ sender: UIButton) {
        self.buttonHandlers[sender.tag](sender)
    }

    private func animateAlertPresentation() {
        self.backgroundView.alpha = 1.0
        
        alertView.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        UIView.animate(withDuration: 0.2, animations: {
            self.alertView.transform = CGAffineTransform.identity
        })
    }

    func dismissAlert(completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.2, animations: {
            self.alertView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            self.alertView.alpha = 0.0
        }, completion: { _ in
            self.backgroundView.alpha = 0.0
            self.dismiss(animated: false, completion: completion)
        })
    }
}
