//
//  UIApplication.swift
//  Core
//
//  Created by gomin on 3/24/25.
//

import Foundation
import UIKit

public extension UIApplication {
    var currentWindow: UIWindow? {
        return self.connectedScenes
            .filter { $0.activationState == .foregroundActive }
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }
}
