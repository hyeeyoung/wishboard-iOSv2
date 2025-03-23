//
//  AppGuideSheetViewController.swift
//  WishboardV2
//
//  Created by gomin on 3/7/25.
//

import Foundation
import UIKit
import Core


final class AppGuideSheetViewController: UIViewController {

    private let backgroundDimView = UIView()
    private let appGuideSheet = AppGuideSheet()

    var onDismiss: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
        
        appGuideSheet.layer.cornerRadius = 20
        appGuideSheet.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        appGuideSheet.clipsToBounds = true
    }

    private func setupUI() {
        view.backgroundColor = .clear
        
        // Dimmed 배경 추가
        backgroundDimView.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        view.addSubview(backgroundDimView)
        backgroundDimView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        // 앱 가이드 시트 추가
        view.addSubview(appGuideSheet)
        appGuideSheet.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(673)
            make.bottom.equalToSuperview().offset(673)
        }

        // 애니메이션으로 시트 올리기
        UIView.animate(withDuration: 0.3) {
            self.appGuideSheet.snp.updateConstraints { make in
                make.bottom.equalToSuperview()
            }
            self.view.layoutIfNeeded()
        }
    }

    private func setupActions() {
        appGuideSheet.onTapped = { [weak self] in
            self?.dismissSheet()
        }
    }

    private func dismissSheet() {
        UIView.animate(withDuration: 0.3, animations: {
            self.appGuideSheet.snp.updateConstraints { make in
                make.bottom.equalToSuperview().offset(673)
            }
            self.view.layoutIfNeeded()
        }) { _ in
            self.dismiss(animated: false) // 애니메이션 종료 후 모달 닫기
            self.onDismiss?()
        }
    }
}
