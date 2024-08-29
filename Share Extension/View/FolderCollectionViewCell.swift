//
//  FolderCollectionViewCell.swift
//  Share Extension
//
//  Created by gomin on 8/25/24.
//

import Foundation
import UIKit
import SnapKit
import Then
import WBNetwork
import Core

final class FolderCollectionViewCell: UICollectionViewCell {
    
    public static let reuseIdentifier = "FolderCollectionViewCell"
    
    // MARK: - Views
    private let folderThumbnailImg = UIImageView().then {
        $0.contentMode = .scaleAspectFill
        $0.layer.cornerRadius = 10
        $0.clipsToBounds = true
        $0.backgroundColor = .black_5
    }
    private let dimmedView = UIView().then {
        $0.layer.cornerRadius = 10
        $0.clipsToBounds = true
        $0.backgroundColor = .black_3
    }
    private let folderNameLabel = UILabel().then {
        $0.text = "폴더이름"
        $0.font = TypoStyle.SuitH6.font
        $0.textColor = .white
        $0.numberOfLines = 1
        $0.textAlignment = .center
    }
    private let selectedCheckImg = UIImageView().then {
        $0.image = Image.checkWhite
        $0.isHidden = true
    }
    
    // MARK: - Properties
    var etcButtonAction: (() -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupViews()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        folderThumbnailImg.image = nil
        folderNameLabel.text = nil
    }
    
    private func setupViews() {
        contentView.addSubview(folderThumbnailImg)
        folderThumbnailImg.addSubview(dimmedView)
        dimmedView.addSubview(folderNameLabel)
        dimmedView.addSubview(selectedCheckImg)
    }
    
    private func setupConstraints() {
        folderThumbnailImg.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        dimmedView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        folderNameLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(12)
            make.bottom.equalToSuperview().offset(-6)
        }
        selectedCheckImg.snp.makeConstraints { make in
            make.width.height.equalTo(32)
            make.center.equalToSuperview()
        }
    }
    
    func configure(with folder: FolderListResponse) {
        folderThumbnailImg.loadImage(from: folder.folder_thumbnail ?? "")
        folderNameLabel.text = folder.folder_name ?? ""
    }
    
    func configureSelectedState(isSelected: Bool) {
        if isSelected {
            dimmedView.backgroundColor = .black_7
            selectedCheckImg.isHidden = false
        } else {
            dimmedView.backgroundColor = .black_3
            selectedCheckImg.isHidden = true
        }
    }
    
}
