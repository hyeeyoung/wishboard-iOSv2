//
//  FolderViewController.swift
//  WishboardV2
//
//  Created by gomin on 8/18/24.
//

import Foundation
import UIKit
import Combine
import WBNetwork

final class FolderViewController: UIViewController, ItemDetailDelegate {
    private let folderView = FolderView()
    private let viewModel = FolderViewModel()
    private let bottomSheetView = FolderBottomSheet()
    private let backgroundDimView = UIView()
    private var cancellables = Set<AnyCancellable>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        self.navigationController?.navigationBar.isHidden = true
        
        setupNotifications()
        setUpFolderView()
        setupBackgroundDimView()
        setupBottomSheet()
        addActions()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.refreshItems()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = false
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Methods
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(refreshItems), name: .ItemUpdated, object: nil)
    }
    
    private func setUpFolderView() {
        self.view.addSubview(folderView)
        folderView.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview()
            make.top.equalTo(self.view.safeAreaLayoutGuide)
            make.bottom.equalToSuperview()
        }
        
        folderView.collectionView.delegate = self
        folderView.collectionView.dataSource = self
        folderView.toolBar.delegate = self
        
        viewModel.$folders
            .receive(on: RunLoop.main)
            .sink { [weak self] folders in
                self?.folderView.refreshControl.endRefreshing()
                self?.folderView.emptyLabel.isHidden = !(folders.isEmpty)
                self?.folderView.collectionView.reloadData()
            }
            .store(in: &cancellables)
    }
    
    private func addActions() {
        // 키보드 닫기 처리: 바텀 시트의 어디든 탭하면 키보드를 내림
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        self.backgroundDimView.addGestureRecognizer(tapGesture)
        
        self.folderView.refreshAction = { [weak self] in
            self?.refreshItems()
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
    
    private func presentActionSheet(for folder: FolderListResponse) {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let renameAction = UIAlertAction(title: "수정하기", style: .default) { [weak self] _ in
            actionSheet.dismiss(animated: true)
            self?.showBottomSheet(for: folder)
        }
        let deleteAction = UIAlertAction(title: "삭제하기", style: .destructive) { [weak self] _ in
            actionSheet.dismiss(animated: true)
            // 폴더 삭제 알럿창
            let alert = AlertViewController(alertType: .deleteFolder)
            alert.buttonHandlers = [
                { _ in
                    print("폴더 삭제 취소")
                }, { _ in
                    print("폴더 삭제")
                    guard let folderId = folder.folder_id else {return}
                    self?.viewModel.deleteFolder(id: folderId)
                }
            ]
            alert.modalTransitionStyle = .crossDissolve
            alert.modalPresentationStyle = .overFullScreen
            self?.present(alert, animated: true, completion: nil)
        }
        let cancelAction = UIAlertAction(title: "취소", style: .cancel, handler: nil)
        
        actionSheet.addAction(renameAction)
        actionSheet.addAction(deleteAction)
        actionSheet.addAction(cancelAction)
        
        present(actionSheet, animated: true, completion: nil)
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
            if let folder = folder, let id = folder.folder_id {
                // 폴더 이름 수정
                Task {
                    self?.bottomSheetView.actionButton.startAnimation()
                    try await self?.viewModel.renameFolder(id: id, newName: folderName)
                    self?.bottomSheetView.actionButton.stopAnimation()
                    self?.hideBottomSheet()
                }
            } else {
                // 새 폴더 추가
                Task {
                    self?.bottomSheetView.actionButton.startAnimation()
                    try await self?.viewModel.addFolder(name: folderName)
                    self?.bottomSheetView.actionButton.stopAnimation()
                    self?.hideBottomSheet()
                }
            }
        }
        
        // 서버 에러 났을 때 예외처리
        viewModel.folderActionFail = { [weak self] code in
            if code == 409 {
                self?.bottomSheetView.actionButton.stopAnimation()
                self?.bottomSheetView.displayErrorMessage("동일 이름의 폴더가 있어요!")
            }
        }
    }
    
    /// 폴더 관련 바텀시트 노출
    /// - Parameter folder: 폴더 정보 - nil이라면 '새 폴더 추가' / nil이 아니라면 '폴더명 수정'
    private func showBottomSheet(for folder: FolderListResponse? = nil) {
        DispatchQueue.main.async {
            self.tabBarController?.tabBar.isHidden = true
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
            self.tabBarController?.tabBar.isHidden = false
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
    
    @objc func refreshItems() {
        viewModel.fetchFolders()
    }
    
    func scrollToTop() {
        if folderView.collectionView.numberOfSections > 0, folderView.collectionView.numberOfItems(inSection: 0) > 0 {
            folderView.collectionView.scrollToItem(at: IndexPath(item: 0, section: 0), at: .top, animated: true)
        }
    }
    
    // MARK: - Actions
    @objc private func dismissKeyboard() {
        self.view.endEditing(true)
    }
}

extension FolderViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.folders.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FolderCollectionViewCell.reuseIdentifier, for: indexPath) as? FolderCollectionViewCell else {
            return UICollectionViewCell()
        }
        
        let folder = viewModel.folders[indexPath.row]
        cell.configure(with: folder)
        
        // etc 버튼 액션 설정
        cell.etcButtonAction = { [weak self] in
            self?.presentActionSheet(for: folder)
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = viewModel.folders[indexPath.item]
        guard let folderId = item.folder_id else {return}
        
        let folderTitle = item.folder_name ?? ""
        let folderDetailVC = FolderDetailViewController(folderId: String(folderId), folderTitle: folderTitle)
        self.navigationController?.pushViewController(folderDetailVC, animated: true)
    }
}

extension FolderViewController: FolderToolBarDelegate {
    func rightNaviItemTap() {
        print("add folder tap!")
        
        showBottomSheet()
    }
}
