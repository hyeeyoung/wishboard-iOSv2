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
    /// 행과 행 사이 간격. 열 사이에는 간격이 없습니다.
    private static let lineSpacing: CGFloat = 0.5

    // MARK: - Views

    let toolBar = AddToolBar()
    let collectionView: UICollectionView

    /// 로딩뷰가 덮을 영역. 상단바는 가리지 않습니다.
    let loadingContainerView = UIView().then {
        $0.isUserInteractionEnabled = false
    }

    // TODO: 폴더에 이미지가 있는 아이템이 하나도 없을 때의 화면은 기획 미지정입니다.
    // 엠티뷰가 신규 제작되면 이 라벨을 교체해 주세요.
    private let emptyLabel = UILabel().then {
        $0.text = "앗, 대표 사진으로 지정할 이미지가 없어요!"
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
        // 셀은 정사각형이고, 행과 행 사이에만 간격이 있습니다.
        layout.itemSize = CGSize(width: cellWidth, height: cellWidth)
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = FolderThumbnailView.lineSpacing

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
        toolBar.configure(title: folderTitle, usesBackIcon: true)

        // 리스트는 상단바 바로 아래에서부터 시작합니다.
        collectionView.snp.makeConstraints { make in
            make.horizontalEdges.bottom.equalToSuperview()
            make.top.equalTo(toolBar.snp.bottom)
        }

        emptyLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.horizontalEdges.equalToSuperview().inset(16)
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

    /// 고를 수 있는 이미지가 없으면 저장할 것도 없어 버튼을 비활성화합니다.
    func updateSaveButtonState(enabled: Bool) {
        toolBar.updateButtonState(enabled: enabled)
    }
}
