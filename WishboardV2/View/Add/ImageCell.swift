//
//  SelectedImageCell.swift
//  WishboardV2
//
//  Created by gomin on 7/11/25.
//

import Foundation
import UIKit
import SnapKit
import Then
import Core

// MARK: - 상품 등록 > 선택된 이미지 셀 (X 버튼 포함)
class SelectedImageCell: UICollectionViewCell {
    static let identifier = "SelectedImageCell"

    /// '대표 사진' 바 높이
    private static let thumbnailBarHeight: CGFloat = 22
    /// 이미지뷰 모서리 반경. '대표 사진' 바의 아래쪽 모서리도 같은 값을 씁니다.
    private static let cornerRadius: CGFloat = 10

    private let imageView = UIImageView().then {
        $0.contentMode = .scaleAspectFill
        $0.clipsToBounds = true
        $0.layer.cornerRadius = SelectedImageCell.cornerRadius
    }

    /// 이미지 배열의 첫 번째 사진에만 노출되는 '대표 사진' 바
    private let thumbnailBar = UIView().then {
        $0.backgroundColor = .black_8
        $0.clipsToBounds = true
        $0.layer.cornerRadius = SelectedImageCell.cornerRadius
        $0.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        $0.isHidden = true
    }

    private let thumbnailLabel = UILabel().then {
        $0.text = "대표 사진"
        $0.textColor = .white_10
        $0.textAlignment = .center
        $0.setTypoStyleWithSingleLine(typoStyle: .SuitD3)
    }

    private let deleteButton = UIButton(type: .system).then {
        $0.setImage(.xCircleBlack.withRenderingMode(.alwaysOriginal), for: .normal)
    }

    var onDelete: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(imageView)
        contentView.addSubview(thumbnailBar)
        thumbnailBar.addSubview(thumbnailLabel)
        contentView.addSubview(deleteButton)

        imageView.snp.makeConstraints { $0.edges.equalToSuperview() }
        thumbnailBar.snp.makeConstraints { make in
            make.horizontalEdges.bottom.equalTo(imageView)
            make.height.equalTo(SelectedImageCell.thumbnailBarHeight)
        }
        thumbnailLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        deleteButton.snp.makeConstraints { make in
            make.top.trailing.equalToSuperview().inset(5)
            make.size.equalTo(16)
        }
        deleteButton.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(with image: UIImage, isThumbnail: Bool) {
        imageView.image = image
        setThumbnail(isThumbnail)
    }

    /// '대표 사진' 바 노출 여부.
    /// 순서를 바꾸면 셀은 그대로 이동만 하므로, 이것만 다시 맞춰 줍니다.
    func setThumbnail(_ isThumbnail: Bool) {
        thumbnailBar.isHidden = !isThumbnail
    }

    @objc private func deleteTapped() { onDelete?() }
}
