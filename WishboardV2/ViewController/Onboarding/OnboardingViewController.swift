//
//  OnboardingViewController.swift
//  WishboardV2
//
//  Created by gomin on 7/27/24.
//

import Foundation
import UIKit

class OnboardingViewController: UIViewController {
    private var onboardingView: OnboardingView
    private var viewModel: OnboardingViewModel
    
    init() {
        self.onboardingView = OnboardingView()
        self.viewModel = OnboardingViewModel()
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        
        self.view.addSubview(onboardingView)
        onboardingView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        onboardingView.configure(with: viewModel)
        setupActions()
    }
    
    private func setupActions() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(loginButtonTapped))
        onboardingView.loginLabel.addGestureRecognizer(tapGesture)
        onboardingView.registerButton.addTarget(self, action: #selector(signUpButtonTapped), for: .touchUpInside)
    }
    
    @objc private func signUpButtonTapped() {
        print("Sign Up button tapped")
        // Handle sign up action
    }
    
    @objc private func loginButtonTapped() {
        print("Go Login View tapped")
        // Handle login action
        self.navigationController?.pushViewController(LoginViewController(), animated: true)
    }
}
