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

final class FolderViewModel {
    @Published var folders: [FolderListResponse] = []
    private var cancellables = Set<AnyCancellable>()

    // 초기화 시에 폴더 데이터를 불러옵니다.
    init() {
        fetchFolders()
    }
    
    // 폴더 데이터 가져오기
    func fetchFolders() {
        Task {
            do {
                let usecase = GetFoldersUseCase(repository: FolderRepository())
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
    func renameFolder(id: Int, newName: String) {
        if let index = folders.firstIndex(where: { $0.folder_id == id }) {
            folders[index].folder_name = newName
        }
    }
    
    // 폴더 삭제
    func deleteFolder(id: Int) {
        folders.removeAll { $0.folder_id == id }
    }
    
//    // 폴더 추가
//    func addFolder(name: String) {
//        let newFolder = Folder(id: folders.count + 1, name: name)
//        folders.append(newFolder)
//    }
}
