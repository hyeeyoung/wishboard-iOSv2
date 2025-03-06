//
//  PasswordInputViewController.swift
//  WishboardV2
//
//  Created by gomin on 3/5/25.
//

import Foundation
import UIKit
import Combine
import SnapKit
import Core


final class PasswordInputViewController: UIViewController {
    
    private let passwordInputView = PasswordInputView()
    private let viewModel: PasswordInputViewModel
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - UI Components
    
    private var keyboardHeight: CGFloat = 0.0
    private var type: InputType
    private let validationCode: String?
    // MARK: - Initializers
    
    init(type: InputType, code: String? = nil) {
        self.type = type
        self.validationCode = code
        self.viewModel = PasswordInputViewModel(type: type)
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.isHidden = true
        
        setupUI()
        bindViewModel()
        setupKeyboardObservers()
        setupDelegates()
        
        // 화면 진입 시 키보드 자동 띄우기
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.passwordInputView.textField.becomeFirstResponder()
        }
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .white
        
        self.view.addSubview(passwordInputView)
        passwordInputView.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview()
            make.top.equalTo(self.view.safeAreaLayoutGuide)
            make.bottom.equalToSuperview()
        }
        
        passwordInputView.configure(type: self.type)
        
        passwordInputView.actionButton.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(16)
            make.height.equalTo(50)
            make.bottom.equalTo(self.view.safeAreaLayoutGuide).inset(16) // 초기 상태
        }
    }
    
    private func setupDelegates() {
        passwordInputView.toolBar.delegate = self
        
        passwordInputView.emailLoginAction = { [weak self] code in
            print("이메일 로그인 code: \(code)")
            
            if code == self?.validationCode {
                print("코드 일치")
            } else {
                self?.viewModel.isValidCode = false
                self?.passwordInputView.errorLabel.isHidden = false
            }
            
        }
        
        passwordInputView.registerAction = { [weak self] pw in
            print("회원가입 pw: \(pw)")
        }
        
        passwordInputView.termsLabel.onTapTerms = {
            print("이용약관 화면으로 이동")
            
        }

        passwordInputView.termsLabel.onTapPrivacy = {
            print("개인정보 처리방침 화면으로 이동")
            
        }
    }
    
    // MARK: - ViewModel Binding
    private func bindViewModel() {
        passwordInputView.textField.textPublisher
            .assign(to: \.input, on: viewModel)
            .store(in: &cancellables)
        
        switch type {
        case .emailLogin:
            viewModel.$isValidCode.dropFirst()
                .sink { [weak self] isValid in
                    self?.passwordInputView.errorLabel.isHidden = isValid
                }
                .store(in: &cancellables)
        case .register:
            viewModel.$isValidPW.dropFirst()
                .sink { [weak self] isValid in
                    self?.passwordInputView.errorLabel.isHidden = isValid
                }
                .store(in: &cancellables)
        }
        
        viewModel.$isButtonEnabled
            .sink { [weak self] isEnabled in
                self?.passwordInputView.actionButton.isEnabled = isEnabled
                self?.passwordInputView.actionButton.backgroundColor = isEnabled ? .green_500 : .gray_100
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Keyboard Handling
    private func setupKeyboardObservers() {
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .sink { [weak self] notification in
                guard let self = self, let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
                self.passwordInputView.actionButton.snp.updateConstraints { make in
                    make.bottom.equalTo(self.view.safeAreaLayoutGuide).inset(keyboardFrame.height - 16)
                }
                self.view.layoutIfNeeded()
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            .sink { [weak self] _ in
                self?.passwordInputView.actionButton.snp.updateConstraints { make in
                    make.bottom.equalTo(self!.view.safeAreaLayoutGuide).inset(16)
                }
                self?.view.layoutIfNeeded()
            }
            .store(in: &cancellables)
    }
}

extension PasswordInputViewController: InputToolBarDelegate {
    func leftNaviItemTap() {
        DispatchQueue.main.async { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }
    }
}
