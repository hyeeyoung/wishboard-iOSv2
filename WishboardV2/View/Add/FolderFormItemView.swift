//
//  FolderFormItemView.swift
//  WishboardV2
//
//  Created by gomin on 7/12/25.
//

import Foundation
import UIKit
import Core
import WBNetwork

final class FolderFormItemView: FormItemView {
    // UI 요소
    private let folderCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 6
        layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)
        
        return UICollectionView(frame: .zero, collectionViewLayout: layout).then {
            $0.showsHorizontalScrollIndicator = false
            $0.backgroundColor = .clear
            $0.register(FolderCell.self, forCellWithReuseIdentifier: FolderCell.identifier)
            $0.register(NewFolderCell.self, forCellWithReuseIdentifier: NewFolderCell.identifier)
            $0.allowsSelection = true
        }
    }()
    
    private let arrowImageView = UIImageView(image: .arrowRight).then {
        $0.contentMode = .scaleAspectFit
    }
    
    private let fadeView = UIView()
    
    // 폴더 목록
    var folders: [FolderListResponse] = [] {
        didSet {
            folderCollectionView.reloadData()
            folderCollectionView.performBatchUpdates(nil) { _ in
                self.folderCollectionView.collectionViewLayout.invalidateLayout()
                self.folderCollectionView.layoutIfNeeded()
            }
        }
    }
    private var selectedFolderId: Int?
    
    // 콜백
    /// 고른 폴더. 이미 고른 폴더를 다시 누르면 `nil` 이 전달됩니다.
    var onFolderSelected: ((Int?) -> Void)?
    var onNewFolderTap: (() -> Void)?
    var onArrowTap: (() -> Void)?
    
    override init(title: String, isRequired: Bool, type: FormItemType = .folder) {
        super.init(title: title, isRequired: isRequired, type: type)
        
        setupUI()
        setupActions()
        setupFadeOverlay()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        mainContainer.addSubview(folderCollectionView)
        mainContainer.addSubview(arrowImageView)
        
        arrowImageView.snp.makeConstraints { make in
            make.centerY.equalTo(folderCollectionView)
            make.trailing.equalToSuperview().offset(-16)
            make.width.height.equalTo(24)
        }
        
        folderCollectionView.snp.makeConstraints { make in
            make.leading.bottom.equalToSuperview()
            make.top.equalTo(titleLabel.snp.bottom).offset(14)
            make.trailing.equalTo(arrowImageView.snp.leading)
            make.height.equalTo(26)
        }
        
        folderCollectionView.dataSource = self
        folderCollectionView.delegate = self
    }

    private func setupActions() {
        arrowImageView.isUserInteractionEnabled = true
        arrowImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapArrow)))
    }
    
    private func setupFadeOverlay() {
        fadeView.isUserInteractionEnabled = false
        fadeView.backgroundColor = .clear
        self.addSubview(fadeView)

        fadeView.snp.makeConstraints { make in
            make.trailing.equalTo(folderCollectionView.snp.trailing)
            make.width.equalTo(16)
            make.top.bottom.equalTo(folderCollectionView)
        }

        let gradient = CAGradientLayer()
        gradient.colors = [
            UIColor.white.withAlphaComponent(0).cgColor,
            UIColor.white.withAlphaComponent(1).cgColor
        ]
        gradient.startPoint = CGPoint(x: 0.0, y: 0.5)
        gradient.endPoint = CGPoint(x: 1.0, y: 0.5)
        gradient.frame = CGRect(x: 0, y: 0, width: 16, height: 26)

        fadeView.layer.addSublayer(gradient)
    }

    @objc private func didTapArrow() {
        onArrowTap?()
    }
    
    /// 고른 폴더를 반영합니다. `nil` 이면 선택을 풉니다.
    public func selectFolder(with id: Int?) {
        selectedFolderId = id

        guard let id = id else {
            folderCollectionView.indexPathsForSelectedItems?.forEach {
                folderCollectionView.deselectItem(at: $0, animated: true)
            }
            return
        }

        guard let index = folders.firstIndex(where: { $0.id == id }) else { return }

        let indexPath = IndexPath(item: index + 1, section: 0)
        folderCollectionView.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
    }
}

// MARK: - UICollectionView Delegates
extension FolderFormItemView: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return folders.count + 1 // 새 폴더 버튼 1개 + 폴더 목록
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.item == 0 {
            // 새폴더 버튼 셀
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NewFolderCell.identifier, for: indexPath) as! NewFolderCell
            cell.onTap = { [weak self] in
                self?.onNewFolderTap?()
            }
            return cell
        } else {
            // 기존 폴더 셀
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FolderCell.identifier, for: indexPath) as! FolderCell
            let item = folders[indexPath.item - 1]   // 첫 인덱스에 있는 버튼 때문에 -1 해줘야 함
            if let cellTitle = item.folderName {
                cell.configure(with: cellTitle)
            }
            return cell
        }
    }

    /// 이미 고른 폴더를 다시 누르면 선택을 풉니다.
    ///
    /// 컬렉션뷰는 이미 선택된 셀을 다시 눌러도 `didSelectItemAt` 을 부르지 않아,
    /// 해제는 여기서 가로채 처리합니다.
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        // 첫 칸은 '새 폴더' 버튼이라 선택 대상이 아닙니다.
        // (선택되면 단일 선택 규칙 때문에 고른 폴더의 표시가 풀립니다)
        guard indexPath.item > 0 else { return false }

        guard collectionView.indexPathsForSelectedItems?.contains(indexPath) == true else { return true }

        collectionView.deselectItem(at: indexPath, animated: true)
        selectedFolderId = nil
        onFolderSelected?(nil)
        return false
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // 첫 칸은 '새 폴더' 버튼입니다. 목록의 첫 폴더는 item 1 이라 함께 걸러내면 안 됩니다.
        guard indexPath.item > 0 else { return }
        guard let selectedId = folders[indexPath.item - 1].id else { return }

        selectedFolderId = selectedId
        onFolderSelected?(selectedId)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        if indexPath.item == 0 {
            return CGSize(width: 66 + 20, height: 26) // 새폴더 버튼 크기
        }
        
        let folderName = folders[indexPath.item - 1].folderName ?? ""
        let font = TypoStyle.SuitB5.font
        let padding: CGFloat = 20  // inset
        let height: CGFloat = 26

        let textWidth = (folderName as NSString).size(withAttributes: [.font: font]).width
        return CGSize(width: textWidth + padding, height: height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
                        minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 6
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let maxOffset = scrollView.contentSize.width - scrollView.bounds.width
        fadeView.isHidden = scrollView.contentOffset.x >= maxOffset - 5
    }
}
