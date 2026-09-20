//
//  ItemAPI.swift
//  WishboardV2
//
//  Created by gomin on 8/17/24.
//

import Foundation
import Moya
import Core

public enum ItemStatusType: String, Decodable {
    case owned = "OWNED"
    case wish = "WISH"
}

public enum AddItemType: String {
    case parsing = "PARSING"        // 파싱 PARSING
    case manual = "MANUAL"          // 수동 MANUAL
}

public struct RequestItemDTO {
    public let folderId: Int?
    public let photos: [Data]?
    public let itemName: String
    public let itemPrice: Int
    public let itemURL: String?
    public let itemMemo: String?
    public let itemNotificationType: String?
    public var itemNotificationDate: String?
    public var version: Int?
    public var imageChanged: Bool?
    
    public init(folderId: Int?, 
                photos: [Data]?,
                itemName: String,
                itemPrice: Int,
                itemURL: String?,
                itemMemo: String?,
                itemNotificationType: String?, itemNotificationDate: String?,
                version: Int? = nil,
                imageChanged: Bool? = nil) {
        self.folderId = folderId
        self.photos = photos
        self.itemName = itemName
        self.itemPrice = itemPrice
        self.itemURL = itemURL
        self.itemMemo = itemMemo
        self.itemNotificationType = itemNotificationType
        self.itemNotificationDate = itemNotificationDate
        self.version = version
        self.imageChanged = imageChanged
    }
}

/// 아이템 일괄 삭제 범위
public enum ItemDeleteScope: String {
    /// 필터에 해당하는 전체
    case all = "ALL"
    /// 요청 본문의 ID 목록만
    case selected = "SELECTED"
}

/// 아이템 일괄 삭제 요청
///
/// scope에 따라 함께 보낼 수 있는 값이 정해져 있어(금지 조합은 400),
/// 반드시 `selected(itemIds:)` / `all(folderId:itemStatus:excludeItemIds:)` 로 생성합니다.
public struct BulkDeleteItemsRequest {
    public let scope: ItemDeleteScope
    public let folderId: Int?
    public let itemStatus: ItemStatusType?
    public let itemIds: [Int]?
    public let excludeItemIds: [Int]?

    private init(scope: ItemDeleteScope,
                 folderId: Int?,
                 itemStatus: ItemStatusType?,
                 itemIds: [Int]?,
                 excludeItemIds: [Int]?) {
        self.scope = scope
        self.folderId = folderId
        self.itemStatus = itemStatus
        self.itemIds = itemIds
        self.excludeItemIds = excludeItemIds
    }

    /// 선택한 아이템만 삭제합니다.
    public static func selected(itemIds: [Int]) -> BulkDeleteItemsRequest {
        BulkDeleteItemsRequest(scope: .selected,
                               folderId: nil,
                               itemStatus: nil,
                               itemIds: itemIds,
                               excludeItemIds: nil)
    }

    /// 조회 조건에 해당하는 아이템 전체를 삭제합니다.
    /// - Parameters:
    ///   - folderId: 폴더 내 아이템만 삭제할 때 지정합니다. (목록 조회 API의 folderId와 동일)
    ///   - itemStatus: 상태 필터. (목록 조회 API의 itemStatus와 동일)
    ///   - excludeItemIds: 전체 선택 후 개별 해제한 아이템. 이 아이템들은 삭제되지 않습니다.
    public static func all(folderId: Int? = nil,
                           itemStatus: ItemStatusType? = nil,
                           excludeItemIds: [Int] = []) -> BulkDeleteItemsRequest {
        BulkDeleteItemsRequest(scope: .all,
                               folderId: folderId,
                               itemStatus: itemStatus,
                               itemIds: nil,
                               excludeItemIds: excludeItemIds.isEmpty ? nil : excludeItemIds)
    }
}

public enum ItemAPI {
    /// 위시리스트 조회
    case getWishItems(page: Int, size: Int, itemStatus: ItemStatusType?)
    /// 아이템 개수 조회 (전체/소장템)
    case getItemCounts
    /// 위시아이템 삭제
    case deleteItem(id: Int)
    /// 위시아이템 일괄 삭제
    case deleteItemsBulk(request: BulkDeleteItemsRequest)
    /// 아이템 디테일 조회
    case getItemDetail(id: Int)
    /// 아이템의 폴더 지정
    case modifyItemFolder(itemId: Int, folderId: Int)
    /// 아이템 파싱
    case parseItemUrl(link: String)
    /// 아이템 추가
    case addItem(type: AddItemType, item: RequestItemDTO)
    /// 아이템 수정
    case modifyItem(idx: Int, item: RequestItemDTO)
    /// 아이템 상태 변경 (소장템)
    case updateItemStatus(idx: Int, status: ItemStatusType)
}

extension ItemAPI: TargetType, AccessTokenAuthorizable {
    
    public var baseURL: URL {
        return URL(string: "\(NetworkMacro.BaseURL)/item")!
    }
    
    public var path: String {
        switch self {
        case .getWishItems:
            return ""
        case .getItemCounts:
            return "/counts"
        case .deleteItem(let id):
            return "/\(id)"
        case .deleteItemsBulk:
            return "/bulk"
        case .getItemDetail(let id):
            return "/\(id)"
        case .modifyItemFolder(let itemId, let folderId):
            return "/\(itemId)/folder/\(folderId)"
        case .parseItemUrl:
            return "/parse"
        case .addItem:
            return ""
        case .modifyItem(let idx, _):
            return "/\(idx)"
        case.updateItemStatus(let idx, _):
            return "/\(idx)/status"
        }
    }

    public var method: Moya.Method {
        switch self {
        case .getWishItems, .getItemDetail, .parseItemUrl, .getItemCounts:
            return .get
        case .modifyItemFolder:
            return .put
        case .deleteItem, .deleteItemsBulk:
            return .delete
        case .addItem:
            return .post
        case .modifyItem:
            return .put
        case .updateItemStatus:
            return .put
        }
    }

    public var task: Moya.Task {
        var parameters: [String: Any] = [:]

        switch self {
        case .getWishItems(let page, let size, let itemStatus):
            parameters = ["page": page, "size": size]
            if let itemStatus = itemStatus {
                parameters["itemStatus"] = itemStatus.rawValue
            }
        case .parseItemUrl(let link):
            parameters = ["site": link]
        case .addItem(let type, let item):
            let data = makeMultipartFormData(param: item)
            return .uploadCompositeMultipart(data, urlParameters: ["type": type.rawValue])
        case .modifyItem(_, let item):
            let data = makeMultipartFormData(param: item)
            return .uploadMultipart(data)
        case .updateItemStatus(_, let status):
            parameters = ["status": status.rawValue]
            return .requestParameters(parameters: parameters, encoding: JSONEncoding.default)
        case .deleteItemsBulk(let request):
            // scope / folderId / itemStatus 는 쿼리로, itemIds / excludeItemIds 는 본문으로 전달합니다.
            var urlParameters: [String: Any] = ["scope": request.scope.rawValue]
            if let folderId = request.folderId {
                urlParameters["folderId"] = folderId
            }
            if let itemStatus = request.itemStatus {
                urlParameters["itemStatus"] = itemStatus.rawValue
            }

            var bodyParameters: [String: Any] = [:]
            if let itemIds = request.itemIds {
                bodyParameters["itemIds"] = itemIds
            }
            if let excludeItemIds = request.excludeItemIds {
                bodyParameters["excludeItemIds"] = excludeItemIds
            }

            return .requestCompositeParameters(bodyParameters: bodyParameters,
                                               bodyEncoding: JSONEncoding.default,
                                               urlParameters: urlParameters)
        default:
            parameters = [:]
        }

        let encoding: ParameterEncoding = self.method == .post ? JSONEncoding.default : URLEncoding.default
        return .requestParameters(parameters: parameters, encoding: encoding)
    }

    public var headers: [String : String]? {
        return NetworkMacro.DeviceInfoHeader
    }
    
    public var authorizationType: Moya.AuthorizationType? {
        return .bearer
    }
    
    public var validationType: ValidationType {
        return .successCodes
    }
    
    func makeMultipartFormData(param: RequestItemDTO) -> [Moya.MultipartFormData] {
        var formData: [Moya.MultipartFormData] = []

        // Required Datas - itemName, itemPrice
        var requestBody: [String: Any] = [
            "itemName": param.itemName,
            "itemPrice": param.itemPrice
        ]

        if let folderId = param.folderId {
            requestBody["folderId"] = folderId
        }
        if let itemURL = param.itemURL, !itemURL.isEmpty {
            requestBody["itemUrl"] = itemURL
        }
        if let itemMemo = param.itemMemo, !itemMemo.isEmpty {
            requestBody["itemMemo"] = itemMemo
        }
        if let notificationType = param.itemNotificationType, !notificationType.isEmpty {
            requestBody["itemNotificationType"] = notificationType
        }
        if let notificationDate = param.itemNotificationDate, !notificationDate.isEmpty {
            requestBody["itemNotificationDate"] = notificationDate
        }
        if let version = param.version {
            requestBody["version"] = version
        }
        if let imageChanged = param.imageChanged {
            requestBody["imageChanged"] = imageChanged
        }

        // JSON 직렬화 → MultipartFormData
        if let jsonData = try? JSONSerialization.data(withJSONObject: requestBody, options: []) {
            let requestPart = MultipartFormData(provider: .data(jsonData), name: "request", mimeType: "application/json")
            formData.append(requestPart)
        }

        // MANUAL - itemImages required
        // PARSING - itemImages optional
        // 이미지들
        if let photos = param.photos {
            for photo in photos {
                let imageData = MultipartFormData(
                    provider: .data(photo),
                    name: "itemImages",
                    fileName: "item_\(UUID()).jpeg",
                    mimeType: "image/jpeg"
                )
                formData.append(imageData)
            }
        }

        return formData
    }
}
