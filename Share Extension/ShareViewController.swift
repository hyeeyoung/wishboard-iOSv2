//
//  ShareViewController.swift
//  Share Extension
//
//  Created by gomin on 8/25/24.
//

import UIKit
import Core
import WBNetwork
import MobileCoreServices

class ShareViewController: UIViewController {
    
    private let shareView = ShareView()
    private let viewModel = ShareViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.addSubview(shareView)
        shareView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        shareView.configure(with: viewModel)
        
        viewModel.fetchFolders()
        self.getSharedUrl { [weak self] url in
            self?.viewModel.fetchItem(link: url)
        }
    }
    
    private func getSharedUrl(completion: @escaping(String) -> Void) {
        // 공유된 URL 가져오기
        if let item = self.extensionContext?.inputItems.first as? NSExtensionItem {
            if let attachment = item.attachments?.first {
                if attachment.hasItemConformingToTypeIdentifier(kUTTypeURL as String) {
                    attachment.loadItem(forTypeIdentifier: kUTTypeURL as String, options: nil) { (urlItem, error) in
                        if let url = urlItem as? URL {
                            DispatchQueue.main.async {
                                print("Shared URL: \(url)")
                                completion(url.absoluteString)
                            }
                        }
                    }
                }
            }
        }
    }

}
