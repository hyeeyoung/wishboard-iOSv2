//
//  LoginViewController.swift
//  WishboardV2
//
//  Created by gomin on 8/12/24.
//

import Foundation
import UIKit
import Combine
import Core
import WBNetwork

final class LoginViewController: UIViewController, ToolBarDelegate {
    
    // MARK: - Views
    private let loginView = LoginView()
    
    // MARK: - ViewModel
    private let viewModel = LoginViewModel()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        self.navigationController?.navigationBar.isHidden = true
        
        setupView()
        bindViewModel()
        setupActions()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        self.view.endEditing(true)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Setup
    private func setupView() {
        view.addSubview(loginView)
        loginView.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview()
            make.verticalEdges.equalTo(self.view.safeAreaLayoutGuide)
        }
        loginView.loginButton.addTarget(self, action: #selector(loginButtonTapped), for: .touchUpInside)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(moveToEmailLogin))
        loginView.forgotPasswordLabel.addGestureRecognizer(tapGesture)
    }
    
    private func bindViewModel() {
        // ViewModel의 email과 password를 View의 텍스트 필드와 바인딩
        loginView.emailTextField.textPublisher
            .assign(to: \.email, on: viewModel)
            .store(in: &cancellables)
        
        loginView.passwordTextField.textPublisher
            .assign(to: \.password, on: viewModel)
            .store(in: &cancellables)
        
        // ViewModel의 isLoginButtonEnabled를 바인딩하여 버튼의 상태를 업데이트
        viewModel.$isLoginButtonEnabled
            .sink { [weak self] isEnabled in
                self?.loginView.updateLoginButtonState(isEnabled: isEnabled)
            }
            .store(in: &cancellables)
    }
    
    private func setupActions() {
        loginView.setBackButtonAction(self)
    }
    
    // MARK: - Actions
    func leftNaviItemTap() {
        navigationController?.popViewController(animated: true)
    }
    
    /// '로그인하기' 버튼 탭 이벤트
    @objc func loginButtonTapped() {
        Task {
            do {
                loginView.loginButton.startAnimation()
                
                try await viewModel.login()
                
                loginView.loginButton.stopAnimation()
                self.moveToMain()
            } catch {
                print("login error")
                loginView.loginButton.stopAnimation()
                self.loginView.updateLoginButtonState(isEnabled: false)
                SnackBar.shared.show(type: .errorMessage)
                throw error
            }
        }
    }
    
    /// 로그인 성공 후 메인 화면으로 전환
    private func moveToMain() {
        self.navigationController?.popViewController(animated: true)
        
        let tabBarController = TabBarViewController()
        tabBarController.modalPresentationStyle = .fullScreen
        self.present(tabBarController, animated: true, completion: nil)
    }
    
    @objc private func moveToEmailLogin() {
        let nextVC = EmailInputViewController()
        self.navigationController?.pushViewController(nextVC, animated: true)
    }
}
