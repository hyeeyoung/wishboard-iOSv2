//
//  ModifyPasswordViewController.swift
//  WishboardV2
//
//  Created by gomin on 9/7/24.
//

import Foundation
import UIKit
import Combine
import Core
import WBNetwork

final class ModifyPasswordViewController: UIViewController, ToolBarDelegate {
    
    // MARK: - Views
    private let modifyPasswordView = ModifyPasswordView()
    
    // MARK: - ViewModel
    private let viewModel = ModifyPasswordViewModel()
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = true
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Setup
    private func setupView() {
        view.addSubview(modifyPasswordView)
        modifyPasswordView.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview()
            make.verticalEdges.equalTo(self.view.safeAreaLayoutGuide)
        }
        modifyPasswordView.completeButton.addTarget(self, action: #selector(completeButtonTapped), for: .touchUpInside)
    }
    
    private func bindViewModel() {
        modifyPasswordView.newPasswordTextField.textPublisher
            .assign(to: \.password, on: viewModel)
            .store(in: &cancellables)
        
        modifyPasswordView.repeatTextField.textPublisher
            .assign(to: \.repeatPassword, on: viewModel)
            .store(in: &cancellables)
        
        viewModel.$isPasswordValid
            .sink { [weak self] isValid in
                self?.modifyPasswordView.newPasswordErrorLabel.isHidden = isValid
            }
            .store(in: &cancellables)
        
        viewModel.$isRepeatPwValid
            .sink { [weak self] isValid in
                self?.modifyPasswordView.repeatErrorLabel.isHidden = isValid
            }
            .store(in: &cancellables)
        
        viewModel.$isButtonEnabled
            .sink { [weak self] isEnabled in
                self?.modifyPasswordView.updateLoginButtonState(isEnabled: isEnabled)
            }
            .store(in: &cancellables)
    }
    
    private func setupActions() {
        modifyPasswordView.setBackButtonAction(self)
    }
    
    // MARK: - Actions
    func leftNaviItemTap() {
        navigationController?.popViewController(animated: true)
    }
    
    /// 하단 버튼 탭 이벤트
    @objc func completeButtonTapped() {
        Task {
            do {
                self.view.endEditing(true)
                modifyPasswordView.completeButton.startAnimation()
                
                try await viewModel.modifyPassword()
                
                modifyPasswordView.completeButton.stopAnimation()
                navigationController?.popViewController(animated: true)
                SnackBar.shared.show(type: .modifyPassword)
            } catch {
                print("modify password error")
                modifyPasswordView.completeButton.stopAnimation()
                self.modifyPasswordView.updateLoginButtonState(isEnabled: false)
                SnackBar.shared.show(type: .errorMessage)
                throw error
            }
        }
    }
}
