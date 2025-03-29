//
//  FolderViewModel.swift
//  WishboardV2
//
//  Created by gomin on 8/18/24.
//

import Foundation
import Foundation
import Combine
import WBNetwork
import Moya

final class FolderViewModel {
    @Published var folders: [FolderListResponse] = []
    private var cancellables = Set<AnyCancellable>()
    public var folderActionFail: ((Int) -> Void)?

    // 초기화 시에 폴더 데이터를 불러옵니다.
    init() {
        fetchFolders()
    }
    
    // 폴더 데이터 가져오기
    func fetchFolders() {
        _Concurrency.Task {
            do {
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
    
    // 폴더 이름 변경
    func renameFolder(id: Int, newName: String) async throws {
        
//        _Concurrency.Task {
            do {
                let usecase = ModifyFolderNameUseCase()
                let _ = try await usecase.execute(folderId: String(id), folderName: newName)
                
                DispatchQueue.main.async {
                    if let index = self.folders.firstIndex(where: { $0.folder_id == id }) {
                        self.folders[index].folder_name = newName
                        SnackBar.shared.show(type: .modifyFolder)
                    }
                }
            } catch {
                if let moyaError = error as? MoyaError, let response = moyaError.response {
                    self.folderActionFail?(response.statusCode)
                }
                throw error
            }
//        }
        
    }
    
    // 폴더 추가
    func addFolder(name: String) async throws {
//        _Concurrency.Task {
            do {
                let usecase = AddFolderNameUseCase()
                let _ = try await usecase.execute(folderName: name)
                
                self.fetchFolders()
                DispatchQueue.main.async {
                    SnackBar.shared.show(type: .addFolder)
                }
            } catch {
                if let moyaError = error as? MoyaError, let response = moyaError.response {
                    self.folderActionFail?(response.statusCode)
                }
                throw error
            }
//        }
    }
    
    // 폴더 삭제
    func deleteFolder(id: Int) {
        _Concurrency.Task {
            do {
                let usecase = DeleteFolderUseCase()
                let _ = try await usecase.execute(folderId: String(id))
                
                DispatchQueue.main.async {
                    self.folders.removeAll { $0.folder_id == id }
                    SnackBar.shared.show(type: .deleteFolder)
                }
            } catch {
                throw error
            }
        }
    }
}
