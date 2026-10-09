//
//  WithdrawFeedbackView.swift
//  WishboardV2
//
//  Created by gomin on 10/8/26.
//

import Foundation
import UIKit
import SnapKit
import Then
import Core

// MARK: - 탈퇴 사유

/// 탈퇴 사유 선택지. 순서가 곧 화면에 노출되는 순서입니다.
enum WithdrawReason: CaseIterable {
    case hardToUse
    case missingFeature
    case notSatisfied
    case privacyConcern
    case otherService
    case lowUsage
    case tooManyIssues
    case other

    var title: String {
        switch self {
        case .hardToUse:        return "앱 이용 방법이 어렵거나 불편해요"
        case .missingFeature:   return "원하는 기능이 없어요"
        case .notSatisfied:     return "서비스 이용이 생각보다 만족스럽지 않아요"
        case .privacyConcern:   return "개인정보 보호가 걱정돼요"
        case .otherService:     return "다른 유사 서비스를 이용하려고 해요"
        case .lowUsage:         return "사용 빈도가 낮아요"
        case .tooManyIssues:    return "오류나 불편한 점이 많아요"
        case .other:            return "기타"
        }
    }

    /// 직접 입력을 받아야 하는 선택지인지 여부
    var needsDetail: Bool {
        self == .other
    }
}

// MARK: - 탈퇴 사유 한 줄

/// 라디오 버튼과 문구로 이루어진 선택지 한 줄.
final class WithdrawReasonRow: UIControl {

    /// 체크 아이콘 크기
    private static let indicatorSize: CGFloat = 18
    /// 체크 아이콘과 문구 사이 간격
    private static let spacing: CGFloat = 6
    /// 줄 높이는 아이콘만큼 작아, 위아래로 조금 더 눌리도록 터치 영역만 넓혀 둡니다.
    /// (줄과 줄 사이 간격의 절반이라 이웃한 줄과 겹치지 않습니다)
    private static let touchAreaExpansion: CGFloat = 6

    let reason: WithdrawReason

    private let emptyCircleView = UIImageView().then {
        $0.image = Image.circle18
        $0.contentMode = .scaleAspectFit
        $0.isUserInteractionEnabled = false
    }

    private let checkImageView = UIImageView().then {
        $0.image = Image.checkGreenCircle18
        $0.contentMode = .scaleAspectFit
        $0.isHidden = true
        $0.isUserInteractionEnabled = false
    }

    private let titleLabel = UILabel().then {
        $0.font = TypoStyle.SuitB3.font
        $0.textColor = .black_10
        $0.numberOfLines = 0
        $0.isUserInteractionEnabled = false
    }

    override var isSelected: Bool {
        didSet {
            checkImageView.isHidden = !isSelected
            emptyCircleView.isHidden = isSelected
        }
    }

    init(reason: WithdrawReason) {
        self.reason = reason
        super.init(frame: .zero)

        titleLabel.text = reason.title

        addSubview(emptyCircleView)
        addSubview(checkImageView)
        addSubview(titleLabel)

        // 줄 높이는 아이콘과 문구 중 큰 쪽을 따릅니다. (문구가 길어 두 줄이 되는 경우 대비)
        emptyCircleView.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.centerY.equalToSuperview()
            make.width.height.equalTo(WithdrawReasonRow.indicatorSize)
            make.top.greaterThanOrEqualToSuperview()
            make.bottom.lessThanOrEqualToSuperview()
        }

        checkImageView.snp.makeConstraints { make in
            make.edges.equalTo(emptyCircleView)
        }

        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(emptyCircleView.snp.trailing).offset(WithdrawReasonRow.spacing)
            make.trailing.equalToSuperview()
            make.centerY.equalToSuperview()
            make.top.greaterThanOrEqualToSuperview()
            make.bottom.lessThanOrEqualToSuperview()
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        bounds.insetBy(dx: 0, dy: -WithdrawReasonRow.touchAreaExpansion).contains(point)
    }
}

// MARK: - 탈퇴 피드백 화면

final class WithdrawFeedbackView: UIView {

    /// 직접 입력란에 받을 수 있는 최대 글자 수
    static let detailTextLimit: Int = 200

    private static let horizontalInset: CGFloat = 16
    private static let actionButtonHeight: CGFloat = 50
    /// 키보드가 올라왔을 때 '탈퇴하기' 버튼과 키보드 사이 간격
    private static let actionButtonKeyboardSpacing: CGFloat = 16
    /// 선택지 줄과 줄 사이 간격
    private static let reasonRowSpacing: CGFloat = 12
    /// 직접 입력란의 안쪽 여백
    private static let detailVerticalPadding: CGFloat = 12
    private static let detailHorizontalPadding: CGFloat = 10
    /// 입력 글자와 글자 수 라벨 사이의 최소 간격
    private static let detailCountSpacing: CGFloat = 12
    private static let detailContainerHeight: CGFloat = 120

    // MARK: - Views

    let toolBar = ToolBar()

    private let scrollView = UIScrollView().then {
        $0.showsVerticalScrollIndicator = false
        $0.keyboardDismissMode = .onDrag
    }

    private let contentView = UIView()

    private let titleLabel = UILabel().then {
        $0.text = Title.withdrawFeedback
        $0.font = TypoStyle.SuitH0.font
        $0.textColor = .gray_700
        $0.numberOfLines = 0
    }

    private let subtitleLabel = UILabel().then {
        $0.text = Message.withdrawFeedback
        $0.font = TypoStyle.SuitD2.font
        $0.textColor = .gray_300
        $0.numberOfLines = 0
    }

    private let reasonStackView = UIStackView().then {
        $0.axis = .vertical
        $0.alignment = .fill
        $0.distribution = .fill
        $0.spacing = WithdrawFeedbackView.reasonRowSpacing
    }

    /// '기타'를 골랐을 때만 노출되는 직접 입력란
    private let detailContainerView = UIView().then {
        $0.backgroundColor = .gray_50
        $0.layer.cornerRadius = 6
        $0.clipsToBounds = true
        $0.isHidden = true
    }

    let detailTextView = UITextView().then {
        $0.font = TypoStyle.SuitD1.font
        $0.textColor = .gray_700
        $0.backgroundColor = .clear
        $0.textContainerInset = .zero
        $0.textContainer.lineFragmentPadding = 0
        $0.isScrollEnabled = true
    }

    private let detailPlaceholderLabel = UILabel().then {
        $0.text = Placeholder.withdrawReason
        $0.font = TypoStyle.SuitD1.font
        $0.textColor = .gray_300
        $0.numberOfLines = 0
        $0.isUserInteractionEnabled = false
    }

    private let detailCountLabel = UILabel().then {
        $0.font = TypoStyle.SuitD3.font
        $0.textColor = .gray_200
        $0.textAlignment = .right
    }

    private let actionButton = UIButton().then {
        $0.setTitle(Button.withdraw, for: .normal)
        $0.titleLabel?.font = TypoStyle.SuitH3.font
        $0.setTitleColor(.gray_300, for: .disabled)
        $0.setTitleColor(.gray_700, for: .normal)
        $0.layer.cornerRadius = 12
        $0.clipsToBounds = true
    }

    // MARK: - Properties

    private var reasonRows: [WithdrawReasonRow] = []
    private var actionButtonBottomConstraint: Constraint?

    /// 선택된 사유. 아직 고르지 않았다면 nil입니다.
    private(set) var selectedReason: WithdrawReason?

    /// 사유를 고르거나 직접 입력이 바뀔 때 호출됩니다.
    var onSelectionChanged: (() -> Void)?
    /// '탈퇴하기' 탭
    var onWithdrawTap: (() -> Void)?

    // MARK: - Initializer

    init() {
        super.init(frame: .zero)
        backgroundColor = .white

        setupViews()
        setupConstraints()
        setupActions()
        setupNotificationObservers()
        updateDetailCount()
        updateActionButtonState()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Setup

    private func setupViews() {
        addSubview(toolBar)
        addSubview(scrollView)
        addSubview(actionButton)

        scrollView.addSubview(contentView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)
        contentView.addSubview(reasonStackView)

        detailContainerView.addSubview(detailTextView)
        detailContainerView.addSubview(detailPlaceholderLabel)
        detailContainerView.addSubview(detailCountLabel)

        toolBar.configure(title: "")

        WithdrawReason.allCases.forEach { reason in
            let row = WithdrawReasonRow(reason: reason)
            row.addTarget(self, action: #selector(reasonRowTapped(_:)), for: .touchUpInside)
            reasonRows.append(row)
            reasonStackView.addArrangedSubview(row)
        }

        // 직접 입력란도 스택에 넣어, 숨겼을 때 자리까지 함께 접히도록 합니다.
        reasonStackView.addArrangedSubview(detailContainerView)

        detailTextView.delegate = self
    }

    private func setupConstraints() {
        // 스크롤뷰는 상단바 아래에서 '탈퇴하기' 버튼 위까지를 차지합니다.
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(toolBar.snp.bottom)
            make.horizontalEdges.equalToSuperview()
            make.bottom.equalTo(actionButton.snp.top).offset(-16)
        }

        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(scrollView.snp.width)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(24)
            make.horizontalEdges.equalToSuperview().inset(WithdrawFeedbackView.horizontalInset)
        }

        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(10)
            make.horizontalEdges.equalTo(titleLabel)
        }

        reasonStackView.snp.makeConstraints { make in
            make.top.equalTo(subtitleLabel.snp.bottom).offset(24)
            make.horizontalEdges.equalTo(titleLabel)
            make.bottom.equalToSuperview().offset(-24)
        }

        detailContainerView.snp.makeConstraints { make in
            make.height.equalTo(WithdrawFeedbackView.detailContainerHeight)
        }

        detailTextView.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(WithdrawFeedbackView.detailVerticalPadding)
            make.horizontalEdges.equalToSuperview().inset(WithdrawFeedbackView.detailHorizontalPadding)
            make.bottom.equalTo(detailCountLabel.snp.top)
                .offset(-WithdrawFeedbackView.detailCountSpacing)
        }

        detailPlaceholderLabel.snp.makeConstraints { make in
            make.top.leading.trailing.equalTo(detailTextView)
        }

        detailCountLabel.snp.makeConstraints { make in
            make.bottom.equalToSuperview().inset(WithdrawFeedbackView.detailVerticalPadding)
            make.trailing.equalToSuperview().inset(WithdrawFeedbackView.detailHorizontalPadding)
        }

        // 기본은 안전 영역 하단에 붙어 있고, 키보드가 올라오면 그 위로 옮깁니다.
        actionButton.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview().inset(WithdrawFeedbackView.horizontalInset)
            make.height.equalTo(WithdrawFeedbackView.actionButtonHeight)
            self.actionButtonBottomConstraint = make.bottom
                .equalTo(safeAreaLayoutGuide).constraint
        }
    }

    private func setupActions() {
        actionButton.addTarget(self, action: #selector(withdrawButtonTapped), for: .touchUpInside)
    }

    // MARK: - Actions

    @objc private func reasonRowTapped(_ row: WithdrawReasonRow) {
        // 하나만 선택할 수 있고, 같은 항목을 다시 눌러도 선택이 풀리지 않습니다.
        selectedReason = row.reason
        reasonRows.forEach { $0.isSelected = ($0.reason == row.reason) }

        detailContainerView.isHidden = !row.reason.needsDetail
        if !row.reason.needsDetail {
            endEditing(true)
        }

        updateActionButtonState()
        onSelectionChanged?()
    }

    @objc private func withdrawButtonTapped() {
        onWithdrawTap?()
    }

    // MARK: - Public Methods

    /// 선택한 사유에 함께 보낼 직접 입력 내용. '기타'가 아니면 nil입니다.
    func detailText() -> String? {
        guard selectedReason?.needsDetail == true else { return nil }
        return detailTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Keyboard

    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillShow),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillHide),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil)
    }

    @objc private func keyboardWillShow(notification: NSNotification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }

        // 이 뷰는 안전 영역 안에 놓이므로, 키보드 높이에서 안전 영역만큼은 빼 줍니다.
        let safeAreaBottom = window?.safeAreaInsets.bottom ?? 0
        let overlap = max(keyboardFrame.height - safeAreaBottom, 0)

        updateActionButtonBottomInset(overlap + WithdrawFeedbackView.actionButtonKeyboardSpacing)
        UIView.animate(withDuration: 0.3) {
            self.layoutIfNeeded()
        } completion: { _ in
            // 버튼이 자리를 잡아 스크롤뷰가 줄어든 뒤라야 입력란 위치가 정확합니다.
            self.scrollToDetailInput()
        }
    }

    /// 입력 중인 직접 입력란이 보이도록 스크롤을 올립니다.
    private func scrollToDetailInput() {
        guard detailTextView.isFirstResponder, !detailContainerView.isHidden else { return }

        let targetRect = detailContainerView.convert(detailContainerView.bounds, to: scrollView)
        scrollView.scrollRectToVisible(targetRect, animated: true)
    }

    @objc private func keyboardWillHide(notification: NSNotification) {
        updateActionButtonBottomInset(0)
        UIView.animate(withDuration: 0.3) {
            self.layoutIfNeeded()
        }
    }

    /// 키보드 높이에 맞춰 '탈퇴하기' 버튼을 올립니다.
    func updateActionButtonBottomInset(_ inset: CGFloat) {
        actionButtonBottomConstraint?.update(offset: -inset)
    }

    // MARK: - Private Methods

    /// 사유를 고르면 활성화됩니다. 다만 '기타'는 내용을 적어야 합니다.
    private func updateActionButtonState() {
        let isEnabled: Bool
        switch selectedReason {
        case .none:
            isEnabled = false
        case .some(let reason) where reason.needsDetail:
            isEnabled = !(detailText() ?? "").isEmpty
        case .some:
            isEnabled = true
        }

        actionButton.isEnabled = isEnabled
        actionButton.backgroundColor = isEnabled ? .green_500 : .gray_100
    }

    private func updateDetailCount() {
        let count = detailTextView.text.count
        detailCountLabel.text = "(\(count)/\(WithdrawFeedbackView.detailTextLimit))자"
        detailPlaceholderLabel.isHidden = !detailTextView.text.isEmpty
    }
}

// MARK: - 직접 입력란

extension WithdrawFeedbackView: UITextViewDelegate {

    func textViewDidChange(_ textView: UITextView) {
        guard textView === detailTextView else { return }

        // 붙여넣기로 한 번에 넘어오는 경우가 있어 여기서 한 번 더 잘라 둡니다.
        if textView.text.count > WithdrawFeedbackView.detailTextLimit {
            textView.text = String(textView.text.prefix(WithdrawFeedbackView.detailTextLimit))
        }

        updateDetailCount()
        updateActionButtonState()
        onSelectionChanged?()
    }

    func textView(_ textView: UITextView,
                  shouldChangeTextIn range: NSRange,
                  replacementText text: String) -> Bool {
        guard textView === detailTextView else { return true }

        // 지우는 동작은 항상 허용합니다.
        if text.isEmpty { return true }

        let current = textView.text ?? ""
        guard let textRange = Range(range, in: current) else { return true }
        let updated = current.replacingCharacters(in: textRange, with: text)

        return updated.count <= WithdrawFeedbackView.detailTextLimit
    }
}
