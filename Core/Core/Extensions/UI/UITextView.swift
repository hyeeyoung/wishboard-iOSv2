//
//  UITextView.swift
//  Core
//
//  Created by gomin on 3/22/25.
//

import Foundation
import UIKit
import Combine

public extension UITextView {
    var textPublisher: AnyPublisher<String, Never> {
        NotificationCenter.default.publisher(for: UITextView.textDidChangeNotification, object: self)
            .compactMap { ($0.object as? UITextView)?.text }
            .eraseToAnyPublisher()
    }
}
