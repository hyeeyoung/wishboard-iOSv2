//
//  FolderCollectionViewCell.swift
//  WishboardV2
//
//  Created by gomin on 8/18/24.
//

import Foundation
import UIKit
import SnapKit
import Then
import WBNetwork
import Core

final class FolderCollectionViewCell: UICollectionViewCell {
    
    static let reuseIdentifier = "FolderCollectionViewCell"
    
    // MARK: - Views
    private let folderThumbnailImg = UIImageView().then {
        $0.contentMode = .scaleAspectFill
        $0.layer.cornerRadius = 10
        $0.clipsToBounds = true
        $0.backgroundColor = .black_5
    }
    private let folderNameLabel = UILabel().then {
        $0.text = "폴더이름"
        $0.font = TypoStyle.SuitB2.font
        $0.textColor = .gray_700
        $0.numberOfLines = 1
        $0.lineBreakMode = .byTruncatingTail
    }
    private let itemCountLabel = UILabel().then {
        $0.text = "12 아이템"
        $0.font = TypoStyle.SuitD3.font
        $0.textColor = .gray_300
        $0.numberOfLines = 1
        $0.lineBreakMode = .byTruncatingTail
    }
    private let etcBtn = UIButton().then {
        $0.setImage(Image.more, for: .normal)
    }
    
    // MARK: - Properties
    var etcButtonAction: (() -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupViews()
        setupConstraints()
        setupActions()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        folderNameLabel.text = nil
        itemCountLabel.text = nil
    }
    
    private func setupViews() {
        contentView.addSubview(folderThumbnailImg)
        contentView.addSubview(folderNameLabel)
        contentView.addSubview(itemCountLabel)
        contentView.addSubview(etcBtn)
    }
    
    private func setupConstraints() {
        folderThumbnailImg.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(folderThumbnailImg.snp.width)
        }
        folderNameLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(folderThumbnailImg.snp.bottom).offset(10)
        }
        itemCountLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(folderNameLabel.snp.bottom).offset(6)
            make.bottom.equalToSuperview().offset(-16)
        }
        etcBtn.snp.makeConstraints { make in
            make.width.height.equalTo(24)
            make.trailing.equalTo(folderThumbnailImg)
            make.top.equalTo(folderThumbnailImg.snp.bottom)
        }
    }
    
    private func setupActions() {
        etcBtn.addTarget(self, action: #selector(etcButtonTapped), for: .touchUpInside)
    }
    
    func configure(with folder: FolderListResponse) {
        configureFolderThumbnail(folder.folder_thumbnail)
        configureFolderName(folder.folder_name)
        configureItemCount(folder.item_count)
    }
    
    private func configureFolderThumbnail(_ url: String?) {
        if let url = url {
            folderThumbnailImg.loadImage(from: url, placeholder: Image.emptyView)
        } else {
            folderThumbnailImg.image = Image.emptyView
        }
    }
    
    private func configureFolderName(_ name: String?) {
        if let name = name {
            folderNameLabel.text = name
        }
    }
    
    private func configureItemCount(_ count: Int?) {
        if let count = count {
            itemCountLabel.text = "\(count) 아이템"
        }
    }
    
    @objc private func etcButtonTapped() {
        etcButtonAction?()
    }
}
