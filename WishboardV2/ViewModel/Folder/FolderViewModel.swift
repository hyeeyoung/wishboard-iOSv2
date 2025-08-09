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
    
    // Paging
    @Published var isLoading: Bool = false
    @Published var isRefreshing: Bool = false
    @Published var hasMore: Bool = true
    private var page: Int = 0          // 서버의 data.number (0-based)
    private let pageSize: Int = 10     // 서버의 data.size와 일치
    
    // MARK: - Init
    init() { }
    
    /// 폴더 가져오기
    func fetchFolders(reset: Bool = false) {
        guard !isLoading, hasMore || reset else { return }
        isLoading = true

        if reset {
            page = 0
            hasMore = true
        }

        _Concurrency.Task {
            do {
                let usecase = GetFoldersUseCase()
                let response = try await usecase.execute(page: page, size: pageSize)

                if reset { folders.removeAll() }

                if let itemDatas = response.data?.content {
                    folders.append(contentsOf: itemDatas)
                }

                // 다음 페이지 여부 및 page 증가
                hasMore = !(response.data?.last ?? true)
                if hasMore {
                    page += 1
                }

                isLoading = false
                isRefreshing = false
            } catch {
                if reset { folders = [] }
                isLoading = false
                isRefreshing = false
                // 필요하면 에러 상태 @Published 추가해서 바인딩
            }
        }
    }

    /// 풀-투-리프레시에서 호출
    func refresh() {
        isRefreshing = true
        fetchFolders(reset: true)
    }

    /// UICollectionView 스크롤 하단 근처에서 호출해 다음 페이지 로드
    func loadNextIfNeeded(currentIndex: Int, threshold: Int = 2) {
        guard currentIndex >= folders.count - threshold else { return }
        fetchFolders()
    }
    
    // 폴더 이름 변경
    func renameFolder(id: Int, newName: String) async throws {
        do {
            let usecase = ModifyFolderNameUseCase()
            let _ = try await usecase.execute(folderId: String(id), folderName: newName)
            
            DispatchQueue.main.async {
                if let index = self.folders.firstIndex(where: { $0.id == id }) {
                    self.folders[index].folderName = newName
                    SnackBar.shared.show(type: .modifyFolder)
                }
            }
        } catch {
            if let moyaError = error as? MoyaError, let response = moyaError.response {
                self.folderActionFail?(response.statusCode)
            }
            throw error
        }
    }
    
    // 폴더 추가
    func addFolder(name: String) async throws {
        do {
            let usecase = AddFolderNameUseCase()
            let _ = try await usecase.execute(folderName: name)
            
            self.fetchFolders(reset: true)
            DispatchQueue.main.async {
                SnackBar.shared.show(type: .addFolder)
            }
        } catch {
            if let moyaError = error as? MoyaError, let response = moyaError.response {
                self.folderActionFail?(response.statusCode)
            }
            throw error
        }
    }
    
    // 폴더 삭제
    func deleteFolder(id: Int) {
        _Concurrency.Task {
            do {
                let usecase = DeleteFolderUseCase()
                let _ = try await usecase.execute(folderId: String(id))
                
                DispatchQueue.main.async {
                    self.folders.removeAll { $0.id == id }
                    SnackBar.shared.show(type: .deleteFolder)
                }
            } catch {
                throw error
            }
        }
    }
}
