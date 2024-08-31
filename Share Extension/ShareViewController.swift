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
//        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
//        self.shareView.addGestureRecognizer(tapGesture)
        shareView.quitButton.addTarget(self, action: #selector(quitShareView), for: .touchUpInside)
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
                                completion(url.absoluteString)
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
    
    @objc private func dismissKeyboard() {
        self.view.endEditing(true)
    }
    
    @objc private func addFolderButtonTapped() {
        self.showBottomSheet()
    }
    
    @objc private func quitShareView() {
        self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
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
