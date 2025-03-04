//
//  EmailInputViewController.swift
//  WishboardV2
//
//  Created by gomin on 3/4/25.
//

import Foundation
import UIKit
import Combine
import SnapKit
import Core

class EmailInputViewController: UIViewController {
    
    private let viewModel = EmailInputViewModel()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - UI Components
    
    private let toolBar = EmailInputToolBar()
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage.loveLetter
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.text = "가입하신 이메일을 입력해주세요!\n로그인을 위해 인증코드가 포함된 이메일을 보내드려요."
        label.textAlignment = .center
        label.font = TypoStyle.SuitD2.font
        label.textColor = .gray_700
        label.numberOfLines = 0
        return label
    }()
    
    private let emailTextField: UITextField = {
        let textField = UITextField()
        textField.borderStyle = .none
        textField.placeholder = "이메일을 입력해 주세요."
        textField.keyboardType = .emailAddress
        textField.setLeftPaddingPoints(16)
        textField.layer.cornerRadius = 6
        textField.backgroundColor = .gray_50
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        return textField
    }()
    
    private let errorLabel: UILabel = {
        let label = UILabel()
        label.text = "올바른 이메일 형식이 아닙니다."
        label.textColor = .pink_700
        label.font = TypoStyle.SuitD3.font
        label.isHidden = true
        return label
    }()
    
    private let actionButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("인증메일 받기", for: .normal)
        button.titleLabel?.font = TypoStyle.SuitH3.font
        button.setTitleColor(.gray_200, for: .disabled)
        button.setTitleColor(.gray_700, for: .normal)
        button.backgroundColor = .gray_100
        button.layer.cornerRadius = 12
        button.isEnabled = false
        return button
    }()
    
    private var keyboardHeight: CGFloat = 0.0
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
        setupKeyboardObservers()
        
        // 화면 진입 시 키보드 자동 띄우기
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.emailTextField.becomeFirstResponder()
        }
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .white
        
        view.addSubview(toolBar)
        view.addSubview(imageView)
        view.addSubview(descriptionLabel)
        view.addSubview(emailTextField)
        view.addSubview(errorLabel)
        view.addSubview(actionButton)
        
        toolBar.snp.makeConstraints { make in
            make.height.equalTo(42)
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
        }
        
        toolBar.configure(title: "이메일로 로그인하기")
        
        imageView.snp.makeConstraints { make in
            make.top.equalTo(toolBar.snp.bottom).offset(14)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(72)
        }
        
        descriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(imageView.snp.bottom).offset(10)
            make.centerX.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(36)
        }
        
        emailTextField.snp.makeConstraints { make in
            make.top.equalTo(descriptionLabel.snp.bottom).offset(32)
            make.left.right.equalToSuperview().inset(16)
            make.height.equalTo(42)
        }
        
        errorLabel.snp.makeConstraints { make in
            make.top.equalTo(emailTextField.snp.bottom).offset(6)
            make.leading.equalTo(emailTextField)
        }
        
        actionButton.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(16)
            make.height.equalTo(50)
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(16)
        }
    }
    
    // MARK: - ViewModel Binding
    private func bindViewModel() {
        emailTextField.textPublisher
            .assign(to: \.email, on: viewModel)
            .store(in: &cancellables)
        
        viewModel.$isValidEmail.dropFirst()
            .sink { [weak self] isValid in
                self?.errorLabel.isHidden = isValid
            }
            .store(in: &cancellables)
        
        viewModel.$isButtonEnabled
            .sink { [weak self] isEnabled in
                self?.actionButton.isEnabled = isEnabled
                self?.actionButton.backgroundColor = isEnabled ? .green_500 : .gray_100
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Keyboard Handling
    private func setupKeyboardObservers() {
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .sink { [weak self] notification in
                guard let self = self, let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
                self.actionButton.snp.updateConstraints { make in
                    make.bottom.equalTo(self.view.safeAreaLayoutGuide).inset(keyboardFrame.height - 16)
                }
                self.view.layoutIfNeeded()
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            .sink { [weak self] _ in
                self?.actionButton.snp.updateConstraints { make in
                    make.bottom.equalTo(self!.view.safeAreaLayoutGuide).inset(16)
                }
                self?.view.layoutIfNeeded()
            }
            .store(in: &cancellables)
    }
}

extension EmailInputViewController: EmailInputToolBarDelegate {
    func leftNaviItemTap() {
        self.navigationController?.popViewController(animated: true)
    }
}
