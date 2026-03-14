//
//  FolderReorderCell.swift
//  WishboardV2
//
//  Created by gomin on 3/14/26.
//


import UIKit
import SnapKit
import Then
import Core
import WBNetwork

final class FolderReorderCell: UITableViewCell {

    static let reuseIdentifier = "FolderReorderCell"

    private let iconImageView = UIImageView().then {
        $0.layer.cornerRadius = 20
        $0.clipsToBounds = true
        $0.contentMode = .scaleToFill
        $0.backgroundColor = .gray_50
    }

    private let titleLabel = UILabel().then {
        $0.font = TypoStyle.SuitD2.font
        $0.textColor = .gray_700
    }

    private let dragIcon = UIImageView().then {
        $0.image = Image.drag
        $0.tintColor = .gray_300
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        addSubview(iconImageView)
        addSubview(titleLabel)
        addSubview(dragIcon)

        iconImageView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(40)
        }

        titleLabel.snp.makeConstraints {
            $0.leading.equalTo(iconImageView.snp.trailing).offset(10)
            $0.centerY.equalToSuperview()
        }

        dragIcon.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-16)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(24)
        }
    }

    required init?(coder: NSCoder) { fatalError() }
    
    override func prepareForReuse() {
        iconImageView.image = nil
    }
    
    func configure(with folder: FolderListResponse) {
        titleLabel.text = folder.folderName
        if let thumbnail = folder.folderThumbnail {
            iconImageView.loadImage(from: thumbnail)
        }
    }
}
