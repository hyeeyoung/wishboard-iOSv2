//
//  ModiftyProfileViewController.swift
//  WishboardV2
//
//  Created by gomin on 9/1/24.
//

import Foundation
import UIKit
import MessageUI
import Combine
import Core

final class ModifyProfileViewController: UIViewController {
    
    private let modifyProfileView: ModifyProfileView
    private let viewModel = ModifyProfileViewModel()
    private var cancellables = Set<AnyCancellable>()
    public var modifyProfileAction: (() -> Void)?
    
    init(_ currentProfileImgUrl: String?, _ currentNickname: String?) {
        modifyProfileView = ModifyProfileView(currentProfileImgUrl, currentNickname)
        modifyProfileView.viewModel = self.viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        self.navigationController?.navigationBar.isHidden = true
        
        setupMyPageView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.tabBarController?.tabBar.isHidden = true
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        self.view.endEditing(true)
    }
    
    private func setupMyPageView() {
        self.view.addSubview(modifyProfileView)
        modifyProfileView.snp.makeConstraints { make in
            make.top.equalTo(self.view.safeAreaLayoutGuide)
            make.horizontalEdges.bottom.equalToSuperview()
        }
        
        self.addTargets()
    }
    
    private func addTargets() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(showAlbum))
        self.modifyProfileView.profileImgView.addGestureRecognizer(tapGesture)
        modifyProfileView.icon.addTarget(self, action: #selector(showAlbum), for: .touchUpInside)
        
        modifyProfileView.completeAction = { [weak self] (image, name) in
            Task {
                do {
                    self?.modifyProfileView.actionButton.startAnimation()
                    try await self?.viewModel.updateProfile(img: image, name: name)
                    self?.modifyProfileView.actionButton.stopAnimation()
                    
                    self?.navigationController?.popViewController(animated: true)
                    SnackBar.shared.show(type: .modifyProfile)
                    self?.modifyProfileAction?()
                } catch {
                    self?.modifyProfileView.updateLoginButtonState(false)
                    SnackBar.shared.show(type: .errorMessage)
                    throw error
                }
            }
        }
        
        modifyProfileView.toolbar.delegate = self
    }
    
    @objc private func showAlbum() {
        self.view.endEditing(true)
        
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.sourceType = .photoLibrary
        imagePickerController.allowsEditing = false
        present(imagePickerController, animated: true, completion: nil)
    }
}

// MARK: - ImagePicker Delegate
extension ModifyProfileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        
        if let selectedImage = info[.originalImage] as? UIImage {
            modifyProfileView.profileImgView.image = selectedImage
            viewModel.profileImageChanged = true
            modifyProfileView.updateLoginButtonState()
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}

// MARK: - ToolBar Delegate
extension ModifyProfileViewController: ToolBarDelegate {
    func leftNaviItemTap() {
        self.navigationController?.popViewController(animated: true)
    }
}
