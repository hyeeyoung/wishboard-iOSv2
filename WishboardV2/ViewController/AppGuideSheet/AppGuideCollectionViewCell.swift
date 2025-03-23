//
//  AppGuideCollectionViewCell.swift
//  WishboardV2
//
//  Created by gomin on 3/7/25.
//

import Foundation
import Core
import UIKit

final class AppGuideCollectionViewCell: UICollectionViewCell {
    
    static let reuseIdentifier = "AppGuideCollectionViewCell"
    
    // MARK: - Views
    private let appGuideImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFit
        $0.backgroundColor = .EDEDED
    }
    private let titleLabel = UILabel().then {
        $0.font = TypoStyle.SuitH1.font
        $0.textColor = .gray_700
        $0.textAlignment = .center
        $0.numberOfLines = 0
    }
    private let descLabel = UILabel().then {
        $0.font = TypoStyle.SuitD2.font
        $0.textColor = .gray_300
        $0.textAlignment = .center
        $0.numberOfLines = 0
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
        titleLabel.text = nil
        descLabel.text = nil
    }
    
    private func setupViews() {
        contentView.addSubview(appGuideImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(descLabel)
    }
    
    private func setupConstraints() {
        appGuideImageView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(411)
        }
        titleLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(appGuideImageView.snp.bottom).offset(24)
        }
        descLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(24)
            make.top.equalTo(titleLabel.snp.bottom).offset(12)
        }
    }
    
    func configure(with item: GuideData) {
        configureImage(item.image)
        configureTitle(item.title)
        configureDesc(item.description)
    }
    
    private func configureImage(_ image: UIImage) {
        self.appGuideImageView.image = image
    }
    
    private func configureTitle(_ title: String) {
        titleLabel.text = title
    }
    
    private func configureDesc(_ desc: String) {
        descLabel.text = desc
    }
}
