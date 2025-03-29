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
import Combine
import Core

final class ShareView: UIView {
    //MARK: - Views
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
    lazy var quitButton = UIButton().then{
        $0.setImage(Image.quit, for: .normal)
    }
    let itemNameTextField = UITextField().then{
        $0.borderStyle = .none
        $0.font = TypoStyle.SuitD2.font
        $0.textAlignment = .center
        $0.placeholder = Placeholder.shareItemName
        $0.autocorrectionType = .no
        $0.textColor = .gray_700
        $0.spellCheckingType = .no
    }
    let itemPriceTextField = UITextField().then{
        $0.borderStyle = .none
        $0.font = TypoStyle.MontserratH3.font
        $0.keyboardType = .numberPad
        $0.textAlignment = .center
        $0.placeholder = Placeholder.shareItemPrice
        $0.autocorrectionType = .no
        $0.textColor = .gray_700
        $0.spellCheckingType = .no
    }
    var setNotificationButton = UIButton().then {
        var config = UIButton.Configuration.plain()
        var attText: AttributedString!
        
        attText = AttributedString.init("상품 알림 설정하기")
        attText.font = TypoStyle.SuitD3.font
        attText.foregroundColor = UIColor.gray_700
        config.attributedTitle = attText
        config.image = Image.noti
        config.imagePadding = 4
        config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        
        $0.configuration = config
    }
    let addFolderButton = UIButton().then{
        $0.setImage(Image.addFolder, for: .normal)
    }
    let completeButton = AnimatedButton().then {
        // 로그인 상태가 아닐 때
        if UserManager.accessToken == nil || UserManager.refreshToken == nil {
            $0.setTitle("로그인 후 이용해주세요", for: .normal)
        } else {
            $0.setTitle("위시리스트에 추가", for: .normal)
        }
        $0.layer.cornerRadius = 12
        $0.titleLabel?.font = TypoStyle.SuitH3.font
        $0.isEnabled = false
        $0.clipsToBounds = true
    }
    
    // MARK: - Properties
    private var viewModel: ShareViewModel?
    var folderCollectionView: UICollectionView!
    public var selectedFolderId: Int? {
        didSet {
            DispatchQueue.main.async {
                self.folderCollectionView.reloadData()
            }
        }
    }
    
    //MARK: - Life Cycles
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.setUpCollectionView(dataSourceDelegate: self)
        self.setUpView()
        self.setUpConstraint()
        self.setupTextFieldDelegates()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    // MARK: - Functions
    private func setUpCollectionView(dataSourceDelegate: UICollectionViewDataSource & UICollectionViewDelegate) {
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
            $0.backgroundColor = .white
            $0.register(FolderCollectionViewCell.self, forCellWithReuseIdentifier: FolderCollectionViewCell.reuseIdentifier)
        }
    }
    private func setUpView() {
        addSubview(backgroundView)
        
        backgroundView.addSubview(quitButton)
        backgroundView.addSubview(itemNameTextField)
        backgroundView.addSubview(itemPriceTextField)
        backgroundView.addSubview(setNotificationButton)
        backgroundView.addSubview(addFolderButton)
        backgroundView.addSubview(folderCollectionView)
        backgroundView.addSubview(completeButton)
        
        addSubview(itemImage)
        
        itemNameTextField.attributedPlaceholder = NSAttributedString(
            string: Placeholder.shareItemName,
            attributes: [
                .foregroundColor: UIColor.gray_300,
                .font: TypoStyle.SuitD2.font
            ]
        )
        itemPriceTextField.attributedPlaceholder = NSAttributedString(
            string: Placeholder.shareItemPrice,
            attributes: [
                .foregroundColor: UIColor.gray_300,
                .font: TypoStyle.MontserratH3.font
            ]
        )
        
    }
    private func setUpConstraint() {
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
            make.height.equalTo(50)
            make.leading.trailing.equalToSuperview().inset(16)
            make.top.equalTo(addFolderButton.snp.bottom).offset(16)
            make.bottom.equalToSuperview().offset(-34)
        }
    }
    
    private func setupTextFieldDelegates() {
        itemNameTextField.delegate = self
        itemPriceTextField.delegate = self
        
        // 초기 상태 확인
        updateCompleteButtonState()
    }
    
    /// Complete 버튼 상태를 업데이트하는 메서드
    public func updateCompleteButtonState() {
        // 로그인 상태가 아닐 때
        if UserManager.accessToken == nil || UserManager.refreshToken == nil {
            completeButton.setTitle("로그인 후 이용해주세요", for: .normal)
            completeButton.isEnabled = false
            completeButton.titleLabel?.font = TypoStyle.SuitH3.font
            return
        }
        
        // CompleteBtn 활성화 조건: 아이템이름 + 아이템가격이 채워져있음
        let isItemNameFilled = !(itemNameTextField.text?.isEmpty ?? true)
        let isItemPriceFilled = !(itemPriceTextField.text?.isEmpty ?? true)
        let shouldEnableButton = isItemNameFilled && isItemPriceFilled
        
        completeButton.isEnabled = shouldEnableButton
        completeButton.titleLabel?.font = TypoStyle.SuitH3.font
    }
    
    // MARK: - Public Methods
    func configure(with viewModel: ShareViewModel) {
        self.viewModel = viewModel
        
        // 폴더 바인딩
        viewModel.$folders
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.folderCollectionView.reloadData()
            }
            .store(in: &cancellables)
        
        folderCollectionView.dataSource = self
        
        // 아이템 파싱 바인딩
        viewModel.$item
            .receive(on: RunLoop.main)
            .sink { [weak self] item in
                self?.configureItemImg(item?.item_img)
                self?.configureItemName(item?.item_name)
                self?.configureItemPrice(item?.item_price)
                
                self?.updateCompleteButtonState()
            }
            .store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    // UI Methods
    private func configureItemImg(_ url: String?) {
        if let url = url {
            self.itemImage.loadImage(from: url, placeholder: Image.blackLogo)
        }
    }
    
    private func configureItemName(_ name: String?) {
        self.itemNameTextField.text = name
    }
    
    private func configureItemPrice(_ price: String?) {
        if let price = price {
            let formatPrice = FormatManager.shared.strToPrice(numStr: price)
            self.itemPriceTextField.text = formatPrice
        } else {
            self.itemPriceTextField.text = nil
        }
    }
    
    /// 알람 선택 후 알람설정 버튼 텍스트 업데이트
    public func configureNotiDateButton(_ date: String) {
        if var config = setNotificationButton.configuration {
            var newTitle = AttributedString(date)
            newTitle.font = TypoStyle.SuitD3.font
            newTitle.foregroundColor = UIColor.gray_700
            config.attributedTitle = newTitle
            setNotificationButton.configuration = config
        }
    }
}

// MARK: - CollecionView Delegate
extension ShareView: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel?.folders.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FolderCollectionViewCell.reuseIdentifier, for: indexPath) as? FolderCollectionViewCell else {
            return UICollectionViewCell()
        }
        
        if let item = viewModel?.folders[indexPath.row] {
            cell.configure(with: item)
            if let selectedFolderId = selectedFolderId, let folderId = item.folder_id, selectedFolderId == folderId {
                cell.configureSelectedState(isSelected: true)
            } else {
                cell.configureSelectedState(isSelected: false)
            }
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        UIDevice.vibrate()
        self.endEditing(true)
        
        guard let folderId = viewModel?.folders[indexPath.item].folder_id else {return}
        
        // 폴더 선택/선택해제
        if self.selectedFolderId == folderId {
            self.selectedFolderId = nil
        } else {
            self.selectedFolderId = folderId
        }
    }
    
}

// MARK: - UITextField Delegate
extension ShareView: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        // 가격 텍스트필드 입력 시 숫자 포맷팅
        if textField == itemPriceTextField {
            guard let currentText = textField.text as NSString? else { return true }
            let newText = currentText.replacingCharacters(in: range, with: string)
            let filteredText = newText.filter { $0.isNumber }
            let formattedText = FormatManager.shared.strToPrice(numStr: filteredText)
            textField.text = formattedText
            
            // 입력이 발생할 때마다 호출되며, 입력이 완료된 후 button 상태를 업데이트
            DispatchQueue.main.async { [weak self] in
                self?.updateCompleteButtonState()
            }
            return false
        } else {
            // 입력이 발생할 때마다 호출되며, 입력이 완료된 후 button 상태를 업데이트
            DispatchQueue.main.async { [weak self] in
                self?.updateCompleteButtonState()
            }
            return true
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        // 편집이 종료될 때도 button 상태를 업데이트
        updateCompleteButtonState()
    }
}
