//
//  FolderDetailViewModel.swift
//  WishboardV2
//
//  Created by gomin on 8/25/24.
//

import Foundation
import Combine
import WBNetwork

final class FolderDetailViewModel {
    
    @Published var items: [WishListResponse] = []
    private var folderId: String
    private var cancellables = Set<AnyCancellable>()
    
    init(folderId: String) {
        self.folderId = folderId
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func fetchItems() {
        Task {
            do {
                let usecase = GetFolderItemListUseCase()
                let data = try await usecase.execute(folderId: folderId)
                
                DispatchQueue.main.async {
                    self.items = data
                }
            } catch {
                throw error
            }
        }
    }
}
