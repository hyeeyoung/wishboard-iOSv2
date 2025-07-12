//
//  SelectedImageCell.swift
//  WishboardV2
//
//  Created by gomin on 7/11/25.
//

import Foundation
import UIKit

// MARK: - 상품 등록 > 선택된 이미지 셀 (X 버튼 포함)
class SelectedImageCell: UICollectionViewCell {
    static let identifier = "SelectedImageCell"

    private let imageView = UIImageView().then {
        $0.contentMode = .scaleAspectFill
        $0.clipsToBounds = true
        $0.layer.cornerRadius = 10
    }

    private let deleteButton = UIButton(type: .system).then {
        $0.setImage(.xCircleBlack.withRenderingMode(.alwaysOriginal), for: .normal)
    }

    var onDelete: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(imageView)
        contentView.addSubview(deleteButton)

        imageView.snp.makeConstraints { $0.edges.equalToSuperview() }
        deleteButton.snp.makeConstraints { make in
            make.top.trailing.equalToSuperview().inset(5)
            make.size.equalTo(16)
        }
        deleteButton.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(with image: UIImage) { imageView.image = image }

    @objc private func deleteTapped() { onDelete?() }
}
