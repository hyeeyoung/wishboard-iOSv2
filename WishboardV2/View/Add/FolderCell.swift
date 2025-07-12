//
//  FolderCell.swift
//  WishboardV2
//
//  Created by gomin on 7/12/25.
//

import Foundation
import UIKit
import Core

final class FolderCell: UICollectionViewCell {
    static let identifier = "FolderCell"
    
    override var isSelected: Bool {
        didSet {
            contentView.backgroundColor = isSelected ? .gray_600 : .gray_50
            label.textColor = isSelected ? .white : .gray_200
        }
    }

    private let label = UILabel().then {
        $0.font = TypoStyle.SuitB5.font
        $0.textColor = .gray_200
        $0.textAlignment = .center
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .gray_50
        contentView.layer.cornerRadius = 13
        contentView.clipsToBounds = true
        
        contentView.addSubview(label)
        label.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview().inset(10)
            make.verticalEdges.equalToSuperview().inset(5.5)
        }
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    func configure(with title: String) {
        label.text = title
    }
}
