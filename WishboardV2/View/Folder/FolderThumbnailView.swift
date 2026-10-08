//
//  FolderThumbnailView.swift
//  WishboardV2
//
//  Created by gomin on 10/8/26.
//

import Foundation
import UIKit
import SnapKit
import Then
import Core

/// 폴더 대표 사진 변경 화면.
///
/// 폴더 상세 화면과 구성은 비슷하지만, 이미지만 2열로 보여 줍니다.
final class FolderThumbnailView: UIView, LoadingPresentable {

    /// 한 줄에 보여 줄 이미지 개수
    private static let columnCount: CGFloat = 2

    // MARK: - Views

    let toolBar = AddToolBar()
    let collectionView: UICollectionView

    /// 로딩뷰가 덮을 영역. 상단바는 가리지 않습니다.
    let loadingContainerView = UIView().then {
        $0.isUserInteractionEnabled = false
    }

    private let emptyLabel = UILabel().then {
        $0.text = "앗, 아이템이 없어요!\n갖고 싶은 아이템을 등록해 보세요!"
        $0.setTypoStyleWithMultiLine(typoStyle: .SuitD2)
        $0.textColor = .gray_200
        $0.numberOfLines = 0
        $0.textAlignment = .center
        $0.isHidden = true
    }

    private let folderTitle: String

    // MARK: - Initializers

    init(folderTitle: String) {
        self.folderTitle = folderTitle

        let layout = UICollectionViewFlowLayout()
        let cellWidth = UIScreen.main.bounds.width / FolderThumbnailView.columnCount
        layout.itemSize = CGSize(width: cellWidth, height: cellWidth)
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .white

        super.init(frame: .zero)
        backgroundColor = .white

        setupViews()
        setupConstraints()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - Setup

    private func setupViews() {
        addSubview(toolBar)
        addSubview(collectionView)
        addSubview(emptyLabel)
        addSubview(loadingContainerView)

        collectionView.register(
            FolderThumbnailImageCell.self,
            forCellWithReuseIdentifier: FolderThumbnailImageCell.reuseIdentifier
        )
    }

    private func setupConstraints() {
        // 대표 사진은 언제든 저장할 수 있어야 해서, 저장 버튼은 항상 활성 상태로 둡니다.
        toolBar.configure(title: folderTitle, usesBackIcon: true)
        toolBar.updateButtonState(enabled: true)

        collectionView.snp.makeConstraints { make in
            make.horizontalEdges.bottom.equalToSuperview()
            make.top.equalTo(toolBar.snp.bottom)
        }

        emptyLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        loadingContainerView.snp.makeConstraints { make in
            make.horizontalEdges.bottom.equalToSuperview()
            make.top.equalTo(toolBar.snp.bottom)
        }
    }

    // MARK: - Public Methods

    func updateEmptyState(isEmpty: Bool) {
        emptyLabel.isHidden = !isEmpty
    }
}
