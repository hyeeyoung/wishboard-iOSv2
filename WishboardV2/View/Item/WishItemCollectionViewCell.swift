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
        $0.backgroundColor = .gray_50
    }
    let itemName = UILabel().then{
        $0.setTypoStyleWithSingleLine(typoStyle: .SuitD3)
        $0.numberOfLines = 1
        $0.lineBreakMode = .byTruncatingTail
    }
    let itemPrice = UILabel().then{
        $0.setTypoStyleWithSingleLine(typoStyle: .MontserratH3)
    }
    let cartButton = UIButton().then{
        var config = UIButton.Configuration.tinted()
        var attText = AttributedString.init("Cart")
        
        attText.font = TypoStyle.SuitD3.font
        config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        attText.foregroundColor = UIColor.gray_700
        config.attributedTitle = attText
        config.background.backgroundColor = .white
        config.baseForegroundColor = .gray_700
        config.cornerStyle = .capsule
        
        $0.configuration = config
    }
    
    // MARK: - Properties
    var cartButtonAction: (() -> Void)?
    
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
            self.imageView.image = nil
            self.itemName.text = nil
            self.itemPrice.text = nil
        }
    }
    
    // MARK: - Setup
    private func setupViews() {
        contentView.addSubview(imageView)
        contentView.addSubview(cartButton)
        contentView.addSubview(itemName)
        contentView.addSubview(itemPrice)
    }
    
    private func setupConstraints() {
        imageView.snp.makeConstraints { make in
            make.height.equalTo(imageView.snp.width)
            make.leading.top.trailing.equalToSuperview()
        }
        cartButton.snp.makeConstraints { make in
            make.width.height.equalTo(38)
            make.bottom.trailing.equalTo(imageView).inset(10)
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
        cartButton.addTarget(self, action: #selector(cartButtonTapped), for: .touchUpInside)
    }
    
    // MARK: - Public Methods
    func configure(with item: WishListResponse) {
        // item image
        if let imgUrl = item.item_img_url {
            self.imageView.loadImage(from: imgUrl)
        }
        DispatchQueue.main.async {
            // item cart state
            self.updateCartButtonState(isInCart: item.cart_state == 1)
            
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
    private func updateCartButtonState(isInCart: Bool) {
        if isInCart {
            cartButton.configuration?.background.backgroundColor = .green_500
        } else {
            cartButton.configuration?.background.backgroundColor = .white
        }
    }
    
    private func configureItemName(with name: String) {
        itemName.text = name
    }
    
    private func configurePriceLabel(with price: String) {
        let priceText = "\(price)원"
        let attributedString = NSMutableAttributedString(string: priceText)
        
        // 숫자 부분을 굵게 설정
        let priceRange = NSRange(location: 0, length: "\(price)".count)
        attributedString.addAttribute(.font, value: TypoStyle.MontserratH3.font, range: priceRange)
        
        // '원' 부분을 작게 설정
        let currencyRange = NSRange(location: priceRange.length, length: 1)
        attributedString.addAttribute(.font, value: TypoStyle.SuitD3.font, range: currencyRange)
        
        itemPrice.attributedText = attributedString
    }
    
    @objc private func cartButtonTapped() {
        cartButtonAction?()
    }
}
