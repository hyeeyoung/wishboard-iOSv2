//
//  FolderSelectTableViewCell.swift
//  WishboardV2
//
//  Created by gomin on 8/25/24.
//

import Foundation
import UIKit
import SnapKit
import Then
import Core
import WBNetwork

final class FolderSelectTableViewCell: UITableViewCell {
    
    static let identifier = "FolderSelectTableViewCell"
    
    // MARK: - Views
    private let folderImg = UIImageView().then {
        $0.backgroundColor = .black_5
        $0.layer.cornerRadius = 20
        $0.contentMode = .scaleAspectFill
        $0.clipsToBounds = true
    }
    
    private let dimmedView = UIView().then {
        $0.backgroundColor = .black_5
        $0.layer.cornerRadius = 20
        $0.clipsToBounds = true
    }
    
    private let titleLabel = UILabel().then {
        $0.setTypoStyleWithSingleLine(typoStyle: .SuitD2)
        $0.textColor = .gray_700
    }
    
    private let checkBtn = UIButton().then {
        $0.setImage(Image.checkGreen, for: .selected)
        $0.setImage(nil, for: .normal)
    }
    
    // MARK: - Life Cycle
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        folderImg.image = nil
        titleLabel.text = nil
    }
    
    private func setupView() {
        // 기본 셀 설정
        contentView.addSubview(folderImg)
        contentView.addSubview(titleLabel)
        contentView.addSubview(checkBtn)
        folderImg.addSubview(dimmedView)
        
        // Thumbnail 설정
        folderImg.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.width.height.equalTo(40)
            make.leading.equalToSuperview().offset(16)
        }
        
        dimmedView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        // titleLabel 설정
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(folderImg.snp.trailing).offset(10)
            make.centerY.equalToSuperview()
        }
        
        // checkBtn 설정
        checkBtn.snp.makeConstraints { make in
            make.width.height.equalTo(24)
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }
    }
    
    func configure(with folder: FolderListResponse) {
        folderImg.loadImage(from: folder.folder_thumbnail ?? "")
        titleLabel.text = folder.folder_name ?? ""
    }
    
    func configureCheckButton(isSelected: Bool) {
        checkBtn.isSelected = isSelected
    }
}
