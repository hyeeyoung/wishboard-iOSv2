//
//  SetNotiBottomSheet.swift
//  WishboardV2
//
//  Created by gomin on 2/23/25.
//

import Foundation
import UIKit
import SnapKit
import Then
import Combine

import Core
import WBNetwork

final class SelectDateBottomSheet: UIView {
    
    // MARK: - UI Components
    private let titleLabel = UILabel().then {
        $0.text = "Title"
        $0.font = TypoStyle.SuitH3.font
        $0.textAlignment = .center
    }
    private let closeButton = UIButton(type: .system).then {
        $0.setImage(Image.quit, for: .normal)
        $0.tintColor = .gray_700
    }
    private let pickerView = UIPickerView().then{
        $0.tintColor = .gray_700
    }
    private let message = UILabel().then{
        $0.text = Message.itemNotification
        $0.setTypoStyleWithSingleLine(typoStyle: .SuitD3)
        $0.textColor = .gray_300
    }
    private let actionButton = AnimatedButton().then {
        $0.setTitle("완료", for: .normal)
        $0.backgroundColor = .gray_100
        $0.setTitleColor(.gray_300, for: .normal)
        $0.titleLabel?.font = TypoStyle.SuitH3.font
        $0.layer.cornerRadius = 12
        $0.clipsToBounds = true
    }
    
    // MARK: - Properties
    private var cancellables = Set<AnyCancellable>()
    public var selectedData: (String?, String?, String?, String?) = ("재입고", "\(SetNotificationDate.currentYear)년 \(SetNotificationDate.currentMonth)월 \(SetNotificationDate.currentDay)일", "00", "00")
    
    var onClose: (() -> Void)?
    var onActionButtonTap: (((String?, String?, String?, String?)) -> Void)?
    
    // MARK: - Initializer
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        setupConstraints()
        
        self.pickerView.delegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup View
    private func setupView() {
        backgroundColor = .white
        layer.cornerRadius = 20
        layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        
        addSubview(titleLabel)
        addSubview(closeButton)
        addSubview(pickerView)
        addSubview(message)
        addSubview(actionButton)
        
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        actionButton.addTarget(self, action: #selector(actionButtonTapped), for: .touchUpInside)
    }
    
    private func setupConstraints() {
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.centerX.equalToSuperview()
        }
        
        closeButton.snp.makeConstraints { make in
            make.width.height.equalTo(24)
            make.centerY.equalTo(titleLabel)
            make.trailing.equalToSuperview().offset(-16)
        }
        
        actionButton.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-34)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(50)
        }
        
        pickerView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.top.equalTo(titleLabel.snp.bottom).offset(45)
            make.height.equalTo(34 * 3 + 20)
        }
        
        message.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(actionButton.snp.top).offset(-6)
        }
    }
    
    // MARK: - Actions
    
    @objc private func closeButtonTapped() {
        onClose?()
    }
    
    @objc private func actionButtonTapped() {
        onActionButtonTap?(selectedData)
    }
    
    private func updateActionButtonState(isEnabled: Bool) {
        actionButton.isEnabled = isEnabled
    }
    
    // MARK: - Public Methods
    
    func initView() {
        self.isHidden = false
    }
    
    func resetView() {
        pickerView.selectRow(0, inComponent: 0, animated: false) // 알림 유형 초기화
        pickerView.selectRow(0, inComponent: 1, animated: false) // 날짜 초기화
        pickerView.selectRow(0, inComponent: 2, animated: false) // 시 초기화
        pickerView.selectRow(0, inComponent: 4, animated: false) // 분 초기화

        self.updateActionButtonState(isEnabled: true)
    }
    
    func configure() {
        self.snp.makeConstraints { make in
            make.height.equalToSuperview().multipliedBy(0.4)
        }
        
        titleLabel.text = "상품 알림 설정"
        self.updateActionButtonState(isEnabled: true)
    }
}


// MARK: - Picker delegate
extension SelectDateBottomSheet: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        /*
         첫번째: 상품 알림 유형 (재입고, 오픈 등..)
         두번째: 날짜
         세번째: 시
         네번째: 땡땡 (:)
         다섯번째: 분
         */
        return 5
    }
    /// row 당 아이템 개수
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch component {
        case 0:
            return 6
        case 1:
            return 90
        case 2:
            return 24
        case 4:
            return 2
        default:
            return 1
        }
        
    }
    /// row 당 아이템 타이틀
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch component {
        case 0:
            return SetNotificationDate.notificationData[row]
        case 1:
            return SetNotificationDate.dateData[row]
        case 2:
            return SetNotificationDate.hourData[row]
        case 4:
            return SetNotificationDate.minuteData[row]
        default:
            return ":"
        }
        
    }
    /// font 적용
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        var label = UILabel()
        if let v = view as? UILabel { label = v }
        label.setTypoStyleWithSingleLine(typoStyle: .SuitD2)
        label.textAlignment = .center
        
        switch component {
        case 0:
            label.text = SetNotificationDate.notificationData[row]
        case 1:
            label.text = SetNotificationDate.dateData[row]
        case 2:
            label.text = SetNotificationDate.hourData[row]
        case 4:
            label.text = SetNotificationDate.minuteData[row]
        default:
            label.text = ":"
        }
        
        return label
    }
    /// 열 가로길이
    func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        switch component {
        case 0:
            return 80
        case 1:
            return 120
        case 2:
            return 30
        case 4:
            return 30
        default:
            return 5
        }
    }
    /// 행 세로길이
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 34
    }
    /// 행 선택 이벤트
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        switch component {
            // type
        case 0: self.selectedData.0 = SetNotificationDate.notificationData[row]
            // date
        case 1: self.selectedData.1 = SetNotificationDate.dateData[row]
            // hour
        case 2: self.selectedData.2 = SetNotificationDate.hourData[row]
            // minute
        case 4: self.selectedData.3 = SetNotificationDate.minuteData[row]
        default: break
        }
    }
}
