//
//  CartView.swift
//  WishboardV2
//
//  Created by gomin on 8/28/24.
//

import Foundation
import UIKit
import SnapKit
import Then
import Core

final class CartView: UIView {
    let toolBar = ToolBar()
    let tableView = UITableView()
    let bottomButtonBar = UIView().then {
        $0.backgroundColor = .green_500
    }
    let bottomView = UIView().then {
        $0.backgroundColor = .green_500
    }
    let totalQuantityLabel = UILabel().then {
        $0.textColor = .gray_700
    }
    let totalPriceLabel = UILabel().then {
        $0.textColor = .gray_700
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        addSubview(toolBar)
        addSubview(tableView)
        addSubview(bottomButtonBar)
        addSubview(bottomView)
        
        bottomButtonBar.addSubview(totalQuantityLabel)
        bottomButtonBar.addSubview(totalPriceLabel)
    }
    
    private func setupConstraints() {
        toolBar.configure(title: "장바구니")
        
        tableView.snp.makeConstraints { make in
            make.top.equalTo(toolBar.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(bottomButtonBar.snp.top)
        }
        
        bottomButtonBar.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(self.safeAreaLayoutGuide)
            make.height.equalTo(44)
        }
        
        bottomView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.top.equalTo(bottomButtonBar.snp.bottom)
        }
        
        totalQuantityLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
        }
        
        totalPriceLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }
    }
    
    /// 장바구니 아이템 총 개수
    public func configureQuantityLabel(with quantity: Int) {
        let quantityText = "전체 \(quantity) 개"
        let attributedString = NSMutableAttributedString(string: quantityText)
        
        // '전체' 부분
        var currencyRange = NSRange(location: 0, length: "전체 ".count)
        attributedString.addAttribute(.font, value: TypoStyle.SuitD2.font, range: currencyRange)
        
        // 숫자 부분을 굵게 설정
        let quantityRange = NSRange(location: currencyRange.length, length: "\(quantity)".count)
        attributedString.addAttribute(.font, value: TypoStyle.MontserratH2.font, range: quantityRange)
        
        // '개' 부분
        currencyRange = NSRange(location: quantityRange.length, length: 1)
        attributedString.addAttribute(.font, value: TypoStyle.SuitD2.font, range: currencyRange)
        
        totalQuantityLabel.attributedText = attributedString
    }
    
    /// 장바구니 아이템 총 가격
    public func configurePriceLabel(with price: String) {
        guard let priceStr = FormatManager.shared.strToPrice(numStr: price) else {return}
        let priceText = "\(priceStr)원"
        let attributedString = NSMutableAttributedString(string: priceText)
        
        // 숫자 부분을 굵게 설정
        let priceRange = NSRange(location: 0, length: "\(priceStr)".count)
        attributedString.addAttribute(.font, value: TypoStyle.MontserratH2.font, range: priceRange)
        
        // '원' 부분을 작게 설정
        let currencyRange = NSRange(location: priceRange.length, length: 1)
        attributedString.addAttribute(.font, value: TypoStyle.SuitD2.font, range: currencyRange)
        
        totalPriceLabel.attributedText = attributedString
    }
}
