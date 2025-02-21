//
//  AddViewController.swift
//  WishboardV2
//
//  Created by gomin on 2/22/25.
//

import Foundation
import UIKit
import Combine
import Lottie
import Then
import Core

final class AddViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    private let addView = AddView()
    private let viewModel = AddViewModel()
    private var cancellables = Set<AnyCancellable>()
    
    override func viewDidLoad() {
        self.view.backgroundColor = .white
        
        self.view.addSubview(addView)
        addView.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview()
            make.top.equalTo(self.view.safeAreaLayoutGuide)
            make.bottom.equalToSuperview()
        }
        
        setupBindings()
        setupActions()
        setupDelegates()
    }
    
    // MARK: - Bindings
    private func setupBindings() {
        addView.itemNameTextField.textPublisher
            .receive(on: RunLoop.main)
            .assign(to: \.itemName, on: viewModel)
            .store(in: &cancellables)

        addView.itemPriceTextField.textPublisher
            .receive(on: RunLoop.main)
            .assign(to: \.itemPrice, on: viewModel)
            .store(in: &cancellables)
        
        viewModel.$selectedFolder
            .receive(on: RunLoop.main)
            .sink { [weak self] text in
                self?.addView.folderView.updateText(text ?? "폴더 선택")
            }
            .store(in: &cancellables)
        
        viewModel.$selectedAlarm
            .receive(on: RunLoop.main)
            .sink { [weak self] text in
                self?.addView.alarmView.updateText(text ?? "상품 일정 알림 선택")
            }
            .store(in: &cancellables)
        
        viewModel.$selectedLink
            .receive(on: RunLoop.main)
            .sink { [weak self] text in
                self?.addView.linkView.updateText(text ?? "쇼핑몰 링크 선택")
            }
            .store(in: &cancellables)
        
        viewModel.$selectedImage
            .receive(on: RunLoop.main)
            .sink { [weak self] image in
                self?.addView.imagePickerView.image = image ?? UIImage()
            }
            .store(in: &cancellables)
        
        viewModel.isSaveEnabled
            .receive(on: RunLoop.main)
            .sink { [weak self] isEnabled in
                self?.addView.toolBar.updateButtonState(enabled: isEnabled) // 저장 버튼 활성화
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Actions
    private func setupActions() {
        addView.folderView.onTap = { [weak self] in
            print("폴더 선택 탭")
        }
        
        addView.alarmView.onTap = { [weak self] in
            print("알림 설정 탭")
        }
        
        addView.linkView.onTap = { [weak self] in
            print("쇼핑몰 링크 입력 탭")
        }
        
        let imageTapGesture = UITapGestureRecognizer(target: self, action: #selector(selectImage))
        addView.imagePickerView.isUserInteractionEnabled = true
        addView.imagePickerView.addGestureRecognizer(imageTapGesture)
    }
    
    private func setupDelegates() {
        addView.toolBar.delegate = self
    }
    
    // MARK: - Image Picker
    @objc private func selectImage() {
        let actionSheet = UIAlertController(title: "사진 선택", message: nil, preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "카메라", style: .default) { _ in
            self.openCamera()
        })
        actionSheet.addAction(UIAlertAction(title: "앨범", style: .default) { _ in
            self.openPhotoLibrary()
        })
        actionSheet.addAction(UIAlertAction(title: "취소", style: .cancel, handler: nil))
        
        present(actionSheet, animated: true)
    }
    
    private func openCamera() {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let picker = UIImagePickerController()
            picker.delegate = self
            picker.sourceType = .camera
            picker.allowsEditing = true
            present(picker, animated: true)
        } else {
            showAlert(title: "카메라 사용 불가", message: "이 기기에서는 카메라를 사용할 수 없습니다.")
        }
    }
    
    private func openPhotoLibrary() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        present(picker, animated: true)
    }
    
    // MARK: - UIImagePickerControllerDelegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let editedImage = info[.editedImage] as? UIImage {
            viewModel.selectedImage = editedImage
        } else if let originalImage = info[.originalImage] as? UIImage {
            viewModel.selectedImage = originalImage
        }
        picker.dismiss(animated: true)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
    
    // MARK: - Alert Helper
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}

extension AddViewController: AddToolBarDelegate {
    func leftItemTap() {
        self.dismiss(animated: true)
    }
    
    func rightItemTap() {
        self.viewModel.saveItem { success in
            print("아이템 저장 성공")
            self.dismiss(animated: true)
        }
    }
}
