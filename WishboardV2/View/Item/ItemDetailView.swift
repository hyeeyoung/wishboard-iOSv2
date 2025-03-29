//
//  ItemDetailView.swift
//  WishboardV2
//
//  Created by gomin on 8/18/24.
//

import Foundation
import UIKit
import SnapKit
import Then
import Core
import WBNetwork

final class ItemDetailView: UIView {
    
    // MARK: - UI Components
    public let toolbar = DetailToolBar()
    private let scrollView = UIScrollView().then {
        $0.isScrollEnabled = true
    }
    private let contentView = UIView()

    private let imageView = UIImageView().then {
        $0.backgroundColor = .black_5
        $0.layer.cornerRadius = 32
        $0.contentMode = .scaleAspectFill
        $0.clipsToBounds = true
    }
    private let notiTypetag = PaddedLabel().then {
        $0.text = "알람 종류"
        $0.font = TypoStyle.SuitB5.font
        $0.backgroundColor = .green_500
        $0.layer.cornerRadius = 12
        $0.clipsToBounds = true
        $0.textAlignment = .center
        $0.edgeInsets = UIEdgeInsets(top: 2, left: 4, bottom: 2, right: 4)
    }
    private let notiDatetag = PaddedLabel().then {
        $0.text = "날짜"
        $0.font = TypoStyle.SuitB5.font
        $0.backgroundColor = .green_500
        $0.layer.cornerRadius = 12
        $0.clipsToBounds = true
        $0.textAlignment = .center
        $0.edgeInsets = UIEdgeInsets(top: 2, left: 4, bottom: 2, right: 4)
    }
    private let folderLabelButton = UILabel().then {
        $0.isUserInteractionEnabled = true
    }
    private let timeLabel = UILabel().then {
        $0.textColor = .gray_300
        $0.font = TypoStyle.SuitD3.font
    }
    private let nameLabel = UILabel().then {
        $0.font = TypoStyle.SuitB1.font
        $0.textColor = .gray_700
        $0.numberOfLines = 0
    }
    private let priceLabel = UILabel()
    private let memoTitleLabel = UILabel().then {
        $0.text = "메모"
        $0.font = TypoStyle.SuitB2.font
        $0.textColor = .gray_700
    }
    private let linkLabel = UILabel().then {
        $0.font = TypoStyle.SuitD3.font
        $0.textColor = .gray_300
    }
    private let actionButton = UIButton(type: .system).then {
        $0.setTitle("쇼핑몰로 이동하기", for: .normal)
        $0.titleLabel?.font = TypoStyle.SuitH3.font
        $0.setTitleColor(.white, for: .normal)
        $0.backgroundColor = .gray_700
    }
    private let bottomView = UIView().then {
        $0.backgroundColor = .gray_700
    }

    private let stackView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 0
    }
    
    private var item: WishListResponse?
    public var folderListButtonAction: (() -> Void)?
    public var linkButtonAction: ((String) -> Void)?

    // MARK: - Initializer
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupConstraints()
        addTargets()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupViews() {
        addSubview(toolbar)
        addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(imageView)
        imageView.addSubview(notiTypetag)
        imageView.addSubview(notiDatetag)
        contentView.addSubview(folderLabelButton)
        contentView.addSubview(timeLabel)
        contentView.addSubview(nameLabel)
        contentView.addSubview(priceLabel)
        contentView.addSubview(stackView)
        addSubview(actionButton)
        addSubview(bottomView)
    }
    
    private func setupConstraints() {
        toolbar.configure()
        
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(toolbar.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(actionButton.snp.top)
        }
        
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(scrollView.snp.width)
        }
        
        imageView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.top.equalToSuperview()
            make.height.equalTo(imageView.snp.width).multipliedBy(1.154)
        }
        
        notiTypetag.snp.makeConstraints { make in
            make.leading.equalTo(imageView).offset(16)
            make.bottom.equalTo(imageView).offset(-16)
        }
        
        notiDatetag.snp.makeConstraints { make in
            make.leading.equalTo(notiTypetag.snp.trailing).offset(8)
            make.bottom.equalTo(imageView).offset(-16)
        }

        folderLabelButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.top.equalTo(imageView.snp.bottom).offset(20)
        }
        
        timeLabel.snp.makeConstraints { make in
            make.trailing.equalTo(imageView)
            make.centerY.equalTo(folderLabelButton)
        }
        
        nameLabel.snp.makeConstraints { make in
            make.top.equalTo(folderLabelButton.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        
        priceLabel.snp.makeConstraints { make in
            make.top.equalTo(nameLabel.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        
        stackView.snp.makeConstraints { make in
            make.top.equalTo(priceLabel.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
        }

        actionButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(48)
            make.bottom.equalTo(self.safeAreaLayoutGuide)
        }
        
        bottomView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.top.equalTo(actionButton.snp.bottom)
        }
    }
    
    private func addTargets() {
        self.actionButton.addTarget(self, action: #selector(actionButtonTapped), for: .touchUpInside)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(folderListButtonTapped))
        self.folderLabelButton.addGestureRecognizer(tapGesture)
    }
    
    @objc private func actionButtonTapped() {
        guard let item = self.item, let url = item.item_url else { return }
        self.linkButtonAction?(url)
    }
    
    @objc private func folderListButtonTapped() {
        self.folderListButtonAction?()
    }
    
    // MARK: - Public Methods
    func configure(with viewModel: ItemDetailViewModel) {
        guard let item = viewModel.item else { return }
        self.item = item

        // item info
        configureItemImg(item.item_img_url)
        configureItemName(with: item.item_name)
        configureItemPrice(with: item.item_price)
        configureTimeLabel(item.create_at)
        configureNotiTags(item)
        configureFolderBtn(item)

        // 구성 요소에 따라 스택뷰에 추가
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() } // 기존 뷰 제거
        configureItemLink(item)
        configureItemMemo(item)
        
        // Action Button 상태 업데이트
        configureBottomBtn(item)
    }
    
    private func configureItemImg(_ url: String?) {
        if let imgUrl = url {
            self.imageView.loadImage(from: imgUrl, placeholder: Image.emptyView)
        } else {
            self.imageView.image = Image.emptyView
        }
    }
    
    private func configureTimeLabel(_ time: String?) {
        guard let time = time else {return}
        timeLabel.text = FormatManager.shared.createdDateToKoreanStr(time)
        timeLabel.font = TypoStyle.SuitD3.font
    }
    
    private func configureNotiTags(_ item: WishListResponse) {
        if let notiType = item.item_notification_type, let notiDate = item.item_notification_date {
            notiTypetag.isHidden = false
            notiDatetag.isHidden = false
            
            notiTypetag.text = notiType
            notiDatetag.text = FormatManager.shared.showNotificationDateInItemDetail(notiDate)
        } else {
            notiTypetag.isHidden = true
            notiDatetag.isHidden = true
        }
    }
    
    private func configureItemName(with name: String?) {
        nameLabel.text = name ?? ""
        nameLabel.font = TypoStyle.SuitD1.font
    }
    
    private func configureItemPrice(with price: String?) {
        guard let price = price else {return}
        guard let formatPrice = FormatManager.shared.strToPrice(numStr: price) else {return}
        let priceText = "\(formatPrice)원"
        let attributedString = NSMutableAttributedString(string: priceText)
        
        // 숫자 부분을 굵게 설정
        let priceRange = NSRange(location: 0, length: "\(formatPrice)".count)
        attributedString.addAttribute(.font, value: TypoStyle.MontserratH2.font, range: priceRange)
        
        // '원' 부분을 작게 설정
        let currencyRange = NSRange(location: priceRange.length, length: 1)
        attributedString.addAttribute(.font, value: TypoStyle.SuitD2.font, range: currencyRange)
        
        priceLabel.attributedText = attributedString
    }
    
    private func configureFolderBtn(_ item: WishListResponse) {
        var attributedText: NSMutableAttributedString
        
        if let _ = item.folder_id, let folderName = item.folder_name {
            attributedText = NSMutableAttributedString(string: folderName + " >")
        } else {
            attributedText = NSMutableAttributedString(string: "폴더를 지정해주세요! >")
        }
        
        attributedText.addAttributes([
            .font: TypoStyle.SuitD3.font,
            .foregroundColor: UIColor.gray_300,
        ], range: NSRange(location: 0, length: attributedText.length))
        
        attributedText.addAttributes([
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ], range: NSRange(location: 0, length: attributedText.length - 2))
        
        folderLabelButton.attributedText = attributedText
        folderLabelButton.textAlignment = .left
    }
    
    private func configureItemLink(_ item: WishListResponse) {
        if let link = item.item_url, !link.isEmpty {
            let linkView = createLinkInfoView(url: link)
            linkView.snp.makeConstraints { make in
                make.height.equalTo(46)
            }
            stackView.addArrangedSubview(linkView)
        }
    }
    
    private func configureItemMemo(_ item: WishListResponse) {
        if let memo = item.item_memo, !memo.isEmpty {
            let memoView = createMemoInfoView(memo: memo)
            stackView.addArrangedSubview(memoView)
        }
    }
    
    private func configureBottomBtn(_ item: WishListResponse) {
        if let link = item.item_url, !link.isEmpty {
            actionButton.titleLabel?.font = TypoStyle.SuitH3.font
            actionButton.setTitleColor(.white, for: .normal)
            actionButton.backgroundColor = .gray_700
            actionButton.isEnabled = true
            bottomView.backgroundColor = .gray_700
        } else {
            actionButton.titleLabel?.font = TypoStyle.SuitH3.font
            actionButton.setTitleColor(.gray_300, for: .normal)
            actionButton.backgroundColor = .gray_100
            actionButton.isEnabled = false
            bottomView.backgroundColor = .gray_100
        }
    }
    
    private func createLinkInfoView(url: String) -> UIView {
        let view = UIView()
        
        let separatorView = UIView().then {
            $0.backgroundColor = .gray_100
        }
        
        view.addSubview(separatorView)
        view.addSubview(linkLabel)
        
        separatorView.snp.makeConstraints { make in
            make.height.equalTo(0.5)
            make.top.leading.trailing.equalToSuperview()
        }
        linkLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(16)
        }
        
        var link = URL(string: url)
        var domain = link?.host
        linkLabel.text = domain
        return view
    }
    
    private func createMemoInfoView(memo: String) -> UIView {
        let view = UIView()

        let separatorView = UIView().then {
            $0.backgroundColor = .gray_100
        }

        let memoTitleLabel = UILabel().then {
            $0.text = "메모"
            $0.font = TypoStyle.SuitB2.font
            $0.textColor = .gray_700
        }

        // ✅ 매번 새로 만드는 memoTextView
        let memoTextView = UITextView().then {
            $0.font = TypoStyle.SuitD2.font
            $0.textColor = .gray_700
            $0.textContainer.maximumNumberOfLines = 0
            $0.isEditable = false
            $0.isSelectable = true
            $0.dataDetectorTypes = [.all]
            $0.isScrollEnabled = false
            $0.textContainerInset = .zero
            $0.text = memo
        }

        let estimatedSize = memoTextView.sizeThatFits(
            CGSize(width: UIScreen.main.bounds.width - 32, height: .greatestFiniteMagnitude)
        )
        memoTextView.snp.makeConstraints { make in
            make.height.equalTo(estimatedSize.height).priority(.high)
        }

        view.addSubview(separatorView)
        view.addSubview(memoTitleLabel)
        view.addSubview(memoTextView)

        separatorView.snp.makeConstraints { make in
            make.height.equalTo(0.5)
            make.top.leading.trailing.equalToSuperview()
        }

        memoTitleLabel.snp.makeConstraints { make in
            make.leading.top.equalToSuperview().inset(16)
        }

        memoTextView.snp.makeConstraints { make in
            make.top.equalTo(memoTitleLabel.snp.bottom).offset(10)
            make.leading.trailing.bottom.equalToSuperview().inset(12)
        }

        return view
    }
}
