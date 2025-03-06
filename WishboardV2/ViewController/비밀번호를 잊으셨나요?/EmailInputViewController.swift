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

enum InputType {
    case emailLogin
    case register
}

final class EmailInputViewController: UIViewController {
    
    private let emailInputView = EmailInputView()
    private let viewModel = EmailInputViewModel()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - UI Components
    
    private var keyboardHeight: CGFloat = 0.0
    private var type: InputType
    
    // MARK: - Initializers
    
    init(type: InputType) {
        self.type = type
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
            self.emailInputView.emailTextField.becomeFirstResponder()
        }
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .white
        
        self.view.addSubview(emailInputView)
        emailInputView.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview()
            make.top.equalTo(self.view.safeAreaLayoutGuide)
            make.bottom.equalToSuperview()
        }
        
        emailInputView.configure(type: self.type)
        
        emailInputView.actionButton.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(16)
            make.height.equalTo(50)
            make.bottom.equalTo(self.view.safeAreaLayoutGuide).inset(16) // 초기 상태
        }
    }
    
    private func setupDelegates() {
        emailInputView.toolBar.delegate = self
        
        // 이메일 로그인
        emailInputView.emailLoginNextAction = { [weak self] email in
            self?.callEmailLoginAPI()
        }
        
        // 회원가입
        emailInputView.registerNextAction = { [weak self] email in
            self?.callCheckEmailValidationAPI()
        }
    }
    
    /// 이메일로 로그인하기 위한 인증번호 받아오기
    private func callEmailLoginAPI() {
        Task {
            do {
                let codeData = try await self.viewModel.getVerificationCode()
                if !codeData.0 { 
                    self.viewModel.isButtonEnabled = false
                    self.emailInputView.showInvalidUser()
                    return
                }
                guard let code = codeData.1 else {
                    print("서버로부터 인증번호를 못 받아옴")
                    return
                }
                let nextVC = PasswordInputViewController(type: self.type, email: self.viewModel.email, code: code)
                self.navigationController?.pushViewController(nextVC, animated: true)
            } catch {
                throw error
            }
        }
    }
    
    /// 회원가입을 하기 위한 이메일 검증하기
    private func callCheckEmailValidationAPI() {
        Task {
            do {
                let success = try await self.viewModel.checkEmailValidation()
                if !success {
                    self.viewModel.isButtonEnabled = false
                    self.emailInputView.showDuplicateUser()
                    return
                }
                let nextVC = PasswordInputViewController(type: self.type, email: self.viewModel.email)
                self.navigationController?.pushViewController(nextVC, animated: true)
            } catch {
                throw error
            }
        }
    }
    
    // MARK: - ViewModel Binding
    private func bindViewModel() {
        emailInputView.emailTextField.textPublisher
            .assign(to: \.email, on: viewModel)
            .store(in: &cancellables)
        
        viewModel.$isValidEmail.dropFirst()
            .sink { [weak self] isValid in
                if !isValid {
                    self?.emailInputView.showInvalidEmail()
                } else {
                    self?.emailInputView.errorLabel.isHidden = isValid
                }
            }
            .store(in: &cancellables)
        
        viewModel.$isButtonEnabled
            .sink { [weak self] isEnabled in
                self?.emailInputView.actionButton.isEnabled = isEnabled
                self?.emailInputView.actionButton.backgroundColor = isEnabled ? .green_500 : .gray_100
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Keyboard Handling
    private func setupKeyboardObservers() {
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .sink { [weak self] notification in
                guard let self = self, let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
                self.emailInputView.actionButton.snp.updateConstraints { make in
                    make.bottom.equalTo(self.view.safeAreaLayoutGuide).inset(keyboardFrame.height - 16)
                }
                self.view.layoutIfNeeded()
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            .sink { [weak self] _ in
                self?.emailInputView.actionButton.snp.updateConstraints { make in
                    make.bottom.equalTo(self!.view.safeAreaLayoutGuide).inset(16)
                }
                self?.view.layoutIfNeeded()
            }
            .store(in: &cancellables)
    }
}

extension EmailInputViewController: InputToolBarDelegate {
    func leftNaviItemTap() {
        DispatchQueue.main.async { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }
    }
}
