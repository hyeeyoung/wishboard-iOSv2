//
//  NewFolderCell.swift
//  WishboardV2
//
//  Created by gomin on 8/30/25.
//

import UIKit
import Core

final class NewFolderCell: UICollectionViewCell {
    static let identifier = "NewFolderCell"
    var onTap: (() -> Void)?

    private let button = UIButton(type: .system).then {
        $0.setTitle(Button.addFolder, for: .normal)
        $0.setTitleColor(.gray_600, for: .normal)
        $0.titleLabel?.font = TypoStyle.SuitH5.font
        $0.layer.cornerRadius = 13
        $0.layer.borderColor = UIColor.gray_100.cgColor
        $0.layer.borderWidth = 1
        $0.contentEdgeInsets = UIEdgeInsets(top: 6, left: 10, bottom: 6, right: 10)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(button)
        button.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.height.equalTo(26)
        }
        button.addTarget(self, action: #selector(didTap), for: .touchUpInside)
    }
    required init?(coder: NSCoder) { fatalError() }
    @objc private func didTap() { onTap?() }
}
