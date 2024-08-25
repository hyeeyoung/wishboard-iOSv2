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
    public static func vibrate() {
       AudioServicesPlaySystemSound(1519)  // 짧은 진동
   }
}
