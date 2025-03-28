//
//  ItemDetailViewController.swift
//  WishboardV2
//
//  Created by gomin on 8/18/24.
//

import Foundation
import UIKit
import SafariServices
import Combine
import Core
import WBNetwork

public protocol ItemDetailDelegate {
    func refreshItems()
}

final class ItemDetailViewController: UIViewController {
    
    private let detailView = ItemDetailView()
    private let viewModel = ItemDetailViewModel()
    private var cancellables = Set<AnyCancellable>()
    
    private let bottomSheetView = FolderSelectBottomSheet()
    private let backgroundDimView = UIView()
    private let id: Int
    
    init(id: Int) {
        self.id = id
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        self.navigationController?.navigationBar.isHidden = true
        self.tabBarController?.tabBar.isHidden = true
        
        setupDetailView()
        setupBackgroundDimView()
        setupBottomSheet()
        
        self.viewModel.fetchItemDetail(id: self.id)
        
        viewModel.$item
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                if let viewModel = self?.viewModel {
                    self?.detailView.configure(with: viewModel)
                }
            }
            .store(in: &cancellables)
    }
    
    private func setupDetailView() {
        self.view.addSubview(detailView)
        detailView.snp.makeConstraints { make in
            make.top.equalTo(self.view.safeAreaLayoutGuide)
            make.horizontalEdges.bottom.equalToSuperview()
        }
        
        detailView.configure(with: viewModel)
        detailView.toolbar.delegate = self
        
        detailView.linkButtonAction = { [weak self] urlStr in
            guard let url = URL(string: urlStr), ["http", "https"].contains(url.scheme?.lowercased()) else {
//                SnackBar.shared.show(type: .errorMessage)
                return
            }

            let linkView = SFSafariViewController(url: url)
            self?.present(linkView, animated: true)
        }
        
        detailView.folderListButtonAction = { [weak self] in
            guard let folders = self?.viewModel.folders else {return}
            self?.showBottomSheet(for: folders)
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
        
        // 폴더 수정
        bottomSheetView.selectAction = { [weak self] folderId, folderName in
            self?.dismissKeyboard()
            self?.hideBottomSheet()
            
            if let folderId = folderId, let itemId = self?.viewModel.item?.item_id {
                Task {
                    try await self?.viewModel.modifyItemFolder(itemId: itemId, folderId: folderId)
//                    NotificationCenter.default.post(name: .ItemUpdated, object: nil)
                }
            }
        }
        bottomSheetView.onClose = { [weak self] in
            self?.dismissKeyboard()
            self?.hideBottomSheet()
        }
        
        // fetch FolderList
        self.viewModel.fetchFolders()
    }
    
    /// 폴더 관련 바텀시트 노출
    private func showBottomSheet(for folders: [FolderListResponse]) {
        DispatchQueue.main.async {
            self.bottomSheetView.configure(with: folders)
            
            // 이미 지정된 폴더 정보 넘기기
            let folderId = self.viewModel.item?.folder_id
            self.bottomSheetView.selectedFolderId = folderId
            
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
}

extension ItemDetailViewController: DetailToolBarDelegate {
    func leftNaviItemTap() {
        self.navigationController?.popViewController(animated: true)
    }
    
    /// 아이템 삭제
    func deleteNaviItemTap() {
        // 아이템 삭제 알럿창
        let alert = AlertViewController(alertType: .deleteItem)
        alert.buttonHandlers = [
            { _ in
                print("아이템 삭제 취소")
            }, { _ in
                print("아이템 삭제")
                Task {
                    do {
                        if let id = self.viewModel.item?.item_id {
                            // delete item
                            try await self.viewModel.deleteItem(id: id)
                            // TODO: 진입 화면의 refreshItems
                            
                            // 뒤로가기
                            self.leftNaviItemTap()
                        }
                    } catch {
                        throw error
                    }
                }
            }
        ]
        alert.modalTransitionStyle = .crossDissolve
        alert.modalPresentationStyle = .overFullScreen
        self.present(alert, animated: true, completion: nil)
    }
    
    /// 아이템 수정
    func modifyNaviItemTap() {
        guard let item = self.viewModel.item else {return}
        let addViewController = AddViewController(type: .modify, item: item)
        addViewController.modalPresentationStyle = .fullScreen
        
        // 새로고침
        addViewController.confirmAction = { [weak self] in
            if let idx = self?.viewModel.item?.item_id {
                self?.viewModel.fetchItemDetail(id: idx)
                NotificationCenter.default.post(name: .ItemUpdated, object: nil)
            }
        }
        
        present(addViewController, animated: true)
    }
}

// MARK: - Keyboard Event
extension ItemDetailViewController {
    @objc private func keyboardWillShow(notification: NSNotification) {
        if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            let keyboardHeight = keyboardFrame.height
            UIView.animate(withDuration: 0.3) {
                self.bottomSheetView.snp.updateConstraints { make in
                    make.bottom.equalToSuperview().offset(-keyboardHeight)
                }
                self.view.layoutIfNeeded()
            }
        }
    }

    @objc private func keyboardWillHide(notification: NSNotification) {
        UIView.animate(withDuration: 0.3) {
            self.bottomSheetView.snp.updateConstraints { make in
                make.bottom.equalToSuperview()
            }
            self.view.layoutIfNeeded()
        }
    }
}
