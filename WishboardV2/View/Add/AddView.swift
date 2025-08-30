//
//  AddView.swift
//  WishboardV2
//
//  Created by gomin on 2/22/25.
//

import Foundation
import UIKit
import SnapKit
import Combine
import Then
import Core

final class AddView: UIView {
    
    // MARK: - UI Components
    
    let toolBar = AddToolBar()
    
    let scrollView = UIScrollView().then {
        $0.showsVerticalScrollIndicator = false
        $0.keyboardDismissMode = .onDrag
    }
    
    let contentView = UIView()
    
    // Image CollectionView
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 100, height: 100)
        layout.minimumInteritemSpacing = 8
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 16)

        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.dataSource = self
        cv.delegate = self
        cv.isScrollEnabled = true
        cv.showsHorizontalScrollIndicator = false
        cv.register(NewCameraCell.self, forCellWithReuseIdentifier: NewCameraCell.identifier)
        cv.register(SelectedImageCell.self, forCellWithReuseIdentifier: SelectedImageCell.identifier)
        return cv
    }()
    
    // Contents
    
    let stackView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 0
        $0.alignment = .fill
        $0.distribution = .fill
    }
    
    let itemNameSection = FormItemView(title: Title.itemName,
                                       isRequired: true,
                                       type: .textField(placeholder: Placeholder.uploadItemName,
                                                        isEditable: true,
                                                        showsArrow: false,
                                                        showsNumberPad: false))
    
    let itemPriceSection = FormItemView(title: Title.price,
                                       isRequired: true,
                                       type: .textField(placeholder: Placeholder.uploadItemPrice,
                                                        isEditable: true,
                                                        showsArrow: false,
                                                        showsNumberPad: true))
    
    let folderSection = FolderFormItemView(title: Title.folder, isRequired: false)
    
    let alarmSection = FormItemView(title: Title.notificationItem,
                                    isRequired: false,
                                    type: .textField(placeholder: Placeholder.uploadItemNoti,
                                                     isEditable: false,
                                                     showsArrow: true,
                                                     showsNumberPad: false))
     
    let itemLinkSection = FormItemView(title: Title.shoppingMallLink,
                                       isRequired: false,
                                       type: .textField(placeholder: Placeholder.uploadItemLink,
                                                        isEditable: false,
                                                        showsArrow: true,
                                                        showsNumberPad: false))
    
    let memoSection = FormItemView(title: Title.memo, isRequired: false, type: .textView)
    
    let separatorViews: [UIView] = Array(repeating: UIView().then {
        $0.backgroundColor = .gray_100
    }, count: 6)
    
    // MARK: - Properties
    public var selectedImages: [UIImage] = []
    public var selectNewImageAction: (() -> Void)?
    public weak var delegate: ActiveFieldDelegate?
    private let viewModel: AddViewModel
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Init
    init(viewModel: AddViewModel) {
        self.viewModel = viewModel
        super.init(frame: .zero)
        
        setupUI()
        setupDelegates()
        setupBindings()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        addSubview(toolBar)
        addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(collectionView)
        contentView.addSubview(stackView)
        
        toolBar.configure(title: Title.addItem)
        
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(toolBar.snp.bottom)
            make.horizontalEdges.equalToSuperview()
            make.bottom.equalTo(super.safeAreaLayoutGuide)
        }
        
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
        }
        
        collectionView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(18)
            make.leading.equalToSuperview().offset(16)
            make.height.equalTo(100)
            make.trailing.equalToSuperview()
        }
        
        stackView.snp.makeConstraints { make in
            make.top.equalTo(collectionView.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview().offset(-16)
        }

        let fields: [UIView] = [
            itemNameSection, itemPriceSection, folderSection, alarmSection, itemLinkSection, memoSection
        ]
        
        for (index, field) in fields.enumerated() {
            let separatorView = UIView().then { $0.backgroundColor = .gray_100 }
            
            stackView.addArrangedSubview(field)
            
            if field == memoSection {
                field.snp.makeConstraints { make in
                    make.height.equalTo(362)
                }
            } else {
                field.snp.makeConstraints { make in
                    make.height.equalTo(84)
                }
            }
            
            if index < fields.count - 1 { // 마지막 항목에는 구분선 안 붙이기
                stackView.addArrangedSubview(separatorView)
                separatorView.snp.makeConstraints { make in
                    make.height.equalTo(0.5)
                }
            }
        }
    }
    
    private func setupDelegates() {
        itemPriceSection.onTextChanged = { [weak self] textField in
            self?.delegate?.setActiveField(textField)
            self?.priceTextChanged(textField)
        }
        itemNameSection.onTextChanged = { [weak self] textField in
            self?.delegate?.setActiveField(textField)
        }
    }
    
    private func setupBindings() {
        viewModel.$selectedImages
            .receive(on: RunLoop.main)
            .sink { [weak self] images in
                self?.updateImages(images)
            }
            .store(in: &cancellables)
        
        folderSection.loadNextPageAction = { [weak self] index in
            self?.viewModel.loadNextIfNeeded(currentIndex: index)
        }
    }
    
    private func priceTextChanged(_ textField: UITextField) {
        // 숫자만 필터링
        let currentText = textField.text ?? ""
        let filteredText = currentText.filter { $0.isNumber }

        // 숫자가 하나도 없으면 전체 텍스트 지우기
        if filteredText.isEmpty {
            textField.text = nil
            return
        }

        // 포맷팅
        let formatted = FormatManager.shared.strToPrice(numStr: filteredText) ?? ""

        // 업데이트 (항상 "원" 붙임)
        textField.text = "\(formatted)원"

        // "원" 직전 위치로 커서 이동
        DispatchQueue.main.async {
            if let endPosition = textField.position(from: textField.beginningOfDocument, offset: formatted.count) {
                textField.selectedTextRange = textField.textRange(from: endPosition, to: endPosition)
            }
        }
    }
    
    public func updateImages(_ images: [UIImage]) {
        selectedImages = images
        collectionView.reloadData()
    }
    
    @objc func priceTextBegin(_ textField: UITextField) {
        self.delegate?.setActiveField(textField)
    }
}

extension AddView: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        selectedImages.count + 1
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if indexPath.item == 0 {
            // 카메라 버튼 셀
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NewCameraCell.identifier, for: indexPath) as! NewCameraCell
            cell.configure(self.selectedImages.count)
            return cell
        } else {
            // 기존 폴더 셀
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SelectedImageCell.identifier, for: indexPath) as! SelectedImageCell
            let image = selectedImages[indexPath.item - 1]
            cell.configure(with: image)
            
            cell.onDelete = { [weak self] in
                guard let self = self else { return }
                self.selectedImages.remove(at: indexPath.item - 1)
                self.viewModel.selectedImages = self.selectedImages
            }
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.item == 0 {
            self.selectNewImageAction?()
            return
        }
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 100, height: 100)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
                        minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 8
    }
}
