//
//  FolderView.swift
//  WishboardV2
//
//  Created by gomin on 8/18/24.
//

import Foundation
import UIKit
import SnapKit

final class FolderView: UIView {
    
    public let toolBar = BaseToolBar()
    public let collectionView: UICollectionView
    
    override init(frame: CGRect) {
        let layout = UICollectionViewFlowLayout()
        let cellWidth = (UIScreen.main.bounds.width - 16 * 3) / 2
        layout.itemSize = CGSize(width: cellWidth, height: cellWidth + 62)
        layout.minimumLineSpacing = 16
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .white
        
        super.init(frame: frame)
        
        setupViews()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        addSubview(toolBar)
        addSubview(collectionView)
        
        collectionView.register(FolderCollectionViewCell.self, forCellWithReuseIdentifier: FolderCollectionViewCell.reuseIdentifier)
    }
    
    private func setupConstraints() {
        toolBar.configure(title: "폴더")
        
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(toolBar.snp.bottom)
            make.horizontalEdges.bottom.equalToSuperview().inset(16)
        }
    }
}
