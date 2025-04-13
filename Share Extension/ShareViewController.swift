//
//  ShareViewController.swift
//  Share Extension
//
//  Created by gomin on 8/25/24.
//

import UIKit
import Combine
import Core
import WBNetwork

class ShareViewController: UIViewController {
    
    private let shareView = ShareView()
    private let viewModel = ShareViewModel()
    
    private let folderSheetView = FolderBottomSheet()
    private let alarmSheetView = SelectDateBottomSheet()
    private let backgroundDimView = UIView()
    
    private var link: String?
    private var cancellables = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpShareView()
        setupBackgroundDimView()
        setupBottomSheet()
        setUpObservers()
        setupBindings()
        
        // fetch datas
        viewModel.fetchFolders()
        viewModel.getSharedUrl(self) { [weak self] url in
            Task {
                do {
                    // 아이템 정보 파싱
                    if !(url.isEmpty) {
                        self?.link = url
                    }
                    try await self?.viewModel.fetchItem(link: url)
                } catch {
                    // 파싱 실패 시 스낵바 노출
                    // 미로그인 상태에서는 스낵바 미노출
                    if UserManager.accessToken == nil || UserManager.refreshToken == nil { return }
                    SnackBar(in: self).show(type: .failShoppingLink)
                    throw error
                }
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        self.dismissKeyboard()
    }
    
    private func setUpShareView() {
        self.view.addSubview(shareView)
        shareView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        shareView.configure(with: viewModel)
        
        shareView.setNotificationButton.addTarget(self, action: #selector(setNotiButtonTapped), for: .touchUpInside)
        shareView.addFolderButton.addTarget(self, action: #selector(addFolderButtonTapped), for: .touchUpInside)
        shareView.quitButton.addTarget(self, action: #selector(quitShareView), for: .touchUpInside)
        shareView.completeButton.addTarget(self, action: #selector(addItem), for: .touchUpInside)
    }
    
    private func setUpObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    private func setupBindings() {
        viewModel.$selectedAlarm
            .receive(on: RunLoop.main)
            .sink { [weak self] text in
                self?.shareView.configureNotiDateButton(text ?? Button.setNoti)
            }
            .store(in: &cancellables)
        
        viewModel.$isLogined
            .receive(on: RunLoop.main)
            .sink { [weak self] isLogined in
                self?.shareView.updateCompleteButtonState()
            }
            .store(in: &cancellables)
        
        shareView.clearNotiAction = { [weak self] in
            self?.viewModel.selectedAlarm = nil
        }
    }
    
    private func setupBackgroundDimView() {
        backgroundDimView.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        backgroundDimView.alpha = 0.0 // 초기에는 투명하게 설정
        view.addSubview(backgroundDimView)
        
        backgroundDimView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    private func setupBottomSheet() {
        view.addSubview(folderSheetView)
        view.addSubview(alarmSheetView)
        
        folderSheetView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview().offset(view.frame.height * 0.4)
        }
        
        folderSheetView.onClose = { [weak self] in
            self?.dismissKeyboard()
            self?.hideBottomSheet()
        }
        
        folderSheetView.onActionButtonTap = { [weak self] folderName, folder in
            self?.dismissKeyboard()
            // 새 폴더 추가 시에는 체크표시 (요구사항)
            self?.shareView.newFolderAdded = true
            // 새 폴더 추가
            self?.viewModel.addFolder(name: folderName)
            self?.hideBottomSheet()
            SnackBar(in: self).show(type: .addFolder)
        }
        
        alarmSheetView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview().offset(340)
        }
        alarmSheetView.onClose = { [weak self] in
            self?.hideDateBottomSheet()
        }
        // 상품알림설정 이후
        alarmSheetView.onActionButtonTap = { [weak self] data in
            self?.hideDateBottomSheet()
            guard let type = data.0, let date = data.1, let hour = data.2, let minute = data.3 else {return}
            self?.viewModel.selectedAlarmType = type
            self?.viewModel.selectedAlarmDate = "\(date) \(hour):\(minute)"
            
            // 1. date의 앞자리 0 제거 -> 0이 붙은 숫자는 한자리수로만 노출하는 요구사항
            let convertedDate = date
                .replacingOccurrences(of: "0([1-9])일", with: "$1일", options: .regularExpression)
                .replacingOccurrences(of: "0([1-9])월", with: "$1월", options: .regularExpression)
            // 2. hour/minute 처리 (앞자리 0 제거) -> 동일 요구사항
            let hourInt = Int(hour) ?? 0
            let minuteInt = Int(minute) ?? 0
            let hourStr = "\(hourInt)시"
            // 3. minute이 00이라면 노출하지 않는 요구사항 추가
            let minuteStr = minuteInt == 0 ? "" : " \(minuteInt)분"
            // 4. 완성된 date 문자열
            let dateText = "\(convertedDate) \(hourStr)\(minuteStr)"
            
            self?.viewModel.selectedAlarm = "[\(type)] \(dateText)"
        }
        
        alarmSheetView.selectErrorAction = { [weak self] in
            #if WISHBOARD_APP
            SnackBar.shared.show(type: .selectPastTime)
            #else
            SnackBar(in: self).show(type: .selectPastTime)
            #endif
        }
    }
    
    /// 폴더 관련 바텀시트 노출
    /// - Parameter folder: 폴더 정보 - nil이라면 '새 폴더 추가' / nil이 아니라면 '폴더명 수정'
    private func showBottomSheet(for folder: FolderListResponse? = nil) {
        DispatchQueue.main.async {
            self.dismissKeyboard()
            self.folderSheetView.initView()
            self.folderSheetView.configure(with: folder)
            
            UIView.animate(withDuration: 0.3) {
                self.backgroundDimView.alpha = 1.0
                self.folderSheetView.snp.updateConstraints { make in
                    make.bottom.equalToSuperview()
                }
                self.view.layoutIfNeeded()
            }
        }
    }
    
    private func hideBottomSheet() {
        DispatchQueue.main.async {
            self.dismissKeyboard()
            self.folderSheetView.resetView()
            
            UIView.animate(withDuration: 0.3) {
                self.backgroundDimView.alpha = 0.0
                self.folderSheetView.snp.updateConstraints { make in
                    make.bottom.equalToSuperview().offset(self.view.frame.height * 0.4)
                }
                self.view.layoutIfNeeded()
            }
        }
    }
    
    /// 날짜 선택 시트 노출
    private func showDateBottomSheet() {
        DispatchQueue.main.async {
            self.dismissKeyboard()
            self.alarmSheetView.configure()
            
            UIView.animate(withDuration: 0.3) {
                self.backgroundDimView.alpha = 1.0
                self.alarmSheetView.snp.updateConstraints { make in
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
                self.alarmSheetView.snp.updateConstraints { make in
                    make.bottom.equalToSuperview().offset(340)
                }
                self.view.layoutIfNeeded()
            }
        }
    }
    
    // MARK: - Actions
    
    /// 키보드 내림
    @objc private func dismissKeyboard() {
        self.view.endEditing(true)
    }
    
    /// 새 폴더 추가
    @objc private func addFolderButtonTapped() {
        // 로그인 상태가 아니라면 비활성화
        if UserManager.accessToken == nil || UserManager.refreshToken == nil {
            return
        }
        self.showBottomSheet()
    }
    
    /// 알림 설정 추가
    @objc private func setNotiButtonTapped() {
        self.showDateBottomSheet()
    }
    
    /// 링크 공유 종료
    @objc private func quitShareView() {
        self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }
    
    /// 아이템 추가
    @objc private func addItem() {
        self.dismissKeyboard()
        shareView.completeButton.startAnimation()
        
        let itemName = shareView.itemNameTextField.text
        let itemPrice = FormatManager.shared.priceToStr(price: shareView.itemPriceTextField.text ?? "")
        let selectedFolderId = shareView.selectedFolderId
        
        var itemImage: Data?
        if let _ = viewModel.item?.item_img {
            itemImage = shareView.itemImage.image?.resizeImageIfNeeded().jpegData(compressionQuality: 1.0)
        }
        
        let itemDTO = RequestItemDTO(folderId: selectedFolderId, 
                                     photo: itemImage,
                                     itemName: itemName,
                                     itemPrice: itemPrice,
                                     itemURL: self.link,
                                     itemMemo: nil,
                                     itemNotificationType: viewModel.selectedAlarmType,
                                     itemNotificationDate: convertDateFormat(input: viewModel.selectedAlarmDate ?? ""))
        
        Task {
            do {
                try await viewModel.addItem(item: itemDTO)
                shareView.completeButton.stopAnimation()
                shareView.isUserInteractionEnabled = false
                shareView.completeButton.isEnabled = false
                
                // complete snackbar
                SnackBar(in: self).show(type: .addItem)
                // quit
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                    self?.quitShareView()
                }
            } catch {
                shareView.completeButton.stopAnimation()
                shareView.isUserInteractionEnabled = true
                shareView.completeButton.isEnabled = false
                SnackBar(in: self).show(type: .errorMessage)
                throw error
            }
        }
        
    }
    
    /// 서버에 전송하기 위해 날짜 포맷팅
    private func convertDateFormat(input: String) -> String? {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yy년 MM월 dd일 HH:mm"
        inputFormatter.locale = Locale(identifier: "ko_KR") // 한글 형식 대응

        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        if let date = inputFormatter.date(from: input) {
            return outputFormatter.string(from: date)
        } else {
            return nil
        }
    }

}

// MARK: - Keyboard Event
extension ShareViewController {
    @objc private func keyboardWillShow(notification: NSNotification) {
        if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            let keyboardHeight = keyboardFrame.height
            UIView.animate(withDuration: 0.3) {
                self.shareView.snp.updateConstraints { make in
                    make.bottom.equalToSuperview().offset(-keyboardHeight)
                }
                self.view.layoutIfNeeded()
            }
        }
    }

    @objc private func keyboardWillHide(notification: NSNotification) {
        UIView.animate(withDuration: 0.3) {
            self.shareView.snp.updateConstraints { make in
                make.bottom.equalToSuperview()
            }
            self.view.layoutIfNeeded()
        }
    }
}
