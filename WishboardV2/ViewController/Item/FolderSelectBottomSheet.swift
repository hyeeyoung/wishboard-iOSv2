//
//  FolderSelectBottomSheet.swift
//  WishboardV2
//
//  Created by gomin on 8/25/24.
//

import Foundation
import UIKit
import SnapKit
import Then
import Combine

import Core
import WBNetwork

final class FolderSelectBottomSheet: UIView {

    /// 기본 시트 높이 비율
    static let defaultHeightRatio: CGFloat = 0.4

    
    // MARK: - UI Components
    private let titleLabel = UILabel().then {
        $0.text = Title.folder
        $0.font = TypoStyle.SuitH3.font
        $0.textAlignment = .center
    }
    private let closeButton = UIButton(type: .system).then {
        $0.setImage(Image.quit, for: .normal)
        $0.tintColor = .gray_700
    }
    public var folderTableView = UITableView(frame: .zero)
    public let emptyLabel = UILabel().then {
        $0.text = EmptyMessage.folder
        $0.setTypoStyleWithMultiLine(typoStyle: .SuitD2)
        $0.textColor = .gray_200
        $0.numberOfLines = 0
        $0.textAlignment = .center
        $0.isHidden = true
    }
    
    // MARK: - Properties
    private var cancellables = Set<AnyCancellable>()
    
    var onClose: (() -> Void)?
    /// 폴더를 골랐을 때. 해제가 켜진 화면에서 이미 지정된 폴더를 다시 고르면 `nil` 이 전달됩니다.
    var selectAction: ((Int?, String?) -> Void)?

    /// 시트 높이 비율. `configure` 를 부르기 전에 지정합니다.
    var heightRatio: CGFloat = FolderSelectBottomSheet.defaultHeightRatio
    /// 이미 지정된 폴더를 다시 골랐을 때 해제할지 여부.
    /// 아이템 상세처럼 해제가 필요한 화면에서만 켭니다.
    var allowsDeselection: Bool = false

    /// 높이 제약. `configure` 가 여러 번 불려도 한 번만 겁니다.
    private var heightConstraint: Constraint?
    public var selectedFolderId: Int? {
        didSet {
            DispatchQueue.main.async {
                self.folderTableView.reloadData()
            }
        }
    }
    private var selectedFolder: String?
    private var folders: [FolderListResponse] = []
    
    // MARK: - Initializer
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        folderTableView.register(FolderSelectTableViewCell.self, forCellReuseIdentifier: FolderSelectTableViewCell.identifier)
        folderTableView.dataSource = self
        folderTableView.delegate = self
        folderTableView.separatorInset = .zero
        folderTableView.separatorColor = .gray_100
        folderTableView.backgroundColor = .white
        
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
        
        addSubview(titleLabel)
        addSubview(closeButton)
        addSubview(folderTableView)
        addSubview(emptyLabel)
        
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
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
        
        folderTableView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(16)
            make.leading.trailing.bottom.equalToSuperview()
        }
        
        emptyLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
    
    @objc private func closeButtonTapped() {
        onClose?()
    }
    
    
    // MARK: - Public Methods
    
    func configure(with folders: [FolderListResponse]) {
        
        if heightConstraint == nil {
            self.snp.makeConstraints { make in
                heightConstraint = make.height.equalToSuperview()
                    .multipliedBy(heightRatio).constraint
            }
        }
        
        self.folders = folders
        self.emptyLabel.isHidden = !(folders.isEmpty)
        self.folderTableView.reloadData()
    }
}

// MARK: - TableView Delegate
extension FolderSelectBottomSheet: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.folders.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: FolderSelectTableViewCell.identifier, for: indexPath) as! FolderSelectTableViewCell
        let folder = folders[indexPath.item]
        cell.configure(with: folder)
        
        if let selectedFolderId = selectedFolderId, let folderId = folder.id, selectedFolderId == folderId {
            cell.configureCheckButton(isSelected: true)
        } else {
            cell.configureCheckButton(isSelected: false)
        }
        
        cell.selectionStyle = .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 56
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        UIDevice.vibrate()
        
        guard indexPath.item < folders.count else { return }
        let folderItem = folders[indexPath.item]
        guard let folderId = folderItem.id, let folderName = folderItem.folderName else {return}

        // 해제가 켜진 화면에서는 이미 지정된 폴더를 다시 고르면 해제합니다.
        if allowsDeselection, selectedFolderId == folderId {
            self.selectedFolderId = nil
            self.selectedFolder = nil
            selectAction?(nil, nil)
            return
        }

        self.selectedFolderId = folderId
        self.selectedFolder = folderName
        selectAction?(folderId, folderName)
    }
}
