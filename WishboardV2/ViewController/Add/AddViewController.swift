//
//  AddViewController.swift
//  WishboardV2
//
//  Created by gomin on 2/22/25.
//

import Foundation
import UIKit
import Combine
import Lottie
import Then
import PhotosUI
import Moya
import Core
import WBNetwork

enum AddItemType {
    case manual
    case modify
}

public protocol ActiveFieldDelegate: AnyObject {
    func setActiveField(_ field: UIView)
}

final class AddViewController: UIViewController {
    
    // MARK: - Properties
    
    private let addView: AddView
    private let viewModel = AddViewModel()
    private var cancellables = Set<AnyCancellable>()
    public var confirmAction: (() -> Void)?
    
    // Album
    private let MAX_IMAGE_COUNT: Int = 10
    
    // Bottom Sheets
    private let backgroundDimView = UIView()
    private let folderSelectBottomSheet = FolderSelectBottomSheet()
    private let addFolderBottomSheet = FolderBottomSheet()
    private let shoppingLinkBottomSheet = ShoppingLinkBottomSheet()
    private let selectDateBottomSheet = SelectDateBottomSheet()
    
    // 모드
    private let type: AddItemType
    private var item: WishListResponse?
    
    // Keyboard
    private weak var activeField: UIView?
    
    // MARK: - Initializers
    
    init(type: AddItemType, item: WishListResponse? = nil) {
        self.addView = AddView(viewModel: self.viewModel)
        self.type = type
        self.item = item
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// 수정 모드라면 뷰모델에 데이터 삽입
    private func setModifyItemData() {
        self.addView.toolBar.configure(title: Title.modifyItem)
        
        self.addView.itemNameSection.text = self.item?.itemName ?? ""
        let formattedText = FormatManager.shared.strToPrice(numStr: self.item?.itemPrice ?? "0")
        self.addView.itemPriceSection.text = "\(formattedText ?? "")원"
        
        if let itemName = self.item?.itemName, !itemName.isEmpty {
            self.viewModel.itemName = itemName
        }
        if let itemPrice = self.item?.itemPrice, !itemPrice.isEmpty {
            self.viewModel.itemPrice = itemPrice
        }
        self.viewModel.selectedFolderId = self.item?.folderId
        if let itemUrl = self.item?.itemUrl, !itemUrl.isEmpty {
            self.viewModel.selectedLink = itemUrl
        }
        if let itemMemo = self.item?.itemMemo, !itemMemo.isEmpty {
            self.viewModel.memo = itemMemo
        }
        self.viewModel.selectedAlarmType =  Alarm.from(apiString: self.item?.itemNotificationType ?? "")?.rawValue
        self.viewModel.selectedAlarmDate = self.item?.itemNotificationDate?.replacingOccurrences(of: "T", with: " ")
        if let selectedAlarmType = viewModel.selectedAlarmType, let selectedAlarmDate = viewModel.selectedAlarmDate {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "ko_KR")
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

            if let date = formatter.date(from: selectedAlarmDate) {
                let calendar = Calendar.current
                let hour = calendar.component(.hour, from: date)
                let minute = calendar.component(.minute, from: date)
                
                let formattedDate = viewModel.formatToShortDate(selectedAlarmDate)
                let time = FormatManager.shared.convertTimeToKoreanFormat(hour: String(hour), minute: String(minute))
                self.viewModel.selectedAlarmDate = "\(formattedDate) \(time)"
                self.viewModel.selectedAlarm = "\(self.viewModel.selectedAlarmDate ?? "") \(selectedAlarmType)"
            }
        }
        
        // 서버에서 받은 이미지 배열 전환
        if let itemImages = self.item?.itemImages {
            for image in itemImages {
                if let imageUrl = image.itemImageUrl {
                    fetchImage(from: imageUrl) { image in
                        if let image = image {
                            DispatchQueue.main.async {
                                self.viewModel.selectedImages.append(image)
                            }
                        } else {
                            print("❌ 이미지 변환 실패")
                            DispatchQueue.main.async {
                                SnackBar.shared.show(type: .errorMessage)
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Life Cycles
    
    override func viewDidLoad() {
        self.view.backgroundColor = .white
        
        self.view.addSubview(addView)
        addView.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview()
            make.top.equalTo(self.view.safeAreaLayoutGuide)
            make.bottom.equalToSuperview()
        }
        
        setupBindings()
        setupActions()
        setupDelegates()
        setupKeyboardObservers()
        
        setupBackgroundDimView()
        setupBottomSheet()
        
        // data - fetch FolderList
        _Concurrency.Task {
            try await self.viewModel.fetchFolders()
            if type == .modify {
                setModifyItemData()
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        self.view.endEditing(true)
    }
    
    // MARK: - Bindings
    private func setupBindings() {
        addView.itemNameSection.`textPublisher`
            .receive(on: RunLoop.main)
            .assign(to: \.itemName, on: viewModel)
            .store(in: &cancellables)

        addView.itemPriceSection.textPublisher
            .receive(on: RunLoop.main)
            .assign(to: \.itemPrice, on: viewModel)
            .store(in: &cancellables)
        
        addView.memoSection.textPublisher
            .map { Optional($0) }
            .removeDuplicates()
            .debounce(for: .milliseconds(100), scheduler: RunLoop.main)
            .assign(to: \.memo, on: viewModel)
            .store(in: &cancellables)
        
        viewModel.$folders
            .receive(on: RunLoop.main)
            .sink { [weak self] folders in
                guard let self = self else { return }
                self.addView.folderSection.folders = folders
                guard let selectedFolderId = self.viewModel.selectedFolderId else { return }
                self.addView.folderSection.selectFolder(with: selectedFolderId)
                self.folderSelectBottomSheet.selectedFolderId = selectedFolderId
            }
            .store(in: &cancellables)
        
        viewModel.$selectedFolderId
            .receive(on: RunLoop.main)
            .sink { [weak self] folderId in
                guard let folderId = folderId else { return }
                self?.addView.folderSection.selectFolder(with: folderId)
                self?.folderSelectBottomSheet.selectedFolderId = folderId
            }
            .store(in: &cancellables)
        
        viewModel.$selectedAlarm
            .receive(on: RunLoop.main)
            .sink { [weak self] text in
                if let text = text {
                    self?.addView.alarmSection.text = text
                }
            }
            .store(in: &cancellables)
        
        viewModel.$selectedLink
            .receive(on: RunLoop.main)
            .sink { [weak self] text in
                if let text = text {
                    self?.addView.itemLinkSection.text = text
                }
            }
            .store(in: &cancellables)
        
        viewModel.$memo
            .dropFirst()
            .removeDuplicates()
            .sink { [weak self] text in
                guard self?.addView.memoSection.textView?.isFirstResponder == false else { return }
                guard let text = text else { return }
                self?.addView.memoSection.text = text
            }
            .store(in: &cancellables)
        
        viewModel.isSaveEnabled
            .receive(on: RunLoop.main)
            .sink { [weak self] isEnabled in
                self?.addView.toolBar.updateButtonState(enabled: isEnabled) // 저장 버튼 활성화
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Actions
    private func setupActions() {
        addView.folderSection.onNewFolderTap = {
            self.view.endEditing(true)
            self.showAddFolderBottomSheet()
        }
        
        addView.folderSection.onFolderSelected = { [weak self] folderId in
            self?.view.endEditing(true)
            self?.viewModel.selectedFolderId = folderId
        }

        addView.folderSection.onArrowTap = { [weak self] in
            self?.view.endEditing(true)
            guard let folders = self?.viewModel.folders else {return}
            self?.showSelectFolderBottomSheet(for: folders)
        }
        
        addView.alarmSection.onTap = { [weak self] in
            self?.view.endEditing(true)
            self?.showDateBottomSheet()
        }
        
        addView.itemLinkSection.onTap = { [weak self] in
            self?.view.endEditing(true)
            self?.showLinkBottomSheet(with: self?.viewModel.selectedLink)
        }
        
        addView.selectNewImageAction = { [weak self] in
            self?.selectImage()
        }
    }
    
    private func setupDelegates() {
        addView.delegate = self
        addView.toolBar.delegate = self
    }
    
    // MARK: Alert Helper
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
    
    // MARK: Bottom Sheets
    /// 뒷배경뷰 설정
    private func setupBackgroundDimView() {
        backgroundDimView.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        backgroundDimView.alpha = 0.0 // 초기에는 투명하게 설정
        view.addSubview(backgroundDimView)
        
        backgroundDimView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissModal))
        backgroundDimView.addGestureRecognizer(tapGesture)
    }
    
    @objc private func dismissModal() {
        self.hideSelectFolderBottomSheet()
        self.hideAddFolerBottomSheet()
        self.hideDateBottomSheet()
        self.hideLinkBottomSheet()
    }
    
    /// 시트 설정
    private func setupBottomSheet() {
        view.addSubview(folderSelectBottomSheet)
        view.addSubview(addFolderBottomSheet)
        view.addSubview(shoppingLinkBottomSheet)
        view.addSubview(selectDateBottomSheet)
        
        folderSelectBottomSheet.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview().offset(view.frame.height * 0.4)
        }
        addFolderBottomSheet.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview().offset(view.frame.height * 0.4)
        }
        shoppingLinkBottomSheet.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview().offset(view.frame.height * 0.4)
        }
        selectDateBottomSheet.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview().offset(340)
        }
        // Folder Binding
        folderSelectBottomSheet.selectAction = { [weak self] folderId, _ in
            self?.hideSelectFolderBottomSheet()
            self?.viewModel.selectedFolderId = folderId
        }
        folderSelectBottomSheet.onClose = { [weak self] in
            self?.hideSelectFolderBottomSheet()
        }
        // Add Folder
        addFolderBottomSheet.onClose = { [weak self] in
            self?.view.endEditing(true)
            self?.hideAddFolerBottomSheet()
        }
        addFolderBottomSheet.onActionButtonTap = { [weak self] folderName, folderId in
            // 새 폴더 추가
            _Concurrency.Task {
                do {
                    self?.addFolderBottomSheet.actionButton.startAnimation()
                    try await self?.viewModel.addFolder(name: folderName)
                    self?.view.endEditing(true)
                    self?.addFolderBottomSheet.actionButton.stopAnimation()
                    self?.hideAddFolerBottomSheet()
                } catch {
                    if let moyaError = error as? MoyaError, let response = moyaError.response {
                        if response.statusCode == 409 {
                            self?.addFolderBottomSheet.actionButton.stopAnimation()
                            self?.addFolderBottomSheet.displayErrorMessage("동일 이름의 폴더가 있어요!")
                        }
                    }
                    throw error
                }
            }
        }
        
        // Shopping Link Binding
        shoppingLinkBottomSheet.onClose = { [weak self] in
            self?.hideLinkBottomSheet()
        }
        shoppingLinkBottomSheet.onActionButtonTap = { [weak self] link in
            self?.hideLinkBottomSheet()
            self?.viewModel.selectedLink = link
        }
        // Select Date Binding
        selectDateBottomSheet.onClose = { [weak self] in
            self?.hideDateBottomSheet()
        }
        selectDateBottomSheet.onActionButtonTap = { [weak self] data in
            
            let (type, date, hour, minute) = data
            
            self?.hideDateBottomSheet()
            guard let type = data.0, let date = data.1, let hour = data.2, let minute = data.3 else {return}
            self?.viewModel.selectedAlarmType = type
            let time = FormatManager.shared.convertTimeToKoreanFormat(hour: hour, minute: minute)
            self?.viewModel.selectedAlarmDate = "\(date) \(time)"
            self?.viewModel.selectedAlarm = "\(self?.viewModel.selectedAlarmDate ?? "") \(type)"
        }
        selectDateBottomSheet.selectErrorAction = { [weak self] in
            #if WISHBOARD_APP
            SnackBar.shared.show(type: .selectPastTime)
            #else
            SnackBar(in: self).show(type: .selectPastTime)
            #endif
        }
    }
    
    /// 폴더 선택 시트 노출
    private func showSelectFolderBottomSheet(for folders: [FolderListResponse]) {
        DispatchQueue.main.async {
            self.view.endEditing(true)
            self.folderSelectBottomSheet.configure(with: folders)
            
            UIView.animate(withDuration: 0.3) {
                self.backgroundDimView.alpha = 1.0
                self.folderSelectBottomSheet.snp.updateConstraints { make in
                    make.bottom.equalToSuperview()
                }
                self.view.layoutIfNeeded()
            }
        }
    }
    
    /// 폴더 선택 시트 미노출
    private func hideSelectFolderBottomSheet() {
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.3) {
                self.backgroundDimView.alpha = 0.0
                self.folderSelectBottomSheet.snp.updateConstraints { make in
                    make.bottom.equalToSuperview().offset(self.view.frame.height * 0.4)
                }
                self.view.layoutIfNeeded()
            }
        }
    }
    /// 새 폴더 추가 시트 노출
    private func showAddFolderBottomSheet(for folder: FolderListResponse? = nil) {
        DispatchQueue.main.async {
            self.tabBarController?.tabBar.isHidden = true
            self.addFolderBottomSheet.initView()
            
            self.addFolderBottomSheet.configure(with: folder)
            UIView.animate(withDuration: 0.3) {
                self.backgroundDimView.alpha = 1.0
                self.addFolderBottomSheet.snp.updateConstraints { make in
                    make.bottom.equalToSuperview()
                }
                self.view.layoutIfNeeded()
            }
        }
    }
    
    /// 새 폴더 추가 시트 숨김
    private func hideAddFolerBottomSheet() {
        DispatchQueue.main.async {
            self.addFolderBottomSheet.resetView()
            
            UIView.animate(withDuration: 0.3) {
                self.backgroundDimView.alpha = 0.0
                self.addFolderBottomSheet.snp.updateConstraints { make in
                    make.bottom.equalToSuperview().offset(self.view.frame.height * 0.4)
                }
                self.view.layoutIfNeeded()
            }
        }
    }
    
    /// 쇼핑몰 링크 입력 시트 노출
    private func showLinkBottomSheet(with prevLink: String? = nil) {
        DispatchQueue.main.async {
            self.shoppingLinkBottomSheet.configure(with: prevLink)
            
            UIView.animate(withDuration: 0.3) {
                self.backgroundDimView.alpha = 1.0
                self.shoppingLinkBottomSheet.snp.updateConstraints { make in
                    make.bottom.equalToSuperview()
                }
                self.view.layoutIfNeeded()
            }
        }
    }
    
    /// 쇼핑몰 링크 입력 시트 미노출
    private func hideLinkBottomSheet() {
        DispatchQueue.main.async {
            self.shoppingLinkBottomSheet.removeObservers()
            UIView.animate(withDuration: 0.3) {
                self.backgroundDimView.alpha = 0.0
                self.shoppingLinkBottomSheet.snp.updateConstraints { make in
                    make.bottom.equalToSuperview().offset(self.view.frame.height * 0.4)
                }
                self.view.layoutIfNeeded()
            }
        }
    }
    
    /// 날짜 선택 시트 노출
    private func showDateBottomSheet() {
        DispatchQueue.main.async {
            self.view.endEditing(true)
            self.selectDateBottomSheet.configure()
            
            UIView.animate(withDuration: 0.3) {
                self.backgroundDimView.alpha = 1.0
                self.selectDateBottomSheet.snp.updateConstraints { make in
                    make.bottom.equalToSuperview()
                }
                self.view.layoutIfNeeded()
            }
        }
    }
    
    /// 날짜 선택 시트 미노출
    private func hideDateBottomSheet() {
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.3) {
                self.backgroundDimView.alpha = 0.0
                self.selectDateBottomSheet.snp.updateConstraints { make in
                    make.bottom.equalToSuperview().offset(340)
                }
                self.view.layoutIfNeeded()
            }
        }
    }
}

// MARK: - ImagePicker 관련 Methods & Delegates
extension AddViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate, PHPickerViewControllerDelegate {
    /// Image Picker
    @objc private func selectImage() {
        self.view.endEditing(true)
        
        if self.viewModel.selectedImages.count >= 10 {
            SnackBar.shared.show(type: .imageLimit)
            return
        }
        
        let actionSheet = UIAlertController(title: "사진 선택", message: nil, preferredStyle: .actionSheet)
        
        let action = UIAlertAction(title: "사진 찍기", style: .default) { _ in
            self.openCamera()
        }
        action.setValue(UIColor.gray_700, forKey: "titleTextColor")
        
        let album = UIAlertAction(title: "사진 보관함", style: .default) { _ in
            self.openPhotoLibrary()
        }
        album.setValue(UIColor.gray_700, forKey: "titleTextColor")

        let cancel = UIAlertAction(title: "취소", style: .cancel)
        cancel.setValue(UIColor.gray_700, forKey: "titleTextColor")

        actionSheet.addAction(action)
        actionSheet.addAction(album)
        actionSheet.addAction(cancel)
        
        present(actionSheet, animated: true)
    }
    
    private func openCamera() {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let picker = UIImagePickerController()
            picker.delegate = self
            picker.sourceType = .camera
            present(picker, animated: true)
        } else {
            showAlert(title: "카메라 사용 불가", message: "이 기기에서는 카메라를 사용할 수 없습니다.")
        }
    }
    
    private func openPhotoLibrary() {
        // 이미지의 Identifier를 사용하기 위해서는 초기화를 shared로
        var config = PHPickerConfiguration(photoLibrary: .shared())
        // 라이브러리에서 보여줄 Assets을 필터 (기본값: 이미지, 비디오, 라이브포토)
        config.filter = PHPickerFilter.any(of: [.images])
        // 다중 선택 갯수 설정 (이미 선택된 사진 갯수 기반으로 최대 10장 로직 정의)
        let selectedImageCount = self.viewModel.selectedImages.count
        config.selectionLimit = MAX_IMAGE_COUNT - selectedImageCount
        // 선택 동작을 나타냄 (default: 기본 틱 모양, ordered: 선택한 순서대로 숫자로 표현, people: 뭔지 모르겠게요)
        config.selection = .ordered
        // 트랜스 코딩을 방지
        config.preferredAssetRepresentationMode = .current

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }
    
    /// UIImagePickerControllerDelegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let editedImage = info[.editedImage] as? UIImage {
            viewModel.selectedImages.append(editedImage)
        } else if let originalImage = info[.originalImage] as? UIImage {
            viewModel.selectedImages.append(originalImage)
        }
        picker.dismiss(animated: true)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        dismiss(animated: true)

        // ✅ 10장 초과 체크
        if results.count > 10 {
            SnackBar.shared.show(type: .imageLimit)
            return
        }

        // ✅ 단순 로딩 (id/기억 로직 없이)
        var images: [UIImage?] = Array(repeating: nil, count: results.count)
        let group = DispatchGroup()

        for (index, result) in results.enumerated() {
            group.enter()
            result.itemProvider.loadObject(ofClass: UIImage.self) { object, _ in
                defer { group.leave() }
                if let image = object as? UIImage {
                    images[index] = image
                }
            }
        }

        group.notify(queue: .main) {
            let finalImages = images.compactMap { $0 }
            if self.viewModel.selectedImages.count + finalImages.count > 10 {
                SnackBar.shared.show(type: .imageLimit)
                return
            }
            self.viewModel.selectedImages.append(contentsOf: finalImages)
        }
    }
}

// MARK: - 상단바 Delegate
extension AddViewController: AddToolBarDelegate {
    func leftItemTap() {
        UIDevice.vibrate()
        self.dismiss(animated: true)
    }
    
    func rightItemTap() {
        UIDevice.vibrate()
        let lottie = SpinningLottie()
        _Concurrency.Task {
            do {
                self.view.endEditing(true)
                lottie.startAnimation()
                
                if self.type == .manual {
                    try await self.viewModel.addItem()
                } else if self.type == .modify {
                    guard let itemIdx = self.item?.id else {return}
                    try await self.viewModel.modifyItem(idx: itemIdx)
                }
                
                lottie.stopAnimation()
                
                self.dismiss(animated: true) {
                    // 스낵바 노출
                    if self.type == .manual {
                        SnackBar.shared.show(type: .addItem)
                    } else if self.type == .modify {
                        SnackBar.shared.show(type: .modifyItem)
                    }
                }
                self.confirmAction?()
                
            } catch {
                lottie.stopAnimation()
                
                SnackBar.shared.show(type: .errorMessage)
                
                throw error
            }
        }
    }
}

// MARK: - 활성화 필드 Delegate
extension AddViewController: ActiveFieldDelegate {
    func setActiveField(_ field: UIView) {
        self.activeField = field
    }
}

// MARK: - Keyboard 관련 Methodds & Delegates
extension AddViewController {
    
    /// 키보드 옵저버 추가
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow(_:)),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide(_:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
    
    /// 키보드 나타날 때 호출
    @objc private func keyboardWillShow(_ notification: Foundation.Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        
        let keyboardHeight = keyboardFrame.height
        let bottomInset = keyboardHeight - view.safeAreaInsets.bottom
        
        UIView.animate(withDuration: 0.3) {
            self.addView.scrollView.contentInset.bottom = bottomInset
            self.addView.scrollView.verticalScrollIndicatorInsets.bottom = bottomInset
        }
        
        // 현재 포커싱된 뷰를 스크롤
        if let field = activeField {
            self.scrollToActiveField(field, keyboardHeight: keyboardHeight)
        }
    }
    
    /// 키보드 사라질 때 호출
    @objc private func keyboardWillHide(_ notification: Foundation.Notification) {
        UIView.animate(withDuration: 0.3) {
            self.addView.scrollView.contentInset.bottom = 0
            self.addView.scrollView.verticalScrollIndicatorInsets.bottom = 0
        }
    }
    
    /// 현재 포커싱된 필드를 키보드 높이에 맞게 조정
    private func scrollToActiveField(_ activeField: UIView, keyboardHeight: CGFloat) {
        // scrollView 기준으로 frame 변환
        let scrollView = self.addView.scrollView
        let fieldFrameInScrollView = activeField.convert(activeField.bounds, to: scrollView)
        
        // 현재 스크롤 offset + visible height (keyboard 고려)
        let visibleHeight = scrollView.bounds.height - keyboardHeight
        let visibleRect = CGRect(x: 0, y: scrollView.contentOffset.y, width: scrollView.bounds.width, height: visibleHeight)
        
        if !visibleRect.contains(fieldFrameInScrollView) {
            // 아래로 스크롤해야 함
            scrollView.scrollRectToVisible(fieldFrameInScrollView.insetBy(dx: 0, dy: -20), animated: true)
        }
    }
}

extension AddViewController {
    func fetchImage(from urlString: String, completion: @escaping (UIImage?) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("❌ 이미지 다운로드 실패: \(error.localizedDescription)")
                completion(nil)
                return
            }

            guard let data = data, let image = UIImage(data: data) else {
                print("❌ 유효하지 않은 이미지 데이터")
                completion(nil)
                return
            }

            DispatchQueue.main.async {
                completion(image)
            }
        }.resume()
    }
}
