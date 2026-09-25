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

final class AddView: UIView, LoadingPresentable {
    
    // MARK: - UI Components
    
    let toolBar = AddToolBar()
    /// 로딩뷰가 덮을 영역. 상단바는 가리지 않습니다.
    let loadingContainerView = UIView().then {
        $0.isUserInteractionEnabled = false
    }
    
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
        layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)

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
    /// '대표 사진'이 붙는 셀 위치. 0번은 카메라 셀이라 이미지 배열의 첫 번째는 1번입니다.
    private static let thumbnailItem: Int = 1

    public var selectedImages: [UIImage] = []
    public var selectNewImageAction: (() -> Void)?
    public weak var delegate: ActiveFieldDelegate?
    private let viewModel: AddViewModel
    private var cancellables = Set<AnyCancellable>()
    /// 이미지 순서 변경으로 발생한 갱신인지 여부. 불필요한 reload를 막기 위해 사용합니다.
    private var isReordering = false
    /// 롱프레스로 시작한 인터랙티브 이동이 진행 중인지 여부
    private var isInteractiveMoving = false
    
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

        addSubview(loadingContainerView)
        loadingContainerView.snp.makeConstraints { make in
            make.top.equalTo(toolBar.snp.bottom)
            make.horizontalEdges.bottom.equalToSuperview()
        }
        
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
        }
        
        collectionView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(18)
            make.leading.equalToSuperview()
            make.height.equalTo(100)
            make.trailing.equalToSuperview()
        }

        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPress.minimumPressDuration = 0.4
        collectionView.addGestureRecognizer(longPress)
        
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
        
        // Int로 변환해서 최대값 체크
        if let number = Int(filteredText), number > 999_999_999 {
            // 최대값 초과 → 입력 무효화 (기존 텍스트 유지)
            // 즉, 직전 상태 그대로 두기 위해 return
            return
        }

        // 포맷팅
        let formatted = FormatManager.shared.strToPrice(numStr: filteredText) ?? ""

        // 업데이트
        textField.text = "₩ \(formatted)"
    }
    
    public func updateImages(_ images: [UIImage]) {
        selectedImages = images

        // 순서 변경은 인터랙티브 이동으로 셀 위치가 이미 반영되어 있으므로 reload를 건너뜁니다.
        if isReordering {
            isReordering = false
            // 셀을 다시 구성하지 않으므로, 대표 사진 표시만 현재 순서에 맞춰 줍니다.
            updateThumbnailBadges()
            return
        }
        collectionView.reloadData()
    }

    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        let location = gesture.location(in: collectionView)

        switch gesture.state {
        case .began:
            // 0번은 카메라 셀이므로 이동 대상에서 제외합니다.
            guard let indexPath = collectionView.indexPathForItem(at: location),
                  indexPath.item > 0,
                  collectionView.beginInteractiveMovementForItem(at: indexPath) else { return }

            isInteractiveMoving = true
            // 이동 중에는 바깥 스크롤뷰가 제스처를 가져가지 않도록 잠급니다.
            scrollView.isScrollEnabled = false
            UIDevice.vibrate()

        case .changed:
            guard isInteractiveMoving else { return }
            collectionView.updateInteractiveMovementTargetPosition(location)

        case .ended:
            guard isInteractiveMoving else { return }
            collectionView.endInteractiveMovement()
            finishInteractiveMove()

        default:
            guard isInteractiveMoving else { return }
            collectionView.cancelInteractiveMovement()
            finishInteractiveMove()
        }
    }

    private func finishInteractiveMove() {
        isInteractiveMoving = false
        scrollView.isScrollEnabled = true
        // 이동이 취소된 경우에도 원래 순서 기준으로 다시 맞춰 줍니다.
        updateThumbnailBadges()
    }

    /// 화면에 떠 있는 이미지 셀들의 '대표 사진' 표시를 현재 순서에 맞춰 갱신합니다.
    private func updateThumbnailBadges() {
        for cell in collectionView.visibleCells {
            guard let imageCell = cell as? SelectedImageCell,
                  let indexPath = collectionView.indexPath(for: cell) else { continue }
            imageCell.setThumbnail(indexPath.item == AddView.thumbnailItem)
        }
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
            // 0번은 카메라 셀이므로, 이미지 배열의 첫 번째는 1번 셀입니다.
            cell.configure(with: image, isThumbnail: indexPath.item == AddView.thumbnailItem)
            
            // 순서 변경 이후에도 올바른 이미지를 지우도록, 캡처한 indexPath 대신 현재 위치를 조회합니다.
            cell.onDelete = { [weak self, weak cell] in
                guard let self = self,
                      let cell = cell,
                      let currentIndexPath = self.collectionView.indexPath(for: cell) else { return }

                let imageIndex = currentIndexPath.item - 1
                guard self.selectedImages.indices.contains(imageIndex) else { return }

                self.selectedImages.remove(at: imageIndex)
                self.viewModel.selectedImages = self.selectedImages
                self.viewModel.imageChanged = true
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
                        willDisplay cell: UICollectionViewCell,
                        forItemAt indexPath: IndexPath) {
        // 미리 만들어 둔 셀은 순서가 바뀌어도 다시 구성되지 않으므로, 나타나기 직전에 맞춰 줍니다.
        guard let imageCell = cell as? SelectedImageCell else { return }
        imageCell.setThumbnail(indexPath.item == AddView.thumbnailItem)
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

    func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
        return indexPath.item > 0
    }

    func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let fromIndex = sourceIndexPath.item - 1
        let toIndex = destinationIndexPath.item - 1

        guard selectedImages.indices.contains(fromIndex),
              selectedImages.indices.contains(toIndex) else { return }

        let movedImage = selectedImages.remove(at: fromIndex)
        selectedImages.insert(movedImage, at: toIndex)

        isReordering = true
        viewModel.selectedImages = selectedImages
        viewModel.imageChanged = true

        // 순서가 바뀌어도 '대표 사진'은 항상 첫 번째 이미지에 있어야 합니다.
        updateThumbnailBadges()
    }

    func collectionView(_ collectionView: UICollectionView, targetIndexPathForMoveFromItemAt originalIndexPath: IndexPath, toProposedIndexPath proposedIndexPath: IndexPath) -> IndexPath {
        return proposedIndexPath.item == 0 ? IndexPath(item: 1, section: 0) : proposedIndexPath
    }
}
