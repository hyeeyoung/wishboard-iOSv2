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
import WBNetwork

final class AddViewController: UIViewController {
    
    // MARK: - Properties
    
    private let addView = AddView()
    private let viewModel = AddViewModel()
    private var cancellables = Set<AnyCancellable>()
    public var confirmAction: (() -> Void)?
    
    // Bottom Sheets
    private let backgroundDimView = UIView()
    private let folderSelectBottomSheet = FolderSelectBottomSheet()
    private let shoppingLinkBottomSheet = ShoppingLinkBottomSheet()
    private let selectDateBottomSheet = SelectDateBottomSheet()
    
    // MARK: - Initializers
    
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
        
        setupBackgroundDimView()
        setupBottomSheet()
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
            guard let folders = self?.viewModel.folders else {return}
            self?.showFolderBottomSheet(for: folders)
        }
        
        addView.alarmView.onTap = { [weak self] in
            self?.showDateBottomSheet()
        }
        
        addView.linkView.onTap = { [weak self] in
            self?.showLinkBottomSheet(with: self?.viewModel.selectedLink)
        }
        
        let imageTapGesture = UITapGestureRecognizer(target: self, action: #selector(selectImage))
        addView.imagePickerView.isUserInteractionEnabled = true
        addView.imagePickerView.addGestureRecognizer(imageTapGesture)
    }
    
    private func setupDelegates() {
        addView.toolBar.delegate = self
        addView.memoTextView.delegate = self
    }
    
    // MARK: Alert Helper
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
    
    // MARK: Bottom Sheets
    /// 뒷배경뷰 설정
    private func setupBackgroundDimView() {
        backgroundDimView.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        backgroundDimView.alpha = 0.0 // 초기에는 투명하게 설정
        view.addSubview(backgroundDimView)
        
        backgroundDimView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    /// 시트 설정
    private func setupBottomSheet() {
        view.addSubview(folderSelectBottomSheet)
        view.addSubview(shoppingLinkBottomSheet)
        view.addSubview(selectDateBottomSheet)
        
        folderSelectBottomSheet.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview().offset(view.frame.height * 0.4)
        }
        shoppingLinkBottomSheet.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview().offset(view.frame.height * 0.4)
        }
        selectDateBottomSheet.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview().offset(view.frame.height * 0.4)
        }
        // Folder Binding
        folderSelectBottomSheet.onClose = { [weak self] folderId, folderName in
            self?.hideFolderBottomSheet()
            self?.viewModel.selectedFolderId = folderId
            self?.viewModel.selectedFolder = folderName
        }
        // Shopping Link Binding
        shoppingLinkBottomSheet.onClose = { [weak self] in
            self?.hideLinkBottomSheet()
        }
        shoppingLinkBottomSheet.onActionButtonTap = { [weak self] link in
            self?.hideLinkBottomSheet()
            self?.viewModel.selectedLink = link
        }
        // Select Date Binding
        selectDateBottomSheet.onClose = { [weak self] in
            self?.hideDateBottomSheet()
        }
        selectDateBottomSheet.onActionButtonTap = { [weak self] data in
            
            let (type, date, hour, minute) = data
            
            self?.hideDateBottomSheet()
            guard let type = data.0, let date = data.1, let hour = data.2, let minute = data.3 else {return}
            self?.viewModel.selectedAlarmType = type
            self?.viewModel.selectedAlarmDate = "\(date) \(hour):\(minute)"
            self?.viewModel.selectedAlarm = "[\(type)] \(self?.viewModel.selectedAlarmDate ?? "")"
        }
        
        // data - fetch FolderList
        self.viewModel.fetchFolders()
    }
    
    /// 폴더 선택 시트 노출
    private func showFolderBottomSheet(for folders: [FolderListResponse]) {
        DispatchQueue.main.async {
            self.folderSelectBottomSheet.configure(with: folders)
            
            UIView.animate(withDuration: 0.3) {
                self.backgroundDimView.alpha = 1.0
                self.folderSelectBottomSheet.snp.updateConstraints { make in
                    make.bottom.equalToSuperview()
                }
                self.view.layoutIfNeeded()
            }
        }
    }
    
    /// 폴더 선택 시트 미노출
    private func hideFolderBottomSheet() {
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.3) {
                self.backgroundDimView.alpha = 0.0
                self.folderSelectBottomSheet.snp.updateConstraints { make in
                    make.bottom.equalToSuperview().offset(self.view.frame.height * 0.4)
                }
                self.view.layoutIfNeeded()
            }
        }
    }
    
    /// 쇼핑몰 링크 입력 시트 노출
    private func showLinkBottomSheet(with prevLink: String? = nil) {
        DispatchQueue.main.async {
            self.shoppingLinkBottomSheet.configure(with: prevLink)
            
            UIView.animate(withDuration: 0.3) {
                self.backgroundDimView.alpha = 1.0
                self.shoppingLinkBottomSheet.snp.updateConstraints { make in
                    make.bottom.equalToSuperview()
                }
                self.view.layoutIfNeeded()
            }
        }
    }
    
    /// 쇼핑몰 링크 입력 시트 미노출
    private func hideLinkBottomSheet() {
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.3) {
                self.backgroundDimView.alpha = 0.0
                self.shoppingLinkBottomSheet.snp.updateConstraints { make in
                    make.bottom.equalToSuperview().offset(self.view.frame.height * 0.4)
                }
                self.view.layoutIfNeeded()
            }
        }
    }
    
    /// 날짜 선택 시트 노출
    private func showDateBottomSheet() {
        DispatchQueue.main.async {
            self.selectDateBottomSheet.configure()
            
            UIView.animate(withDuration: 0.3) {
                self.backgroundDimView.alpha = 1.0
                self.selectDateBottomSheet.snp.updateConstraints { make in
                    make.bottom.equalToSuperview()
                }
                self.view.layoutIfNeeded()
            }
        }
    }
    
    /// 날짜 선택 시트 미노출
    private func hideDateBottomSheet() {
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.3) {
                self.backgroundDimView.alpha = 0.0
                self.selectDateBottomSheet.snp.updateConstraints { make in
                    make.bottom.equalToSuperview().offset(self.view.frame.height * 0.4)
                }
                self.view.layoutIfNeeded()
            }
        }
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
        Task {
            do {
                try await self.viewModel.addItem()
                self.dismiss(animated: true)
                self.confirmAction?()
            } catch {
                throw error
            }
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
