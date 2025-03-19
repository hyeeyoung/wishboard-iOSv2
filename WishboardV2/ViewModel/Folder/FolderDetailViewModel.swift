//
//  FolderDetailViewModel.swift
//  WishboardV2
//
//  Created by gomin on 8/25/24.
//

import Foundation
import Combine
import WBNetwork
import Moya

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
        _Concurrency.Task {
            do {
                let usecase = GetFolderItemListUseCase()
                let data = try await usecase.execute(folderId: folderId)
                
                DispatchQueue.main.async {
                    self.items = data
                }
            } catch {
                if let moyaError = error as? MoyaError, let response = moyaError.response {
                    if response.statusCode == 404 {
                        self.items = []
                    }
                }
                throw error
            }
        }
    }
}
