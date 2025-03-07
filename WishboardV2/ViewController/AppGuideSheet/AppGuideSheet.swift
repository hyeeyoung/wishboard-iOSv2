//
//  AppGuideSheet.swift
//  WishboardV2
//
//  Created by gomin on 3/7/25.
//

import Foundation
import UIKit
import SnapKit
import Then
import Combine

import Core
import WBNetwork

struct GuideData {
    var image: UIImage
    var title: String
    var description: String
}

final class AppGuideSheet: UIView {
    
    // MARK: - UI Components
    
    public let collectionView: UICollectionView
    
    private let pageControl = UIPageControl().then {
       $0.currentPage = 0
       $0.numberOfPages = 3
       $0.pageIndicatorTintColor = UIColor.gray_150
       $0.currentPageIndicatorTintColor = UIColor.gray_700
   }
    
    private let ctaButton = UIButton(type: .system).then {
        $0.tintColor = .gray_700
        $0.setTitle("네! 알겠어요", for: .normal)
        $0.setTitleColor(.white, for: .normal)
        $0.titleLabel?.font = TypoStyle.SuitH3.font
        $0.layer.cornerRadius = 12
        $0.clipsToBounds = true
        $0.backgroundColor = .gray_700
    }
    
    // MARK: - Properties
    private var cancellables = Set<AnyCancellable>()
    
    var onTapped: (() -> Void)?
    private var guideData: [GuideData] = [
        GuideData(image: Image.how1, 
                  title: "아이템 저장",
                  description: "웹 브라우저에서 사고 싶은 아이템이 있다면\n“공유하기”로 아이템을 위시보드에 저장해 보세요!"),
        GuideData(image: Image.how2, 
                  title: "폴더 지정",
                  description: "아이템에 폴더를 지정해 보세요!\n원하는 폴더가 없다면 새 폴더를 추가할 수 있어요."),
        GuideData(image: Image.how3, 
                  title: "알림 설정",
                  description: "상품의 재입고, 프리오더, 세일 알림을 설정해 보세요.\n설정한 시간 30분 전에 알림 보내드려요!")
    ]
    
    // MARK: - Initializer
    override init(frame: CGRect) {
        
        let layout = UICollectionViewFlowLayout()
        let cellWidth = (UIScreen.main.bounds.width)
        layout.itemSize = CGSize(width: cellWidth, height: 600)
        layout.minimumLineSpacing = 0
        layout.scrollDirection = .horizontal
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .white
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.isPagingEnabled = true
        collectionView.register(AppGuideCollectionViewCell.self, forCellWithReuseIdentifier: AppGuideCollectionViewCell.reuseIdentifier)
        
        super.init(frame: frame)
        
        collectionView.dataSource = self
        collectionView.delegate = self
        pageControl.numberOfPages = guideData.count
        
        setupView()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup View
    
    private func setupView() {
        backgroundColor = .white
        layer.cornerRadius = 20
        layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        
        addSubview(collectionView)
        addSubview(pageControl)
        addSubview(ctaButton)
        
        ctaButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
    }
    
    private func setupConstraints() {
        
        collectionView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(411)
        }
        pageControl.snp.makeConstraints { make in
            make.bottom.equalTo(ctaButton.snp.top).offset(-22)
            make.centerX.equalToSuperview()
        }
        ctaButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalTo(self.safeAreaLayoutGuide).inset(16)
            make.height.equalTo(50)
        }
    }
    
    @objc private func closeButtonTapped() {
        onTapped?()
    }
    
    
    // MARK: - Public Methods
    
    func configure() {
        self.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(639)
        }
    }
}

// MARK: - CollectionView Delegate
extension AppGuideSheet: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.guideData.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AppGuideCollectionViewCell.reuseIdentifier, for: indexPath) as? AppGuideCollectionViewCell else {
            return UICollectionViewCell()
        }
        
        cell.configure(with: self.guideData[indexPath.row])
        return cell
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let pageIndex = Int(round(scrollView.contentOffset.x / scrollView.frame.width))
        pageControl.currentPage = pageIndex
    }
}
