//
//  FolderThumbnailImageCell.swift
//  WishboardV2
//
//  Created by gomin on 10/8/26.
//

import Foundation
import UIKit
import SnapKit
import Then
import Core
import WBNetwork

/// 폴더 대표 사진 변경 화면의 셀.
///
/// 폴더 상세 화면의 셀과 달리 상품명/가격은 노출하지 않고 이미지만 보여 줍니다.
/// 선택 상태의 표시는 홈화면 아이템 선택과 같은 딤드 + 체크 아이콘을 씁니다.
final class FolderThumbnailImageCell: UICollectionViewCell {

    static let reuseIdentifier = "FolderThumbnailImageCell"

    // MARK: - Views

    private let imageView = UIImageView().then {
        $0.backgroundColor = .black_04
        $0.clipsToBounds = true
        $0.contentMode = .scaleAspectFill
    }

    /// 선택된 이미지의 딤드 처리
    private let selectionDimView = UIView().then {
        $0.backgroundColor = .black_55
        $0.isHidden = true
    }

    /// 선택된 이미지의 체크 아이콘
    private let selectionCheckImageView = UIImageView().then {
        $0.image = Image.checkCircle
        $0.isHidden = true
    }

    // MARK: - Initializers

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.addSubview(imageView)
        contentView.addSubview(selectionDimView)
        contentView.addSubview(selectionCheckImageView)

        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        selectionDimView.snp.makeConstraints { make in
            make.edges.equalTo(imageView)
        }
        selectionCheckImageView.snp.makeConstraints { make in
            make.trailing.bottom.equalTo(imageView).offset(-5)
            make.width.height.equalTo(24)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - Public Methods

    func configure(with item: WishListResponse, isSelected: Bool) {
        if let itemImages = item.itemImages, !itemImages.isEmpty, let imgUrl = itemImages[0].itemImageUrl {
            self.imageView.loadImage(from: imgUrl, placeholder: Image.logoIcon.withTintColor(.gray_100))
        } else {
            self.imageView.image = Image.logoIcon.withTintColor(.gray_100)
        }

        setSelected(isSelected)
    }

    func setSelected(_ isSelected: Bool) {
        selectionDimView.isHidden = !isSelected
        selectionCheckImageView.isHidden = !isSelected
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        setSelected(false)
    }
}
