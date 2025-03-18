//
//  CalendarCell.swift
//  WishboardV2
//
//  Created by gomin on 3/18/25.
//

import Foundation
import UIKit
import Core

class CalendarCell: UICollectionViewCell {
    static let identifier = "CalendarCell"
    
    private let dayLabel = UILabel()
    private let alarmBackgroundView = UIView()
    private let stickerView = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        dayLabel.textAlignment = .center
        contentView.addSubview(alarmBackgroundView)
        contentView.addSubview(dayLabel)
        contentView.addSubview(stickerView)
        
        dayLabel.textColor = .gray_700
        
        alarmBackgroundView.backgroundColor = .green_200
        alarmBackgroundView.layer.cornerRadius = 16.665
        alarmBackgroundView.clipsToBounds = true
        
        stickerView.backgroundColor = .green_500
        stickerView.layer.cornerRadius = 5
        stickerView.clipsToBounds = true
        
        dayLabel.snp.makeConstraints { make in
            make.centerX.centerY.equalTo(contentView)
        }
        alarmBackgroundView.snp.makeConstraints { make in
            make.width.height.equalTo(33.33)
            make.center.equalTo(dayLabel)
        }
        stickerView.snp.makeConstraints { make in
            make.width.height.equalTo(10)
            make.centerY.equalTo(alarmBackgroundView.snp.top)
            make.centerX.equalTo(dayLabel)
        }
        
        self.bringSubviewToFront(dayLabel)
    }
    
    func configure(day: Int, hasAlarm: Bool, isSelected: Bool, isCurrentMonth: Bool, isToday: Bool) {
        dayLabel.text = "\(day)"
        dayLabel.font = isSelected ? TypoStyle.SuitH3.font : TypoStyle.SuitD1.font
        dayLabel.textColor = isCurrentMonth ? .gray_700 : .white
        stickerView.isHidden = !isToday
        
        alarmBackgroundView.isHidden = !hasAlarm
        alarmBackgroundView.backgroundColor = hasAlarm ? .green_200 : nil
    }
}
