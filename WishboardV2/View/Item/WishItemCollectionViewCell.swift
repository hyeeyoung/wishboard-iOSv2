//
//  ItemCollectionViewCell.swift
//  WishboardV2
//
//  Created by gomin on 8/17/24.
//

import Foundation
import UIKit
import SnapKit
import Then
import Core
import WBNetwork

final class WishItemCollectionViewCell: UICollectionViewCell {
    
    static let reuseIdentifier = "WishItemCollectionViewCell"
    
    // MARK: - Views
    
    let imageView = UIImageView().then{
        $0.backgroundColor = .black_5
        $0.clipsToBounds = true
        $0.contentMode = .scaleAspectFill
    }
    let itemName = UILabel().then{
        $0.setTypoStyleWithSingleLine(typoStyle: .SuitD3)
        $0.lineBreakMode = .byTruncatingTail
    }
    let itemPrice = UILabel().then{
        $0.setTypoStyleWithSingleLine(typoStyle: .MontserratH3)
    }
    let collectionTag = UIView().then {
        $0.backgroundColor = .green_alpha_80
    }
    let collectionTagTitle = UILabel().then {
        $0.text = "소장템"
        $0.textColor = .white
        $0.font = TypoStyle.SuitB5.font
    }
    
    // MARK: - Initializers
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupViews()
        setupTwoColumnConstraints()
        setupActions()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupViews() {
        contentView.addSubview(imageView)
        contentView.addSubview(itemName)
        contentView.addSubview(itemPrice)
        contentView.addSubview(collectionTag)
        collectionTag.addSubview(collectionTagTitle)
    }
    
    private func setupTwoColumnConstraints() {
        imageView.snp.remakeConstraints { make in
            make.height.equalTo(imageView.snp.width)
            make.leading.top.trailing.equalToSuperview()
        }
        itemName.snp.remakeConstraints { make in
            make.top.equalTo(imageView.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview().inset(10)
        }
        itemPrice.snp.remakeConstraints { make in
            make.top.equalTo(itemName.snp.bottom).offset(8)
            make.leading.equalToSuperview().offset(10)
            make.bottom.lessThanOrEqualToSuperview().inset(20)
        }
        collectionTag.snp.remakeConstraints { make in
            make.bottom.leading.equalTo(imageView)
            make.height.equalTo(22)
        }
        collectionTagTitle.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(6)
            make.top.bottom.equalToSuperview()
        }
        itemName.numberOfLines = 2
        imageView.layer.cornerRadius = 0
        imageView.clipsToBounds = true
    }
    
    private func setupTripleColumnConstraints() {
        imageView.snp.remakeConstraints { make in
            make.height.equalTo(imageView.snp.width)
            make.leading.top.trailing.equalToSuperview()
        }
        itemName.snp.remakeConstraints { make in
            make.top.equalTo(imageView.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview().inset(10)
        }
        itemPrice.snp.remakeConstraints { make in
            make.top.equalTo(itemName.snp.bottom).offset(8)
            make.leading.equalToSuperview().offset(10)
            make.bottom.lessThanOrEqualToSuperview().inset(20)
        }
        collectionTag.snp.remakeConstraints { make in
            make.bottom.leading.equalTo(imageView)
            make.height.equalTo(22)
        }
        collectionTagTitle.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(6)
            make.top.bottom.equalToSuperview()
        }
        itemName.numberOfLines = 3
        imageView.layer.cornerRadius = 0
        imageView.clipsToBounds = true
    }

    private func setupOneColumnConstraints() {
        imageView.snp.remakeConstraints { make in
            make.top.bottom.equalToSuperview().inset(10)
            make.width.height.equalTo(84)
            make.leading.equalToSuperview().offset(16)
        }
        itemName.snp.remakeConstraints { make in
            make.top.equalTo(imageView)
            make.leading.equalTo(imageView.snp.trailing).offset(10)
            make.trailing.equalToSuperview().inset(16)
        }
        itemPrice.snp.remakeConstraints { make in
            make.trailing.equalToSuperview().inset(16)
            make.bottom.equalTo(imageView)
            make.top.greaterThanOrEqualTo(itemName.snp.bottom).offset(16)
        }
        collectionTag.snp.remakeConstraints { make in
            make.bottom.equalTo(imageView)
            make.leading.equalTo(imageView.snp.trailing).offset(10)
            make.trailing.lessThanOrEqualTo(itemPrice.snp.leading).offset(-10)
            make.height.equalTo(22)
        }
        collectionTagTitle.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(6)
            make.top.bottom.equalToSuperview()
        }
        itemName.numberOfLines = 2
        imageView.layer.cornerRadius = 10
        imageView.clipsToBounds = true
    }
    
    private func setupActions() {
        
    }
    
    // MARK: - Public Methods
    func configure(with item: WishListResponse, columnType: GridColumnType = .two) {
        switch columnType {
        case .one:
            setupOneColumnConstraints()
        case .two:
            setupTwoColumnConstraints()
        case .three:
            setupTripleColumnConstraints()
        }

        // item image
        if let itemImages = item.itemImages, !itemImages.isEmpty, let imgUrl = itemImages[0].itemImageUrl {
            self.imageView.loadImage(from: imgUrl, placeholder: Image.emptyView)
        } else {
            self.imageView.image = Image.emptyView
        }
        // item name
        if let itemName = item.itemName {
            self.configureItemName(with: itemName)
        }
        // item price
        if let itemPrice = item.itemPrice {
            self.configurePriceLabel(with: itemPrice)
        }
        // item status
        let isCollected = (item.itemStatus == .owned)
        self.configureCollection(with: isCollected)
    }
    
    // MARK: - Private Methods
    
    private func configureItemName(with name: String) {
        itemName.text = name
    }
    
    private func configurePriceLabel(with price: String) {
        guard let priceStr = FormatManager.shared.strToPrice(numStr: price) else {return}
        let priceText = "\(priceStr)원"
        let attributedString = NSMutableAttributedString(string: priceText)
        
        let priceRange = NSRange(location: 0, length: "\(priceStr)".count)
        attributedString.addAttribute(.font, value: TypoStyle.MontserratH3.font, range: priceRange)
        
        let currencyRange = NSRange(location: priceRange.length, length: 1)
        attributedString.addAttribute(.font, value: TypoStyle.SuitD3.font, range: currencyRange)
        
        itemPrice.attributedText = attributedString
    }
    
    private func configureCollection(with isCollected: Bool) {
        self.collectionTag.isHidden = !isCollected
    }
}
