//
//  FolderReorderView.swift
//  WishboardV2
//
//  Created by gomin on 3/14/26.
//

import UIKit
import SnapKit
import Then
import Core

final class FolderReorderView: UIView {

    let toolBar = UIView()
    
    let titleLabel = UILabel().then {
        $0.text = "폴더 정렬"
        $0.font = TypoStyle.SuitH3.font
    }

    let closeButton = UIButton().then {
        $0.setImage(Image.quit, for: .normal)
    }

    let tableView = UITableView().then {
        $0.separatorStyle = .none
        $0.showsVerticalScrollIndicator = false
    }
    
    let buttonStackView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 14
    }

    let saveButton = UIButton().then {
        $0.setTitle("저장", for: .normal)
        $0.titleLabel?.font = TypoStyle.SuitH3.font
        $0.layer.cornerRadius = 12
        $0.setTitleColor(.gray_700, for: .normal)
        $0.setTitleColor(.gray_300, for: .disabled)
        $0.isEnabled = false
    }

    let gradientView = UIView()
    
    let recentSortButton = UIButton().then {
        $0.setTitle("최근 등록 순으로 재설정하기", for: .normal)
        $0.setTitleColor(.gray_600, for: .normal)
        $0.titleLabel?.font = TypoStyle.SuitD2.font

        $0.setImage(Image.arrowRetry, for: .normal)
        $0.tintColor = .gray_600

        $0.semanticContentAttribute = .forceLeftToRight
        $0.imageEdgeInsets = UIEdgeInsets(top: 0, left: -3, bottom: 0, right: 3)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        setupViews()
        setupLayout()
        setupGradient()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupViews() {
        backgroundColor = .white

        addSubview(toolBar)
        toolBar.addSubview(titleLabel)
        toolBar.addSubview(closeButton)
        addSubview(tableView)
        addSubview(gradientView)
        addSubview(buttonStackView)
        buttonStackView.addArrangedSubview(saveButton)
        buttonStackView.addArrangedSubview(recentSortButton)

        tableView.register(FolderReorderCell.self,
                           forCellReuseIdentifier: FolderReorderCell.reuseIdentifier)
    }

    private func setupLayout() {

        toolBar.snp.makeConstraints {
            $0.top.leading.trailing.equalTo(safeAreaLayoutGuide).offset(10)
            $0.height.equalTo(42)
        }
        
        closeButton.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(13)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(24)
        }

        titleLabel.snp.makeConstraints {
            $0.centerX.centerY.equalToSuperview()
        }

        tableView.snp.makeConstraints {
            $0.top.equalTo(toolBar.snp.bottom).offset(18)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(buttonStackView.snp.top)
        }

        gradientView.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(buttonStackView.snp.top)
            $0.height.equalTo(36)
        }

        buttonStackView.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalTo(safeAreaLayoutGuide).offset(-8)
        }
        
        saveButton.snp.makeConstraints {
            $0.height.equalTo(50)
        }

//        recentSortButton.snp.makeConstraints {
//            $0.centerX.equalToSuperview()
//            $0.bottom.equalTo(saveButton.snp.top).offset(-10)
//        }
    }

    private func setupGradient() {

        let gradient = CAGradientLayer()
        gradient.colors = [
            UIColor.white.withAlphaComponent(0).cgColor,
            UIColor.white.cgColor
        ]

        gradient.locations = [0, 1]
        gradientView.layer.addSublayer(gradient)

        gradient.frame = CGRect(x: 0, y: 0,
                                width: UIScreen.main.bounds.width,
                                height: 40)
    }

    func updateSaveButton(enabled: Bool) {

        saveButton.isEnabled = enabled
        saveButton.backgroundColor = enabled ? .green_500 : .gray_100
    }
}
