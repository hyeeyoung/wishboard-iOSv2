//
//  ShareViewController.swift
//  Share Extension
//
//  Created by gomin on 8/25/24.
//

import UIKit
import Core
import WBNetwork
import MobileCoreServices

class ShareViewController: UIViewController {
    
    private let shareView = ShareView()
    private let viewModel = ShareViewModel()
    
    private let bottomSheetView = FolderBottomSheet()
    private let backgroundDimView = UIView()
    
    private var link: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpShareView()
        setupBackgroundDimView()
        setupBottomSheet()
        setUpObservers()
        
        // fetch datas
        viewModel.fetchFolders()
        self.getSharedUrl { [weak self] url in
            self?.viewModel.fetchItem(link: url)
        }
    }
    
    private func setUpShareView() {
        self.view.addSubview(shareView)
        shareView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        shareView.configure(with: viewModel)
        
        shareView.addFolderButton.addTarget(self, action: #selector(addFolderButtonTapped), for: .touchUpInside)
        shareView.quitButton.addTarget(self, action: #selector(quitShareView), for: .touchUpInside)
        shareView.completeButton.addTarget(self, action: #selector(addItem), for: .touchUpInside)
    }
    
    private func setUpObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    private func getSharedUrl(completion: @escaping(String) -> Void) {
        // 공유된 URL 가져오기
        if let item = self.extensionContext?.inputItems.first as? NSExtensionItem {
            if let attachment = item.attachments?.first {
                if attachment.hasItemConformingToTypeIdentifier(kUTTypeURL as String) {
                    attachment.loadItem(forTypeIdentifier: kUTTypeURL as String, options: nil) { (urlItem, error) in
                        if let url = urlItem as? URL {
                            DispatchQueue.main.async {
                                print("Shared URL: \(url)")
                                self.link = url.absoluteString
                                completion(self.link ?? "")
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func setupBackgroundDimView() {
        backgroundDimView.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        backgroundDimView.alpha = 0.0 // 초기에는 투명하게 설정
        view.addSubview(backgroundDimView)
        
        backgroundDimView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    private func setupBottomSheet() {
        view.addSubview(bottomSheetView)
        
        bottomSheetView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview().offset(view.frame.height * 0.4)
        }
        
        bottomSheetView.onClose = { [weak self] in
            self?.dismissKeyboard()
            self?.hideBottomSheet()
        }
        
        bottomSheetView.onActionButtonTap = { [weak self] folderName, folder in
            self?.dismissKeyboard()
            // 새 폴더 추가
            self?.viewModel.addFolder(name: folderName)
            self?.hideBottomSheet()
            SnackBar(in: self).show(type: .addFolder)
        }
    }
    
    /// 폴더 관련 바텀시트 노출
    /// - Parameter folder: 폴더 정보 - nil이라면 '새 폴더 추가' / nil이 아니라면 '폴더명 수정'
    private func showBottomSheet(for folder: FolderListResponse? = nil) {
        DispatchQueue.main.async {
            self.dismissKeyboard()
            self.bottomSheetView.initView()
            self.bottomSheetView.configure(with: folder)
            
            UIView.animate(withDuration: 0.3) {
                self.backgroundDimView.alpha = 1.0
                self.bottomSheetView.snp.updateConstraints { make in
                    make.bottom.equalToSuperview()
                }
                self.view.layoutIfNeeded()
            }
        }
    }
    
    private func hideBottomSheet() {
        DispatchQueue.main.async {
            self.dismissKeyboard()
            self.bottomSheetView.resetView()
            
            UIView.animate(withDuration: 0.3) {
                self.backgroundDimView.alpha = 0.0
                self.bottomSheetView.snp.updateConstraints { make in
                    make.bottom.equalToSuperview().offset(self.view.frame.height * 0.4)
                }
                self.view.layoutIfNeeded()
            }
        }
    }
    
    // MARK: - Actions
    
    /// 키보드 내림
    @objc private func dismissKeyboard() {
        self.view.endEditing(true)
    }
    
    /// 새 폴더 추가
    @objc private func addFolderButtonTapped() {
        self.showBottomSheet()
    }
    
    /// 링크 공유 종료
    @objc private func quitShareView() {
        self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }
    
    /// 아이템 추가
    @objc private func addItem() {
        self.dismissKeyboard()
        shareView.completeButton.startAnimation()
        
        let itemName = shareView.itemNameTextField.text
        let itemPrice = FormatManager.shared.priceToStr(price: shareView.itemPriceTextField.text ?? "")
        let selectedFolderId = shareView.selectedFolderId
        let itemImage = shareView.itemImage.image?.resizeImageIfNeeded().jpegData(compressionQuality: 1.0)
        
        let itemDTO = RequestItemDTO(folderId: selectedFolderId, 
                                     photo: itemImage,
                                     itemName: itemName,
                                     itemPrice: itemPrice,
                                     itemURL: self.link,
                                     itemMemo: nil,
                                     itemNotificationType: nil, itemNotificationDate: nil)
        
        Task {
            do {
                try await viewModel.addItem(item: itemDTO)
                shareView.completeButton.stopAnimation()
                shareView.completeButton.isEnabled = false
                
                // complete snackbar
                SnackBar(in: self).show(type: .addItem)
                // 1초 후 quit
                DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) { [weak self] in
                    self?.quitShareView()
                }
            } catch {
                shareView.completeButton.stopAnimation()
                shareView.completeButton.isEnabled = false
                SnackBar(in: self).show(type: .errorMessage)
                throw error
            }
        }
        
    }

}

// MARK: - Keyboard Event
extension ShareViewController {
    @objc private func keyboardWillShow(notification: NSNotification) {
        if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            let keyboardHeight = keyboardFrame.height
            UIView.animate(withDuration: 0.3) {
                self.shareView.snp.updateConstraints { make in
                    make.bottom.equalToSuperview().offset(-keyboardHeight)
                }
                self.view.layoutIfNeeded()
            }
        }
    }

    @objc private func keyboardWillHide(notification: NSNotification) {
        UIView.animate(withDuration: 0.3) {
            self.shareView.snp.updateConstraints { make in
                make.bottom.equalToSuperview()
            }
            self.view.layoutIfNeeded()
        }
    }
}
