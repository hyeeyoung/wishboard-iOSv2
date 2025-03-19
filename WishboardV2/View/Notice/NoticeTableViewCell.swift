//
//  NoticeTableViewCell.swift
//  WishboardV2
//
//  Created by gomin on 8/29/24.
//

import Foundation
import UIKit
import SnapKit
import Then
import Core


final class NoticeTableViewCell: UITableViewCell {
    static let reuseIdentifier = "NoticeTableViewCell"
    
    // MARK: - Views
    
    let background = UIView().then {
        $0.backgroundColor = .gray_50
        $0.layer.cornerRadius = 24
        $0.clipsToBounds = true
        $0.isHidden = true
    }
    let itemImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFill
        $0.backgroundColor = .black_5
        $0.layer.cornerRadius = 40
        $0.clipsToBounds = true
    }
    let notiTypeLabel = UILabel().then {
        $0.text = "재입고 알림"
        $0.setTypoStyleWithSingleLine(typoStyle: .SuitH5)
        $0.textColor = .gray_700
    }
    let readStateView = UIView().then {
        $0.backgroundColor = .green_500
        $0.layer.cornerRadius = 4
        $0.clipsToBounds = true
    }
    let itemNameLabel = UILabel().then {
        $0.text = "itemName"
        $0.setTypoStyleWithMultiLine(typoStyle: .SuitD3)
        $0.numberOfLines = 0
        $0.textColor = .gray_700
    }
    let notiDateLabel = UILabel().then {
        $0.text = "방금 전"
        $0.setTypoStyleWithSingleLine(typoStyle: .SuitD3)
        $0.textColor = .gray_200
    }
    
    // MARK: - Properties
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        contentView.addSubview(background)
        contentView.addSubview(itemImageView)
        contentView.addSubview(notiTypeLabel)
        contentView.addSubview(readStateView)
        contentView.addSubview(itemNameLabel)
        contentView.addSubview(notiDateLabel)
    }
    
    private func setupConstraints() {
        background.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview()
            make.verticalEdges.equalToSuperview().inset(3)
        }
        itemImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(80)
        }
        notiTypeLabel.snp.makeConstraints { make in
            make.leading.equalTo(itemImageView.snp.trailing).offset(10)
            make.top.equalTo(itemImageView)
        }
        readStateView.snp.makeConstraints { make in
            make.leading.equalTo(notiTypeLabel.snp.trailing).offset(4)
            make.width.height.equalTo(8)
            make.centerY.equalTo(notiTypeLabel)
        }
        itemNameLabel.snp.makeConstraints { make in
            make.leading.equalTo(notiTypeLabel)
            make.top.equalTo(notiTypeLabel.snp.bottom).offset(6)
            make.trailing.equalToSuperview().offset(-20)
        }
        notiDateLabel.snp.makeConstraints { make in
            make.leading.equalTo(notiTypeLabel)
            make.bottom.equalTo(itemImageView)
        }
    }
    
    public func configure(with item: NoticeItem) {
        itemNameLabel.text = item.name
        notiTypeLabel.text = "\(item.notiType) 알림"
        if let imageUrl = item.imageUrl {
            self.itemImageView.loadImage(from: imageUrl, placeholder: Image.emptyView)
        } else {
            self.itemImageView.image = Image.emptyView
        }
        self.notiDateLabel.text = FormatManager.shared.createdDateToKoreanStr(item.notiDate)
        self.readStateView.isHidden = item.readState
    }
    
    public func configureCalendarAlarm(with item: NoticeItem) {
        itemNameLabel.text = item.name
        notiTypeLabel.text = "\(item.notiType) 알림"
        if let imageUrl = item.imageUrl {
            self.itemImageView.loadImage(from: imageUrl, placeholder: Image.emptyView)
        } else {
            self.itemImageView.image = Image.emptyView
        }
        self.notiDateLabel.text = createdDateToKoreanStr(item.notiDate)
        self.readStateView.isHidden = item.readState
        self.background.isHidden = false
    }
    
    func createdDateToKoreanStr(_ dateString: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss" // 원본 날짜 포맷
        dateFormatter.locale = Locale(identifier: "ko_KR")
        dateFormatter.timeZone = TimeZone(identifier: "Asia/Seoul")

        guard let date = dateFormatter.date(from: dateString) else {
            return "날짜 오류"
        }

        // 🔥 원하는 출력 형식: "오전 10시" 또는 "오후 3시"
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "a h시" // "a"는 AM/PM, "h"는 12시간제 시
        outputFormatter.locale = Locale(identifier: "ko_KR")

        return outputFormatter.string(from: date)
    }
}
