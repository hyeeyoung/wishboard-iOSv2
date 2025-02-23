//
//  UIResponder.swift
//  Core
//
//  Created by gomin on 2/23/25.
//

import Foundation
import UIKit

public extension UIResponder {
    private static weak var _currentFirstResponder: UIResponder?

    public static var currentFirstResponder: UIResponder? {
        _currentFirstResponder = nil
        UIApplication.shared.sendAction(#selector(findFirstResponder), to: nil, from: nil, for: nil)
        return _currentFirstResponder
    }

    @objc private func findFirstResponder() {
        UIResponder._currentFirstResponder = self
    }
}
