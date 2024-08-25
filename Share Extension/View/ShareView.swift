//
//  ShareView.swift
//  Share Extension
//
//  Created by gomin on 8/25/24.
//

import Foundation
import UIKit
import SnapKit
import Then
import Core

final class ShareView: UIView, UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return UICollectionViewCell()
    }
    
    //MARK: - Properties
    let itemImage = UIImageView().then{
        $0.backgroundColor = .systemGray6
        $0.clipsToBounds = true
        $0.layer.cornerRadius = 40
        $0.image = Image.blackLogo
        $0.contentMode = .scaleAspectFill
    }
    let backgroundView = UIView().then{
        $0.backgroundColor = .white
        $0.layer.cornerRadius = 20
        $0.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
    }
//    let backgroundViewSquare = UIView().then {
//        $0.backgroundColor = .white
//    }
    lazy var quitButton = UIButton().then{
        $0.setImage(Image.quit, for: .normal)
    }
    let itemNameTextField = UITextField().then{
        $0.borderStyle = .none
        $0.font = TypoStyle.SuitD2.font
        $0.textAlignment = .center
        $0.placeholder = Placeholder.shareItemName
    }
    let itemPriceTextField = UITextField().then{
        $0.borderStyle = .none
        $0.font = TypoStyle.MontserratH3.font
        $0.keyboardType = .numberPad
        $0.textAlignment = .center
        $0.placeholder = Placeholder.shareItemPrice
    }
    var setNotificationButton = UIButton().then {
        var config = UIButton.Configuration.plain()
        var attText: AttributedString!
        
        attText = AttributedString.init(" 상품 알림 설정하기")
        attText.font = TypoStyle.SuitD3.font
        attText.foregroundColor = UIColor.gray_700
        config.attributedTitle = attText
        config.image = Image.noti
        config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        
        $0.configuration = config
    }
    let addFolderButton = UIButton().then{
        $0.setImage(Image.addFolder, for: .normal)
    }
    let completeButton = AnimatedButton().then{
        $0.setTitle("위시리스트에 추가", for: .normal)
        $0.layer.cornerRadius = 24
        $0.setTitleColor(.gray_300, for: .normal)
        $0.titleLabel?.font = TypoStyle.SuitH3.font
        $0.backgroundColor = .gray_100
        $0.isEnabled = false
    }
    //MARK: - Life Cycles
    var folderCollectionView: UICollectionView!
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.setUpCollectionView(dataSourceDelegate: self)
        self.setUpView()
        self.setUpConstraint()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    // MARK: - Functions
    func setUpCollectionView(dataSourceDelegate: UICollectionViewDataSource & UICollectionViewDelegate) {
        folderCollectionView = UICollectionView(frame: .zero, collectionViewLayout: .init()).then{
            let flowLayout = UICollectionViewFlowLayout()
            flowLayout.minimumInteritemSpacing = 0
            flowLayout.minimumLineSpacing = 10
            
            
            flowLayout.itemSize = CGSize(width: 80, height: 80)
            flowLayout.scrollDirection = .horizontal
            
            $0.collectionViewLayout = flowLayout
            $0.dataSource = dataSourceDelegate
            $0.delegate = dataSourceDelegate
            $0.showsHorizontalScrollIndicator = false
            
//            $0.register(FolderCollectionViewCell.self, forCellWithReuseIdentifier: FolderCollectionViewCell.identifier)
        }
    }
    func setUpView() {
        addSubview(backgroundView)
//        addSubview(backgroundViewSquare)
        
        backgroundView.addSubview(quitButton)
        backgroundView.addSubview(itemNameTextField)
        backgroundView.addSubview(itemPriceTextField)
        backgroundView.addSubview(setNotificationButton)
        backgroundView.addSubview(addFolderButton)
        backgroundView.addSubview(folderCollectionView)
        backgroundView.addSubview(completeButton)
        
        addSubview(itemImage)
    }
    func setUpConstraint() {
//        backgroundViewSquare.snp.makeConstraints { make in
//            make.bottom.leading.trailing.equalToSuperview()
//            make.height.equalTo(20)
//        }
        backgroundView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(317)
        }
        itemImage.snp.makeConstraints { make in
            make.width.height.equalTo(80)
            make.centerX.equalToSuperview()
            make.centerY.equalTo(backgroundView.snp.top)
        }
        quitButton.snp.makeConstraints { make in
            make.width.height.equalTo(24)
            make.trailing.equalToSuperview().offset(-16)
            make.top.equalToSuperview().offset(12)
        }
        itemNameTextField.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(16)
            make.top.equalTo(itemImage.snp.bottom).offset(16)
        }
        itemPriceTextField.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(itemNameTextField.snp.bottom).offset(6)
        }
        setNotificationButton.snp.makeConstraints { make in
            make.height.equalTo(14)
            make.centerX.equalToSuperview()
            make.top.equalTo(itemPriceTextField.snp.bottom).offset(16)
        }
        addFolderButton.snp.makeConstraints { make in
            make.width.height.equalTo(80)
            make.leading.equalToSuperview().offset(16)
            make.top.equalTo(setNotificationButton.snp.bottom).offset(16)
        }
        folderCollectionView.snp.makeConstraints { make in
            make.leading.equalTo(addFolderButton.snp.trailing).offset(10)
            make.top.bottom.equalTo(addFolderButton)
            make.trailing.equalToSuperview()
        }
        completeButton.snp.makeConstraints { make in
            make.height.equalTo(48)
            make.leading.trailing.equalToSuperview().inset(16)
            make.top.equalTo(addFolderButton.snp.bottom).offset(16)
            make.bottom.equalToSuperview().offset(-34)
//            make.bottom.greaterThanOrEqualToSuperview().offset(-34)
        }
    }
}
