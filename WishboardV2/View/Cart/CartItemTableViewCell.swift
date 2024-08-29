//
//  CartItemTableViewCell.swift
//  WishboardV2
//
//  Created by gomin on 8/28/24.
//

import Foundation
import UIKit
import SnapKit
import Then
import Core


final class CartItemTableViewCell: UITableViewCell {
    static let reuseIdentifier = "CartItemTableViewCell"
    
    // MARK: - Views
    
    let itemImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFill
        $0.layer.cornerRadius = 10
        $0.clipsToBounds = true
    }
    let dimmedView = UIView().then {
        $0.backgroundColor = .black_5
        $0.layer.cornerRadius = 10
        $0.clipsToBounds = true
    }
    let itemNameLabel = UILabel().then {
        $0.text = "itemName"
        $0.setTypoStyleWithMultiLine(typoStyle: .SuitD2)
        $0.numberOfLines = 0
    }
    let quantityLabel = UILabel().then {
        $0.text = "quantity"
        $0.setTypoStyleWithSingleLine(typoStyle: .SuitD2)
        $0.textAlignment = .center
    }
    let minusButton = UIButton().then {
        $0.setImage(Image.cartMinus, for: .normal)
    }
    let plusButton = UIButton().then {
        $0.setImage(Image.cartPlus, for: .normal)
    }
    let removeButton = UIButton().then {
        $0.setImage(Image.quit, for: .normal)
    }
    let priceLabel = UILabel()
    
    // MARK: - Properties
    
    var increaseQuantity: (() -> Void)?
    var decreaseQuantity: (() -> Void)?
    var removeItem: (() -> Void)?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
        setupConstraints()
        addTargets()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        contentView.addSubview(itemImageView)
        itemImageView.addSubview(dimmedView)
        contentView.addSubview(itemNameLabel)
        contentView.addSubview(quantityLabel)
        contentView.addSubview(minusButton)
        contentView.addSubview(plusButton)
        contentView.addSubview(removeButton)
        contentView.addSubview(priceLabel)
    }
    
    private func addTargets() {
        minusButton.addTarget(self, action: #selector(minusButtonTapped), for: .touchUpInside)
        plusButton.addTarget(self, action: #selector(plusButtonTapped), for: .touchUpInside)
        removeButton.addTarget(self, action: #selector(removeButtonTapped), for: .touchUpInside)
    }
    
    private func setupConstraints() {
        itemImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(84)
        }
        
        dimmedView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        itemNameLabel.snp.makeConstraints { make in
            make.leading.equalTo(itemImageView.snp.trailing).offset(10)
            make.top.equalTo(itemImageView)
            make.trailing.equalTo(removeButton.snp.leading).offset(6)
        }
        
        minusButton.snp.makeConstraints { make in
            make.leading.equalTo(itemImageView.snp.trailing).offset(10)
            make.bottom.equalTo(itemImageView)
            make.width.height.equalTo(24)
        }
        
        quantityLabel.snp.makeConstraints { make in
            make.leading.equalTo(minusButton.snp.trailing)
            make.centerY.equalTo(minusButton)
            make.width.equalTo(33)
        }
        
        plusButton.snp.makeConstraints { make in
            make.leading.equalTo(quantityLabel.snp.trailing)
            make.centerY.equalTo(minusButton)
            make.width.height.equalTo(24)
        }
        
        removeButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-12)
            make.top.equalTo(itemImageView)
            make.width.height.equalTo(24)
        }
        
        priceLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-12)
            make.bottom.equalTo(itemImageView)
        }
    }
    
    @objc private func minusButtonTapped() {
        decreaseQuantity?()
    }
    
    @objc private func plusButtonTapped() {
        increaseQuantity?()
    }
    
    @objc private func removeButtonTapped() {
        removeItem?()
    }
    
    public func configure(with item: CartItem) {
        itemNameLabel.text = item.name
        quantityLabel.text = "\(item.quantity)"
        self.configurePriceLabel(with: String(item.itemTotalPrice))
        self.itemImageView.loadImage(from: item.imageUrl)
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
        
        priceLabel.attributedText = attributedString
    }
}
