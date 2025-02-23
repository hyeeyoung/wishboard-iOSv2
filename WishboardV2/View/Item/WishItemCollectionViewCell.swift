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
        $0.numberOfLines = 1
        $0.lineBreakMode = .byTruncatingTail
    }
    let itemPrice = UILabel().then{
        $0.setTypoStyleWithSingleLine(typoStyle: .MontserratH3)
    }
    
    // MARK: - Properties
    
    // MARK: - Initializers
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
        
        DispatchQueue.main.async {
            self.itemName.text = nil
            self.itemPrice.text = nil
        }
    }
    
    // MARK: - Setup
    private func setupViews() {
        contentView.addSubview(imageView)
        contentView.addSubview(itemName)
        contentView.addSubview(itemPrice)
    }
    
    private func setupConstraints() {
        imageView.snp.makeConstraints { make in
            make.height.equalTo(imageView.snp.width)
            make.leading.top.trailing.equalToSuperview()
        }
        itemName.snp.makeConstraints { make in
            make.top.equalTo(imageView.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview().inset(10)
        }
        itemPrice.snp.makeConstraints { make in
            make.top.equalTo(itemName.snp.bottom).offset(8)
            make.leading.equalToSuperview().offset(10)
            make.bottom.equalToSuperview().inset(20)
        }
    }
    
    private func setupActions() {
        
    }
    
    // MARK: - Public Methods
    func configure(with item: WishListResponse) {
        // item image
        if let imgUrl = item.item_img_url {
            self.imageView.loadImage(from: imgUrl, placeholder: Image.emptyView)
        } else {
            self.imageView.image = Image.emptyView
        }
        DispatchQueue.main.async {
            // item name
            if let item_name = item.item_name {
                self.configureItemName(with: item_name)
            }
            // item price
            if let item_price = item.item_price {
                self.configurePriceLabel(with: item_price)
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func configureItemName(with name: String) {
        itemName.text = name
    }
    
    private func configurePriceLabel(with price: String) {
        guard let priceStr = FormatManager.shared.strToPrice(numStr: price) else {return}
        let priceText = "\(priceStr)원"
        let attributedString = NSMutableAttributedString(string: priceText)
        
        // 숫자 부분을 굵게 설정
        let priceRange = NSRange(location: 0, length: "\(priceStr)".count)
        attributedString.addAttribute(.font, value: TypoStyle.MontserratH3.font, range: priceRange)
        
        // '원' 부분을 작게 설정
        let currencyRange = NSRange(location: priceRange.length, length: 1)
        attributedString.addAttribute(.font, value: TypoStyle.SuitD3.font, range: currencyRange)
        
        itemPrice.attributedText = attributedString
    }
}
