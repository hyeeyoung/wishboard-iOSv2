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
    
    // MARK: - UI Components
    private let titleLabel = UILabel().then {
        $0.text = "폴더 선택"
        $0.font = TypoStyle.SuitH3.font
        $0.textAlignment = .center
    }
    private let closeButton = UIButton(type: .system).then {
        $0.setImage(Image.quit, for: .normal)
        $0.tintColor = .gray_700
    }
    public var folderTableView = UITableView(frame: .zero, style: .grouped)
    
    // MARK: - Properties
    private var cancellables = Set<AnyCancellable>()
    
    var onClose: ((Int?) -> Void)?
    public var selectedFolderId: Int? {
        didSet {
            DispatchQueue.main.async {
                self.folderTableView.reloadData()
            }
        }
    }
    private var folders: [FolderListResponse] = []
    
    // MARK: - Initializer
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        folderTableView.register(FolderSelectTableViewCell.self, forCellReuseIdentifier: FolderSelectTableViewCell.identifier)
        folderTableView.dataSource = self
        folderTableView.delegate = self
        folderTableView.separatorStyle = .none
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
    }
    
    @objc private func closeButtonTapped() {
        onClose?(self.selectedFolderId)
    }
    
    
    // MARK: - Public Methods
    
    func configure(with folders: [FolderListResponse]) {
        
        self.snp.makeConstraints { make in
            make.height.equalToSuperview().multipliedBy(0.4)
        }
        
        self.folders = folders
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
        
        if let selectedFolderId = selectedFolderId, let folderId = folder.folder_id, selectedFolderId == folderId {
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
        
        guard let folderId = folders[indexPath.item].folder_id else {return}
        self.selectedFolderId = folderId
        
//        // 선택된 셀의 체크 버튼을 선택 상태로 변경
//        if let selectedCell = tableView.cellForRow(at: indexPath) as? FolderSelectTableViewCell {
//            selectedCell.configureCheckButton(isSelected: true)
//        }
//
//        // 나머지 셀들의 체크 버튼을 선택 해제
//        for (index, folder) in folders.enumerated() where index != indexPath.row {
//            let otherIndexPath = IndexPath(row: index, section: indexPath.section)
//            if let cell = tableView.cellForRow(at: otherIndexPath) as? FolderSelectTableViewCell {
//                cell.configureCheckButton(isSelected: false)
//            }
//        }
    }
}
