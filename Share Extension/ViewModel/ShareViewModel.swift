//
//  ShareViewModel.swift
//  Share Extension
//
//  Created by gomin on 8/25/24.
//

import Foundation
import Foundation
import Combine
import Core
import WBNetwork
import UIKit
import MobileCoreServices

final class ShareViewModel {
    @Published var isLogined: Bool = true
    @Published var item: WishListResponse?
    @Published var folders: [FolderListResponse] = []
    @Published var selectedAlarmType: String? = nil
    @Published var selectedAlarmDate: String? = nil
    @Published var selectedAlarm: String? = nil
    private var cancellables = Set<AnyCancellable>()
    
    /// 웹url로 아이템 파싱하기
    func fetchItem(link: String) async throws {
        do {
            let usecase = ParseItemUrlUseCase()
            let data = try await usecase.execute(link: link)
            
            DispatchQueue.main.async {
                self.item = data
            }
        } catch {
            self.item = nil
            throw error
        }
    }
    
    /// 폴더 데이터 가져오기
    func fetchFolders() {
        Task {
            do {
                // 로그인 상태가 아닐 때
                if UserManager.accessToken == nil || UserManager.refreshToken == nil {
                    self.isLogined = false
                    return
                }
                
                self.isLogined = true
                let usecase = GetFoldersUseCase()
                let data = try await usecase.execute()
                
                DispatchQueue.main.async {
                    self.folders = data
                }
            } catch {
                throw error
            }
        }
    }
    
    /// 폴더 추가
    func addFolder(name: String) {
        Task {
            do {
                let usecase = AddFolderNameUseCase()
                let _ = try await usecase.execute(folderName: name)
                
                self.fetchFolders()
            } catch {
                throw error
            }
        }
    }
    
    /// 아이템 추가
    func addItem(item: RequestItemDTO) async throws {
        do {
            let usecase = AddItemUseCase()
            _ = try await usecase.execute(type: .parsing, item: item)
        } catch {
            throw error
        }
    }
    
    /// URL 가져오기
    func getSharedUrl(_ context: UIViewController, completion: @escaping (String) -> Void) {
        guard let item = context.extensionContext?.inputItems.first as? NSExtensionItem else {
            completion("")
            return
        }

        guard let attachment = item.attachments?.first else {
            completion("")
            return
        }

        // URL 타입 먼저 시도
        if attachment.hasItemConformingToTypeIdentifier(kUTTypeURL as String) {
            attachment.loadItem(forTypeIdentifier: kUTTypeURL as String, options: nil) { (urlItem, error) in
                DispatchQueue.main.async {
                    if let url = urlItem as? URL {
                        print("✅ Shared URL (as URL): \(url)")
                        completion(url.absoluteString)
                    } else {
                        print("❌ Failed to cast as URL: \(type(of: urlItem))")
                        completion("")
                    }
                }
            }

        // URL을 텍스트로 주는 경우 (YouTube 앱)
        } else if attachment.hasItemConformingToTypeIdentifier("public.plain-text") {
            attachment.loadItem(forTypeIdentifier: "public.plain-text", options: nil) { (textItem, error) in
                DispatchQueue.main.async {
                    if let urlString = textItem as? String {
                        print("🌀 Shared URL (as plain text): \(urlString)")

                        // 인코딩된 경우도 고려
                        let decodedOnce = urlString.removingPercentEncoding ?? urlString
                        let decodedTwice = decodedOnce.removingPercentEncoding ?? decodedOnce

                        print("🛠 Final Decoded URL: \(decodedTwice)")
                        completion(decodedTwice)
                    } else {
                        print("❌ Failed to cast as String: \(type(of: textItem))")
                        completion("")
                    }
                }
            }

        } else {
            print("❌ No supported type found.")
            completion("")
        }
    }
}
