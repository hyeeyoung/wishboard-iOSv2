//
//  NotificationName.swift
//  Core
//
//  Created by gomin on 8/17/24.
//

import Foundation

extension Foundation.Notification.Name {
    public static let SignOut = Foundation.Notification.Name("SignOut")
    public static let ReceivedNetworkError = Foundation.Notification.Name("didReceiveUnauthorizedError")
    public static let ShowSnackBar = Foundation.Notification.Name("ShowSnackBar")
    public static let ItemUpdated = Foundation.Notification.Name("ItemUpdated")
}
