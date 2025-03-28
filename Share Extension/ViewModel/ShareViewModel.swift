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
}
