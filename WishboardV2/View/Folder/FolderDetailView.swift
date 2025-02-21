//
//  FolderDetailView.swift
//  WishboardV2
//
//  Created by gomin on 8/25/24.
//

import Foundation
import UIKit
import SnapKit
import Combine
import Core


final class FolderDetailView: UIView {
    
    // MARK: - Views
    public let toolbar = ToolBar()
    private var folderTitle: String?
    public let collectionView: UICollectionView
    private let emptyLabel = UILabel().then {
        $0.text = "앗, 아이템이 없어요!\n갖고 싶은 아이템을 등록해 보세요!"
        $0.setTypoStyleWithMultiLine(typoStyle: .SuitD2)
        $0.textColor = .gray_200
        $0.numberOfLines = 0
        $0.textAlignment = .center
        $0.isHidden = true
    }
    
    // MARK: - Initializers
    
    private var viewModel: FolderDetailViewModel?
    
    override init(frame: CGRect) {
        let layout = UICollectionViewFlowLayout()
        let cellWidth = UIScreen.main.bounds.width / 2
        layout.itemSize = CGSize(width: cellWidth, height: cellWidth + 70)
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .white
        
        super.init(frame: frame)
    }
    
    convenience init(folderTitle: String) {
        self.init()
        self.folderTitle = folderTitle
        
        setupViews()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupViews() {
        addSubview(toolbar)
        addSubview(collectionView)
        addSubview(emptyLabel)
        
        collectionView.register(WishItemCollectionViewCell.self, forCellWithReuseIdentifier: WishItemCollectionViewCell.reuseIdentifier)
    }
    
    private func setupConstraints() {
        toolbar.configure(title: folderTitle ?? "")
        
        collectionView.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview()
            make.top.equalTo(toolbar.snp.bottom)
            make.bottom.equalToSuperview()
        }
        
        emptyLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
    
    // MARK: - Public Methods
    func configure(with viewModel: FolderDetailViewModel) {
        self.viewModel = viewModel
        
        viewModel.$items
            .receive(on: RunLoop.main)
            .sink { [weak self] items in
                self?.emptyLabel.isHidden = !(items.isEmpty)
                self?.collectionView.reloadData()
            }
            .store(in: &cancellables)
        
        collectionView.dataSource = self
    }
    
    private var cancellables = Set<AnyCancellable>()
}

extension FolderDetailView: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel?.items.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: WishItemCollectionViewCell.reuseIdentifier, for: indexPath) as? WishItemCollectionViewCell else {
            return UICollectionViewCell()
        }
        
        if let item = viewModel?.items[indexPath.row] {
            cell.configure(with: item)
            cell.cartButtonAction = { [weak self] in
                self?.viewModel?.toggleCartState(for: item)
            }
        }
        return cell
    }
}
