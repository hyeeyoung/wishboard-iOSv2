//
//  UIDevice.swift
//  Core
//
//  Created by gomin on 8/24/24.
//

import Foundation
import UIKit
import AVFoundation

extension UIDevice {
    
    /// 짧은 진동
    public static func vibrate() {
       AudioServicesPlaySystemSound(1519)
   }
    
    /// Model Name
    public var modelName: String {
        var systemInfo = utsname()
        uname(&systemInfo)

        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }

        // 예: iPhone15,3 → iPhone 15 Pro
        return identifier
    }
}
