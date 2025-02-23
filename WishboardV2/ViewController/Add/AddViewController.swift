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

final class AddViewController: UIViewController {
    
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
        setupKeyboardObservers()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        self.view.endEditing(true)
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
        addView.memoTextView.delegate = self
    }
    
    // MARK: - Alert Helper
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - ImagePicker 관련 Methods & Delegates
extension AddViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    /// Image Picker
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
            present(picker, animated: true)
        } else {
            showAlert(title: "카메라 사용 불가", message: "이 기기에서는 카메라를 사용할 수 없습니다.")
        }
    }
    
    private func openPhotoLibrary() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        present(picker, animated: true)
    }
    
    /// UIImagePickerControllerDelegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let editedImage = info[.editedImage] as? UIImage {
            viewModel.selectedImage = editedImage
        } else if let originalImage = info[.originalImage] as? UIImage {
            viewModel.selectedImage = originalImage
            addView.cameraIcon.isHidden = (viewModel.selectedImage != nil)
        }
        picker.dismiss(animated: true)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}

// MARK: - UITextView Delegates
extension AddViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        addView.memoPlaceholder.isHidden = !textView.text.isEmpty
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        textView.resignFirstResponder()
    }
}

// MARK: - 상단바 Delegate
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

// MARK: - Keyboard 관련 Methodds & Delegates
extension AddViewController {
    
    /// 키보드 옵저버 추가
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow(_:)),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide(_:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
    
    /// 키보드 나타날 때 호출
    @objc private func keyboardWillShow(_ notification: Foundation.Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        
        let keyboardHeight = keyboardFrame.height
        let bottomInset = keyboardHeight - view.safeAreaInsets.bottom
        
        UIView.animate(withDuration: 0.3) {
            self.addView.scrollView.contentInset.bottom = bottomInset
            self.addView.scrollView.verticalScrollIndicatorInsets.bottom = bottomInset
        }
        
        // 현재 포커싱된 뷰를 스크롤
        if let activeField = UIResponder.currentFirstResponder as? UIView {
            self.scrollToActiveField(activeField, keyboardHeight: keyboardHeight)
        }
    }
    
    /// 키보드 사라질 때 호출
    @objc private func keyboardWillHide(_ notification: Foundation.Notification) {
        UIView.animate(withDuration: 0.3) {
            self.addView.scrollView.contentInset.bottom = 0
            self.addView.scrollView.verticalScrollIndicatorInsets.bottom = 0
        }
    }
    
    /// 현재 포커싱된 필드를 키보드 높이에 맞게 조정
    private func scrollToActiveField(_ activeField: UIView, keyboardHeight: CGFloat) {
        let fieldFrame = activeField.convert(activeField.bounds, to: self.view)
        let fieldBottomY = fieldFrame.maxY
        let availableHeight = view.frame.height - keyboardHeight
        
        if fieldBottomY > availableHeight {
            let offset = fieldBottomY - availableHeight + 20
            self.addView.scrollView.setContentOffset(CGPoint(x: 0, y: offset), animated: true)
        }
    }
}
