//
//  ModifyProfileViewModel.swift
//  WishboardV2
//
//  Created by gomin on 9/1/24.
//

import Combine
import Foundation
import Core
import UIKit
import WBNetwork

final class ModifyProfileViewModel {
    init() { }
    
    /// 프로필 편집 후 유저 프로필 업데이트
    func updateProfile(img: UIImage?, name: String?) async throws {
        do {
            let usecase = ModifyProfileUseCase()
            _ = try await usecase.execute(profileImg: img?.resizeImageIfNeeded().jpegData(compressionQuality: 1.0), nickname: name)
        } catch {
            throw error
        }
    }
}
